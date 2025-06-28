import ARKit.hand_skeleton

struct Hand {
    static let joints: [(HandSkeleton.JointName, Finger, Bone)] = [
        (.thumbKnuckle, .thumb, .knuckle),
        (.thumbIntermediateBase, .thumb, .intermediateBase),
        (.thumbIntermediateTip, .thumb, .intermediateTip),
        (.thumbTip, .thumb, .tip),

        (.indexFingerMetacarpal, .index, .metacarpal),
        (.indexFingerKnuckle, .index, .knuckle),
        (.indexFingerIntermediateBase, .index, .intermediateBase),
        (.indexFingerIntermediateTip, .index, .intermediateTip),
        (.indexFingerTip, .index, .tip),

        (.middleFingerMetacarpal, .middle, .metacarpal),
        (.middleFingerKnuckle, .middle, .knuckle),
        (.middleFingerIntermediateBase, .middle, .intermediateBase),
        (.middleFingerIntermediateTip, .middle, .intermediateTip),
        (.middleFingerTip, .middle, .tip),

        (.ringFingerMetacarpal, .ring, .metacarpal),
        (.ringFingerKnuckle, .ring, .knuckle),
        (.ringFingerIntermediateBase, .ring, .intermediateBase),
        (.ringFingerIntermediateTip, .ring, .intermediateTip),
        (.ringFingerTip, .ring, .tip),

        (.littleFingerMetacarpal, .little, .metacarpal),
        (.littleFingerKnuckle, .little, .knuckle),
        (.littleFingerIntermediateBase, .little, .intermediateBase),
        (.littleFingerIntermediateTip, .little, .intermediateTip),
        (.littleFingerTip, .little, .tip),

        (.forearmWrist, .forearm, .wrist),
        (.forearmArm, .forearm, .arm)
    ]
}