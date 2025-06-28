import SwiftUI
import RealityKit
import ARKit

struct HandTrackingView: View {
    var body: some View {
        RealityView { content in
            makeHandEntities(in: content)
        }
    }

    @MainActor
    func makeHandEntities(in content: any RealityViewContentProtocol) {
        let leftHand = Entity()
        leftHand.components.set(HandTrackingComponent(chirality: .left))
        content.add(leftHand)

        let rightHand = Entity()
        rightHand.components.set(HandTrackingComponent(chirality: .right))
        content.add(rightHand)
    }
}