import Foundation
import Combine
import SystemConfiguration
import CoreFoundation

import SWXMLHash

struct ReceiverStateSnapshot {
    let isOn: Bool
    let volume: Float
    let isMuted: Bool
    let input: String
    let lastUpdated: Date
}

class ReceiverStateModel: ObservableObject {
    // --- Source rename integration ---
    @Published var availableSources: [String] = []
    @Published var renameMap: [String: String] = [:]

    // --- Command sending methods ---
    /// Set the volume in dB (range: -80.5 to 18.0)
    func setVolume(to dB: Float) {
        let dBString = String(format: "%.1f", dB)
        print("[DenonAvr] setVolume(to:) called with dB = \(dBString)")
        sendPostCommand(cmd: "PutMasterVolumeSet/\(dBString)")
    }

    /// Set mute state
    func setMute(to muted: Bool) {
        let state = muted ? "on" : "off"
        print("[DenonAvr] setMute(to:) called with muted = \(muted) (\(state))")
        sendPostCommand(cmd: "PutVolumeMute/\(state)")
    }

    /// Set power state
    func setPower(to on: Bool) {
        let state = on ? "ON" : "OFF"
        print("[DenonAvr] setPower(to:) called with on = \(on) (\(state))")
        sendPostCommand(cmd: "PutZone_OnOff/\(state)")
    }

    /// Send a POST command to the receiver
    func sendPostCommand(cmd: String) {
        print("[DenonAvr] sendPostCommand: \(cmd) to http://\(ipAddress)/MainZone/index.put.asp")
        guard !ipAddress.isEmpty else { return }
        let urlString = "http://\(ipAddress)/MainZone/index.put.asp"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "cmd0=\(cmd)"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            // After sending, poll for latest state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.pollReceiver()
            }
        }
        task.resume()
    }
    // Published properties for UI binding
    @Published var lastPolledState: ReceiverStateSnapshot? = nil
    @Published var isConnected: Bool = false
    @Published var errorMessage: String? = nil

    /// Public method to trigger an immediate poll
    func performImmediatePoll() {
        fetchSourceRenameMap()
        pollReceiver()
    }

    private var ipAddress: String
    private var pollingInterval: TimeInterval
    private var pollingTimer: Timer?
    private var isPollingActive = false
    private var consecutiveFailures = 0
    private let maxFailures = 3

    init(ipAddress: String, pollingInterval: TimeInterval = 3.0) {
        self.ipAddress = ipAddress
        self.pollingInterval = pollingInterval
        fetchSourceRenameMap()
    }

    func updateIPAddress(_ newIP: String) {
        ipAddress = newIP
        consecutiveFailures = 0 // Reset retries when a new IP is saved
        fetchSourceRenameMap()
    }

    func startPolling() {
        print("[Polling] startPolling() called — scheduling polling timer (interval: \(pollingInterval)s)")
        stopPolling()
        beginPolling() // Always restart polling timer when startPolling is called
    }

    private func beginPolling() {
        print("[Polling] beginPolling() — starting recurring polling")
        stopPolling() // Prevent multiple timers!
        guard !isPollingActive else { return }
        isPollingActive = true
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.pollReceiver()
        }
        pollReceiver()
    }

    func stopPolling() {
        print("[Polling] stopPolling() called — cancelling polling timer")
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPollingActive = false
    }

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
        let xml = XMLHash.config {
              config in
              // set any config options here
          }.parse(data)
        let now = Date()

        let powerString = xml["item"]["Power"]["value"].element?.text ?? ""
        let isOn = powerString.uppercased() == "ON"

        let volumeString = xml["item"]["MasterVolume"]["value"].element?.text ?? "0.0"
        let volume = Float(volumeString) ?? 0.0

        let muteString = xml["item"]["Mute"]["value"].element?.text ?? ""
        let isMuted = muteString.lowercased() == "on"

        let input = xml["item"]["InputFuncSelect"]["value"].element?.text ?? ""

        let snapshot = ReceiverStateSnapshot(
            isOn: isOn,
            volume: volume,
            isMuted: isMuted,
            input: input,
            lastUpdated: now
        )

        DispatchQueue.main.async {
            self.lastPolledState = snapshot
            self.errorMessage = nil
            print("[Polling] Snapshot: isOn=\(snapshot.isOn), volume=\(snapshot.volume), isMuted=\(snapshot.isMuted), input=\(snapshot.input), lastUpdated=\(snapshot.lastUpdated)")
        }
    }

    // Fetch and parse the rename HTML from the AVR (run at startup or when IP changes)
    func fetchSourceRenameMap() {
        let urlString = "http://\(ipAddress)/SETUP/INPUTS/SOURCERENAME/d_Rename.asp"
        print("[ReceiverStateModel] Fetching source rename map from: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("[ReceiverStateModel] Invalid URL for source rename map: \(urlString)")
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error {
                print("[ReceiverStateModel] Error fetching rename HTML: \(error)")
                return
            }
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                print("[ReceiverStateModel] No data or invalid encoding for rename HTML")
                return
            }
            print("[ReceiverStateModel] Fetched rename HTML length: \(html.count) characters")
            let renameMap = SourceNameExtractor.extractRenameMappings(from: html)
            let sources = Array(renameMap.keys).sorted()
            print("[ReceiverStateModel] Parsed renameMap: \(renameMap)")
            print("[ReceiverStateModel] Parsed availableSources: \(sources)")
            DispatchQueue.main.async {
                var updatedRenameMap = renameMap
                var updatedSources = sources
                // Ensure NET is always present with display name "Network"
                if !updatedSources.contains("NET") {
                    updatedSources.append("NET")
                }
                if updatedRenameMap["NET"] == nil {
                    updatedRenameMap["NET"] = "Network"
                }
                self.renameMap = updatedRenameMap
                self.availableSources = updatedSources.sorted()
                print("[ReceiverStateModel] Available sources: \(self.availableSources)")
                print("[ReceiverStateModel] Rename map: \(self.renameMap)")
            }
        }.resume()
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
