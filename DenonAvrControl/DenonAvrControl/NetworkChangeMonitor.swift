import Foundation
import Network

class NetworkChangeMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var lastPath: NWPath?
    var onChange: (() -> Void)?

    init(onChange: (() -> Void)? = nil) {
        self.onChange = onChange
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if self.lastPath == nil || self.lastPath != path {
                self.lastPath = path
                self.onChange?()
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
