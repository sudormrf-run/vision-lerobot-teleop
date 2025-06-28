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

    var body: some View {
        VStack {
            Text("LeRobot Teleoperator")
                .font(.title)

            ToggleImmersiveSpaceButton()
            
            HStack(spacing: 20) {
                Toggle("Show Debug View", isOn: $showDebugView)
                    .toggleStyle(.button)
                
                Toggle("Show Monitor Panel", isOn: $showMonitorView)
                    .toggleStyle(.button)
            }
            .padding(.top)
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            if showMonitorView {
                HandCoordinateMonitorView()
                    .offset(x: -20, y: 100)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showMonitorView)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
