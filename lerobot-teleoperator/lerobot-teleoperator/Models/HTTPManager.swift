import Foundation
import Combine

@Observable
class HTTPManager: NSObject {
    enum ConnectionState: Equatable {
        case idle
        case sending
        case success
        case failed(Error)
        
        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                 (.sending, .sending),
                 (.success, .success):
                return true
            case (.failed(_), .failed(_)):
                return true
            default:
                return false
            }
        }
    }
    
    // Connection properties
    private var urlSession: URLSession!
    private var serverURL: URL?
    
    // State
    var connectionState: ConnectionState = .idle
    var lastError: String?
    var messagesSent: Int = 0
    var lastMessageTime: Date?
    
    // Configuration
    var serverAddress: String = "http://192.168.0.118:1049" {  // Replace with your computer's IP
        didSet {
            updateServerURL()
        }
    }
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0
        config.timeoutIntervalForResource = 5.0
        self.urlSession = URLSession(configuration: config)
        updateServerURL()
    }
    
    private func updateServerURL() {
        if let url = URL(string: serverAddress) {
            self.serverURL = url
        } else {
            self.serverURL = nil
            self.lastError = "Invalid server address"
        }
    }
    
    // MARK: - Message Handling
    
    func sendHandData(_ data: HandTrackingData.HandData, isLeft: Bool) {
        guard let baseURL = serverURL else {
            connectionState = .failed(NSError(domain: "HTTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"]))
            return
        }
        
        let url = baseURL.appendingPathComponent("control")
        
        let message = HandDataMessage(
            timestamp: Date().timeIntervalSince1970,
            isLeft: isLeft,
            joints: data.joints.map { joint in
                JointMessage(
                    name: joint.name,
                    position: [joint.position.x, joint.position.y, joint.position.z],
                    isTracked: joint.isTracked
                )
            }
        )
        
        sendMessage(message, to: url)
    }
    
    func sendBothHands(left: HandTrackingData.HandData?, right: HandTrackingData.HandData?) {
        guard let baseURL = serverURL else {
            connectionState = .failed(NSError(domain: "HTTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"]))
            return
        }
        
        let url = baseURL.appendingPathComponent("control")
        
        let message = BothHandsMessage(
            timestamp: Date().timeIntervalSince1970,
            leftHand: left != nil ? HandDataCompact(from: left!) : nil,
            rightHand: right != nil ? HandDataCompact(from: right!) : nil
        )
        
        sendMessage(message, to: url)
    }
    
    private func sendMessage<T: Encodable>(_ message: T, to url: URL) {
        connectionState = .sending
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(message)
            request.httpBody = jsonData
            
            let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.connectionState = .failed(error)
                        self?.lastError = error.localizedDescription
                        print("HTTP send error: \(error)")
                    } else if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            self?.connectionState = .success
                            self?.messagesSent += 1
                            self?.lastMessageTime = Date()
                            self?.lastError = nil
                        } else {
                            let error = NSError(domain: "HTTP", code: httpResponse.statusCode, 
                                              userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
                            self?.connectionState = .failed(error)
                            self?.lastError = "HTTP error: \(httpResponse.statusCode)"
                        }
                    }
                    
                    // Reset to idle after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if self?.connectionState == .success {
                            self?.connectionState = .idle
                        }
                    }
                }
            }
            
            task.resume()
            
        } catch {
            connectionState = .failed(error)
            lastError = "Failed to encode hand data: \(error.localizedDescription)"
            print("Encoding error: \(error)")
        }
    }
    
    // MARK: - Status Methods
    
    func checkHealth() {
        guard let baseURL = serverURL else { return }
        
        let url = baseURL.appendingPathComponent("health")
        
        let task = urlSession.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = "Health check failed: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self?.lastError = nil
                        print("Server is healthy")
                    } else {
                        self?.lastError = "Server unhealthy: HTTP \(httpResponse.statusCode)"
                    }
                }
            }
        }
        
        task.resume()
    }
    
    // Singleton
    static let shared = HTTPManager()
}

// MARK: - Message Types

struct HandDataMessage: Codable {
    let timestamp: Double
    let isLeft: Bool
    let joints: [JointMessage]
}

struct JointMessage: Codable {
    let name: String
    let position: [Float]
    let isTracked: Bool
}

struct BothHandsMessage: Codable {
    let timestamp: Double
    let leftHand: HandDataCompact?
    let rightHand: HandDataCompact?
}

struct HandDataCompact: Codable {
    let joints: [[Float]] // 27 joints x 3 coordinates
    let trackedMask: Int // Bit mask for tracked joints
    
    init(from handData: HandTrackingData.HandData) {
        self.joints = handData.joints.map { [$0.position.x, $0.position.y, $0.position.z] }
        
        // Create bit mask for tracked joints
        var mask = 0
        for (index, joint) in handData.joints.enumerated() {
            if joint.isTracked && index < 32 {
                mask |= (1 << index)
            }
        }
        self.trackedMask = mask
    }
}
