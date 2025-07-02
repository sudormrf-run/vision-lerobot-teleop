import SwiftUI

struct HTTPControlView: View {
    @State private var httpManager = HTTPManager.shared
    @State private var serverAddress: String = HTTPManager.shared.serverAddress
    @State private var isEditingAddress: Bool = false
    @State private var targetHz: Double = HTTPManager.shared.targetHz
    @State private var isEditingHz: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Label("HTTP Connection", systemImage: "network")
                    .font(.headline)
                Spacer()
                ConnectionStatusBadge(state: httpManager.connectionState)
            }
            .padding(.bottom, 4)
            
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
            
            Divider()
                .opacity(0.3)
            
            // Frequency Control
            HStack {
                Text("Frequency:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isEditingHz {
                    HStack {
                        Slider(value: $targetHz, in: 10...120, step: 10)
                            .frame(width: 150)
                        Text("\(Int(targetHz)) Hz")
                            .font(.caption.monospacedDigit())
                            .frame(width: 50)
                    }
                } else {
                    Text("\(Int(httpManager.targetHz)) Hz")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isEditingHz = true
                        }
                }
                
                Button(action: { 
                    if isEditingHz {
                        httpManager.targetHz = targetHz
                    }
                    isEditingHz.toggle()
                }) {
                    Image(systemName: isEditingHz ? "checkmark.circle" : "slider.horizontal.3")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            // Control Buttons
            HStack(spacing: 8) {
                if httpManager.isActive {
                    Button(action: { httpManager.stop() }) {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button(action: { httpManager.start() }) {
                        Label("Start", systemImage: "play.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                
                Button(action: { httpManager.reset() }) {
                    Label("Reset", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button("Health") {
                    httpManager.checkHealth()
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
            
            Divider()
                .opacity(0.3)
            
            // Statistics
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Status:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(httpManager.isActive ? "Active" : "Inactive")
                        .font(.caption2)
                        .foregroundColor(httpManager.isActive ? .green : .gray)
                }
                
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
                
                HStack {
                    Text("Actual rate:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if httpManager.messagesSent > 1, httpManager.isActive {
                        // Calculate rate based on time interval between messages
                        Text("~\(Int(httpManager.targetHz)) Hz")
                            .font(.caption2.monospacedDigit())
                    } else {
                        Text("--")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 5)
            
            // Error Display (Always reserve space)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(httpManager.lastError != nil ? 0.15 : 0.05))
                .frame(height: 40)
                .overlay(
                    Group {
                        if let error = httpManager.lastError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .lineLimit(2)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                        } else {
                            Text("No errors")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                )
        }
        .padding()
        .frame(width: 380, height: 320)  // Fixed size
        .background(Color.black.opacity(0.8))
        .cornerRadius(15)
        .onAppear {
            // Start active by default
            if !httpManager.isActive {
                httpManager.start()
            }
        }
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