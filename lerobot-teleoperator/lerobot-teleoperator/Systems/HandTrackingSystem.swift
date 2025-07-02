import RealityKit
import ARKit

struct HandTrackingSystem: System {
    static var arSession = ARKitSession()
    static let handTracking = HandTrackingProvider()
    static var latestLeftHand: HandAnchor?
    static var latestRightHand: HandAnchor?

    init(scene: RealityKit.Scene) {
        Task { await Self.runSession() }
    }

    @MainActor
    static func runSession() async {
        do {
            if handTracking.state == .initialized {
                try await arSession.run([handTracking])
                print("Hand tracking session started successfully")
            } else {
                print("Hand tracking provider not initialized")
            }
        } catch let error as ARKitSession.Error {
            print("The app has encountered an error while running providers: \(error.localizedDescription)")
        } catch let error {
            print("The app has encountered an unexpected error: \(error.localizedDescription)")
        }

        for await anchorUpdate in handTracking.anchorUpdates {
            switch anchorUpdate.anchor.chirality {
            case .left:
                self.latestLeftHand = anchorUpdate.anchor
                HandTrackingData.shared.updateHand(anchor: anchorUpdate.anchor, chirality: .left)
            case .right:
                self.latestRightHand = anchorUpdate.anchor
                HandTrackingData.shared.updateHand(anchor: anchorUpdate.anchor, chirality: .right)
            }
            
            // Send both hands data via HTTP (HTTPManager will check isActive internally)
            HTTPManager.shared.sendBothHands(
                left: HandTrackingData.shared.leftHand.isTracked ? HandTrackingData.shared.leftHand : nil,
                right: HandTrackingData.shared.rightHand.isTracked ? HandTrackingData.shared.rightHand : nil
            )
        }
    }
    
    static let query = EntityQuery(where: .has(HandTrackingComponent.self))
    
    func update(context: SceneUpdateContext) {
        let handEntities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)

        for entity in handEntities {
            guard var handComponent = entity.components[HandTrackingComponent.self] else { continue }

            if handComponent.fingers.isEmpty {
                self.addJoints(to: entity, handComponent: &handComponent)
            }

            guard let handAnchor: HandAnchor = switch handComponent.chirality {
                case .left: Self.latestLeftHand
                case .right: Self.latestRightHand
                default: nil
            } else { continue }

            if let handSkeleton = handAnchor.handSkeleton {
                for (jointName, jointEntity) in handComponent.fingers {
                    let anchorFromJointTransform = handSkeleton.joint(jointName).anchorFromJointTransform
                    jointEntity.setTransformMatrix(
                        handAnchor.originFromAnchorTransform * anchorFromJointTransform,
                        relativeTo: nil
                    )
                }
            }
        }
    }
    
    func addJoints(to handEntity: Entity, handComponent: inout HandTrackingComponent) {
        let radius: Float = 0.01
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let sphereEntity = ModelEntity(
            mesh: .generateSphere(radius: radius),
            materials: [material]
        )

        for bone in Hand.joints {
            let newJoint = sphereEntity.clone(recursive: false)
            handEntity.addChild(newJoint)
            handComponent.fingers[bone.0] = newJoint
        }

        handEntity.components.set(handComponent)
    }
}