//
//  ContentView.swift
//  lerobot-teleoperator
//
//  Created by Jong Hyun Park on 6/28/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @State private var showDebugView = false
    @State private var showMonitorView = false
    @State private var showHTTPControl = false

    var body: some View {
        ZStack {
            // Main content
            VStack {
                Text("LeRobot Teleoperator")
                    .font(.title)

                ToggleImmersiveSpaceButton()
                
                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        Toggle("Show Debug View", isOn: $showDebugView)
                            .toggleStyle(.button)
                        
                        Toggle("Show Monitor Panel", isOn: $showMonitorView)
                            .toggleStyle(.button)
                    }
                    
                    Toggle("HTTP Control", isOn: $showHTTPControl)
                        .toggleStyle(.button)
                }
                .padding(.top)
            }
            .padding()
            
            // Overlays positioned absolutely
            VStack {
                HStack {
                    // HTTP Control - Top Left
                    if showHTTPControl {
                        HTTPControlView()
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // Hand Monitor - Top Right
                    if showMonitorView {
                        HandCoordinateMonitorView()
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .animation(.easeInOut, value: showMonitorView)
        .animation(.easeInOut, value: showHTTPControl)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
