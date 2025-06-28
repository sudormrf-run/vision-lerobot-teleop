import Foundation
import SwiftUI
import ARKit
import RealityKit
import simd

@Observable
class HandTrackingData {
    struct JointData {
        let name: String
        let position: SIMD3<Float>
        let isTracked: Bool
    }
    
    struct HandData {
        var joints: [JointData] = []
        var isTracked: Bool = false
        var chirality: String
    }
    
    var leftHand = HandData(chirality: "Left")
    var rightHand = HandData(chirality: "Right")
    
    func updateHand(anchor: HandAnchor, chirality: AnchoringComponent.Target.Chirality) {
        var handData = HandData(chirality: chirality == .left ? "Left" : "Right")
        handData.isTracked = anchor.handSkeleton != nil
        
        if let skeleton = anchor.handSkeleton {
            handData.joints = Hand.joints.map { joint in
                let transform = anchor.originFromAnchorTransform * skeleton.joint(joint.0).anchorFromJointTransform
                let position = transform.columns.3
                return JointData(
                    name: "\(joint.1).\(joint.2)",
                    position: SIMD3<Float>(position.x, position.y, position.z),
                    isTracked: skeleton.joint(joint.0).isTracked
                )
            }
        }
        
        if chirality == .left {
            leftHand = handData
        } else {
            rightHand = handData
        }
    }
    
    static let shared = HandTrackingData()
}