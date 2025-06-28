import SwiftUI

struct WebSocketControlView: View {
    @State private var webSocketManager = WebSocketManager.shared
    @State private var serverAddress: String = WebSocketManager.shared.serverAddress
    @State private var isEditingAddress: Bool = false
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Label("WebSocket Connection", systemImage: "network")
                    .font(.headline)
                Spacer()
                ConnectionStatusBadge(state: webSocketManager.connectionState)
            }
            
            // Server Address
            HStack {
                Text("Server:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isEditingAddress {
                    TextField("ws://host:port", text: $serverAddress)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .onSubmit {
                            webSocketManager.serverAddress = serverAddress
                            isEditingAddress = false
                        }
                } else {
                    Text(webSocketManager.serverAddress)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isEditingAddress = true
                        }
                }
                
                Button(action: { isEditingAddress.toggle() }) {
                    Image(systemName: isEditingAddress ? "checkmark.circle" : "pencil.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            // Connection Button
            HStack(spacing: 10) {
                switch webSocketManager.connectionState {
                case .disconnected:
                    Button("Connect") {
                        webSocketManager.connect()
                    }
                    .buttonStyle(.borderedProminent)
                    
                case .connecting:
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Connecting...")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                case .connected:
                    Button("Disconnect") {
                        webSocketManager.disconnect()
                    }
                    .buttonStyle(.bordered)
                    
                case .failed:
                    Button("Retry") {
                        webSocketManager.connect()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
            
            // Statistics
            if webSocketManager.connectionState == .connected {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Messages sent:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(webSocketManager.messagesSent)")
                            .font(.caption2.monospacedDigit())
                    }
                    
                    if let lastTime = webSocketManager.lastMessageTime {
                        HStack {
                            Text("Last sent:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(lastTime, style: .relative)
                                .font(.caption2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Error Display
            if let error = webSocketManager.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(width: 320)
        .background(Color.black.opacity(0.8))
        .cornerRadius(15)
    }
}

struct ConnectionStatusBadge: View {
    let state: WebSocketManager.ConnectionState
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch state {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .failed: return .red
        }
    }
    
    private var statusText: String {
        switch state {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .failed: return "Failed"
        }
    }
}

#Preview {
    WebSocketControlView()
}