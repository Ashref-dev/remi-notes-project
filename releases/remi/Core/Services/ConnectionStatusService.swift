import Foundation
import Network
import Combine

@MainActor
class ConnectionStatusService: ObservableObject {
    static let shared = ConnectionStatusService()
    
    @Published var isConnected: Bool = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        // Note: deinit is not MainActor isolated, so we can call monitor.cancel() directly
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    var connectionDescription: String {
        guard isConnected else { return "No Connection" }
        
        switch connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        default:
            return "Connected"
        }
    }
}
