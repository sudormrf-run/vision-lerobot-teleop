import SwiftUI

struct HTTPControlView: View {
    @State private var httpManager = HTTPManager.shared
    @State private var serverAddress: String = HTTPManager.shared.serverAddress
    @State private var isEditingAddress: Bool = false
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Label("HTTP Connection", systemImage: "network")
                    .font(.headline)
                Spacer()
                ConnectionStatusBadge(state: httpManager.connectionState)
            }
            
            // Server Address
            HStack {
                Text("Server:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isEditingAddress {
                    TextField("http://host:port", text: $serverAddress)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .onSubmit {
                            httpManager.serverAddress = serverAddress
                            isEditingAddress = false
                        }
                } else {
                    Text(httpManager.serverAddress)
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
            
            // Health Check Button
            HStack(spacing: 10) {
                Button("Check Health") {
                    httpManager.checkHealth()
                }
                .buttonStyle(.bordered)
            }
            
            // Statistics
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Messages sent:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(httpManager.messagesSent)")
                        .font(.caption2.monospacedDigit())
                }
                
                if let lastTime = httpManager.lastMessageTime {
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
            
            // Error Display
            if let error = httpManager.lastError {
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
    let state: HTTPManager.ConnectionState
    
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
        case .idle: return .gray
        case .sending: return .orange
        case .success: return .green
        case .failed: return .red
        }
    }
    
    private var statusText: String {
        switch state {
        case .idle: return "Idle"
        case .sending: return "Sending"
        case .success: return "Success"
        case .failed: return "Failed"
        }
    }
}

#Preview {
    HTTPControlView()
}