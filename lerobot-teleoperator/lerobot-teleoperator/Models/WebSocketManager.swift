import Foundation
import Combine

@Observable
class WebSocketManager: NSObject {
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(Error)
        
        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected),
                 (.connecting, .connecting),
                 (.connected, .connected):
                return true
            case (.failed(_), .failed(_)):
                return true
            default:
                return false
            }
        }
    }
    
    // Connection properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var serverURL: URL?
    
    // State
    var connectionState: ConnectionState = .disconnected
    var lastError: String?
    var messagesSent: Int = 0
    var lastMessageTime: Date?
    
    // Configuration
    var serverAddress: String = "ws://192.168.1.100:8765" {  // Replace with your computer's IP
        didSet {
            if connectionState == .connected {
                disconnect()
            }
        }
    }
    
    override init() {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard connectionState != .connected else { return }
        
        guard let url = URL(string: serverAddress) else {
            connectionState = .failed(NSError(domain: "WebSocket", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            lastError = "Invalid server address"
            return
        }
        
        connectionState = .connecting
        serverURL = url
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessage()
        
        // Send ping periodically to keep connection alive
        schedulePing()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
        messagesSent = 0
    }
    
    // MARK: - Message Handling
    
    func sendHandData(_ data: HandTrackingData.HandData, isLeft: Bool) {
        guard connectionState == .connected else { return }
        
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
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(message)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            webSocketTask?.send(.string(jsonString)) { [weak self] error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                    self?.lastError = error.localizedDescription
                } else {
                    DispatchQueue.main.async {
                        self?.messagesSent += 1
                        self?.lastMessageTime = Date()
                    }
                }
            }
        } catch {
            print("Encoding error: \(error)")
            lastError = "Failed to encode hand data"
        }
    }
    
    func sendBothHands(left: HandTrackingData.HandData?, right: HandTrackingData.HandData?) {
        guard connectionState == .connected else { return }
        
        let message = BothHandsMessage(
            timestamp: Date().timeIntervalSince1970,
            leftHand: left != nil ? HandDataCompact(from: left!) : nil,
            rightHand: right != nil ? HandDataCompact(from: right!) : nil
        )
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(message)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            webSocketTask?.send(.string(jsonString)) { [weak self] error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                    self?.lastError = error.localizedDescription
                } else {
                    DispatchQueue.main.async {
                        self?.messagesSent += 1
                        self?.lastMessageTime = Date()
                    }
                }
            }
        } catch {
            print("Encoding error: \(error)")
            lastError = "Failed to encode hand data"
        }
    }
    
    // MARK: - Private Methods
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received message: \(text)")
                case .data(let data):
                    print("Received data: \(data.count) bytes")
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                DispatchQueue.main.async {
                    self?.connectionState = .failed(error)
                    self?.lastError = error.localizedDescription
                }
            }
        }
    }
    
    private func schedulePing() {
        let delay = 30.0 // Send ping every 30 seconds
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard self?.connectionState == .connected else { return }
            
            self?.webSocketTask?.sendPing { error in
                if let error = error {
                    print("Ping failed: \(error)")
                } else {
                    self?.schedulePing()
                }
            }
        }
    }
    
    // Singleton
    static let shared = WebSocketManager()
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
        DispatchQueue.main.async {
            self.connectionState = .connected
            self.lastError = nil
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected")
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
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