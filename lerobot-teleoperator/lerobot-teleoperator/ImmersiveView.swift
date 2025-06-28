//
//  ImmersiveView.swift
//  lerobot-teleoperator
//
//  Created by Jong Hyun Park on 6/28/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct ImmersiveView: View {
    @State private var handTrackingEntity: Entity?

    var body: some View {
        RealityView { content in
            // Create hand tracking entities
            let leftHandEntity = Entity()
            leftHandEntity.components.set(HandTrackingComponent(chirality: .left))
            content.add(leftHandEntity)
            
            let rightHandEntity = Entity()
            rightHandEntity.components.set(HandTrackingComponent(chirality: .right))
            content.add(rightHandEntity)
            
            print("ImmersiveView: Hand tracking entities added")
        } update: { content in
            // Update hand tracking data for monitoring
            Task {
                await updateHandTrackingData()
            }
        }
    }
    
    @MainActor
    private func updateHandTrackingData() async {
        // This will be called by the RealityKit update cycle
        // The HandTrackingSystem will handle the actual tracking
        // and update the HandTrackingData singleton
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
