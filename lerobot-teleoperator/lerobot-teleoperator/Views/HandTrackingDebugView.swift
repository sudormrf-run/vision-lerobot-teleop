import SwiftUI

struct HandTrackingDebugView: View {
    let handData = HandTrackingData.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Hand Tracking Debug")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(spacing: 40) {
                HandDebugCard(hand: handData.leftHand)
                HandDebugCard(hand: handData.rightHand)
            }
            .padding()
        }
        .background(Color.black.opacity(0.7))
        .cornerRadius(20)
        .padding()
    }
}

struct HandDebugCard: View {
    let hand: HandTrackingData.HandData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(hand.chirality) Hand")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Circle()
                    .fill(hand.isTracked ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
            }
            
            if hand.isTracked && !hand.joints.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(hand.joints.prefix(5), id: \.name) { joint in
                            JointInfoRow(joint: joint)
                        }
                        
                        if hand.joints.count > 5 {
                            Text("... and \(hand.joints.count - 5) more joints")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxHeight: 200)
            } else {
                Text("Not Tracked")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 40)
            }
        }
        .frame(width: 250)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
    }
}

struct JointInfoRow: View {
    let joint: HandTrackingData.JointData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(joint.name)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("x: \(joint.position.x, specifier: "%.3f") y: \(joint.position.y, specifier: "%.3f") z: \(joint.position.z, specifier: "%.3f")")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HandTrackingDebugView()
}