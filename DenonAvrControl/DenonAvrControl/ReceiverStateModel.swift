import Foundation
import Combine
import SystemConfiguration
import CoreFoundation

import Network

class ReceiverStateModel: ObservableObject {
    // Published properties for UI binding
    @Published var isOn: Bool = false
    @Published var volume: Float = 0.0
    @Published var isMuted: Bool = false
    @Published var input: String = ""
    @Published var isConnected: Bool = false
    @Published var lastUpdated: Date? = nil
    @Published var errorMessage: String? = nil

    private var ipAddress: String
    private var pollingInterval: TimeInterval
    private var pollingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var networkMonitor: NWPathMonitor?
    private var lastNetworkPath: NWPath?
    private var isPollingActive = false
    private var consecutiveFailures = 0
    private let maxFailures = 3

    init(ipAddress: String, pollingInterval: TimeInterval = 3.0) {
        self.ipAddress = ipAddress
        self.pollingInterval = pollingInterval
    }

    func updateIPAddress(_ newIP: String) {
        ipAddress = newIP
        consecutiveFailures = 0 // Reset retries when a new IP is saved
    }

    func startPolling() {
        stopPolling()
        startNetworkMonitoring()
    }

    private func startNetworkMonitoring() {
        if networkMonitor != nil { return }
        let monitor = NWPathMonitor()
        self.networkMonitor = monitor
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if self.lastNetworkPath == nil || self.lastNetworkPath != path {
                self.lastNetworkPath = path
                self.handleNetworkChange()
            }
        }
        monitor.start(queue: queue)
        // Initial check
        handleNetworkChange()
    }

    private func handleNetworkChange() {
        stopPolling()
        isPollingActive = false
        // Validate the configured receiver IP once
        validateConnection(ip: ipAddress) { [weak self] success, _ in
            DispatchQueue.main.async {
                if success {
                    self?.beginPolling()
                } else {
                    self?.isConnected = false
                    self?.errorMessage = "Receiver not found on current network"
                }
            }
        }
    }

    private func beginPolling() {
        stopPolling() // Prevent multiple timers!
        isPollingActive = true
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.pollReceiver()
        }
        // No immediate pollReceiver() call (already fixed)
    }
    
    @objc private func updateNetworkStatus() {
        // This will be called when network status changes
        // No action needed; handled by NWPathMonitor now.
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPollingActive = false
    }

    deinit {
        networkMonitor?.cancel()
    }

    // checkNetworkAndPoll is now obsolete (network change triggers validation and polling)

    
    private func pollReceiver() {
        guard !ipAddress.isEmpty else {
            print("[Polling] Skipped: IP address is empty.")
            return
        }
        let urlString = "http://\(ipAddress)/goform/formMainZone_MainZoneXml.xml"
        guard let url = URL(string: urlString) else {
            print("[Polling] Invalid IP address: \(ipAddress)")
            DispatchQueue.main.async { self.errorMessage = "Invalid IP address" }
            self.incrementFailureAndMaybeStop()
            return
        }
        print("[Polling] Attempting to poll receiver at \(ipAddress)...")
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                print("[Polling] Poll failed for \(self.ipAddress): \(error.localizedDescription) [Failure \(self.consecutiveFailures+1)/\(self.maxFailures)]")
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                self.incrementFailureAndMaybeStop()
                return
            }
            guard let data = data else {
                print("[Polling] No data received from receiver at \(self.ipAddress) [Failure \(self.consecutiveFailures+1)/\(self.maxFailures)]")
                DispatchQueue.main.async { self.errorMessage = "No data received" }
                self.incrementFailureAndMaybeStop()
                return
            }
            print("[Polling] Poll succeeded for \(self.ipAddress)")
            self.consecutiveFailures = 0 // reset on success
            self.parseReceiverXML(data)
        }.resume()
    }

    /// Attempts a one-time connection to the given IP and calls completion with the result (true, nil) on success, (false, error) on failure.
    func validateConnection(ip: String, completion: @escaping (Bool, String?) -> Void) {
        guard !ip.isEmpty else {
            self.incrementFailureAndMaybeStop()
            completion(false, "IP address is empty")
            return
        }
        let urlString = "http://\(ip)/goform/formMainZone_MainZoneXml.xml"
        guard let url = URL(string: urlString) else {
            self.incrementFailureAndMaybeStop()
            completion(false, "Invalid IP address")
            return
        }
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 3.0
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                self.incrementFailureAndMaybeStop()
                completion(false, error.localizedDescription)
                return
            }
            guard let data = data else {
                self.incrementFailureAndMaybeStop()
                completion(false, "No data received from receiver")
                return
            }
            // Minimal XML validation for Denon AVR
            let parser = XMLParser(data: data)
            let validator = DenonXMLValidator()
            parser.delegate = validator
            var parseError: String? = nil
            validator.onError = { errMsg in parseError = errMsg }
            if parser.parse(), validator.isValid {
                self.consecutiveFailures = 0 // reset on success
                print("[DenonAvr] Connection validation succeeded for IP: \(ip)")
                completion(true, nil)
            } else {
                self.incrementFailureAndMaybeStop()
                if let parseError = parseError {
                    completion(false, parseError)
                } else {
                    completion(false, "Invalid or unexpected receiver response")
                }
            }
        }
        task.resume()
    }

    /// Minimal XML validator for Denon AVR MainZone XML
    private class DenonXMLValidator: NSObject, XMLParserDelegate {
        var isValid = false
        private var foundRoot = false
        private var foundFriendlyName = false
        private var foundPower = false
        private var foundMasterVolume = false
        var onError: ((String) -> Void)?
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            if elementName == "item" { foundRoot = true }
            if elementName == "FriendlyName" { foundFriendlyName = true }
            if elementName == "Power" { foundPower = true }
            if elementName == "MasterVolume" { foundMasterVolume = true }
        }
        func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
            onError?("XML parse error: \(parseError.localizedDescription)")
        }
        func parserDidEndDocument(_ parser: XMLParser) {
            isValid = foundRoot && foundFriendlyName && foundPower && foundMasterVolume
            if !isValid {
                onError?("Missing required tags in receiver XML.")
            }
        }
    }

    private func parseReceiverXML(_ data: Data) {
        // TODO: Implement real XML parsing for receiver state
        // For now, just mark as updated
        DispatchQueue.main.async {
            self.lastUpdated = Date()
            self.errorMessage = nil
            // Example: self.volume = ...
            // Example: self.powerOn = ...
            // Example: self.inputSource = ...
        }
    }

    // Helper to increment failure counter and stop polling if limit is reached
    private func incrementFailureAndMaybeStop() {
        consecutiveFailures += 1
        if consecutiveFailures >= maxFailures {
            DispatchQueue.main.async {
                self.errorMessage = "Connection failed too many times. Polling stopped."
                self.stopPolling()
            }
        }
    }
}
