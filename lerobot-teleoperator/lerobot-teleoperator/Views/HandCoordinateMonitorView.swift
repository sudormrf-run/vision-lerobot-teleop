import SwiftUI
import RealityKit

struct HandCoordinateMonitorView: View {
    @State private var selectedHand: String = "Left"
    @State private var showAllJoints: Bool = true
    @State private var selectedFingers: Set<String> = []
    
    private let fingerGroups = [
        "thumb": ["thumb.knuckle", "thumb.intermediateBase", "thumb.intermediateTip", "thumb.tip"],
        "index": ["index.metacarpal", "index.knuckle", "index.intermediateBase", "index.intermediateTip", "index.tip"],
        "middle": ["middle.metacarpal", "middle.knuckle", "middle.intermediateBase", "middle.intermediateTip", "middle.tip"],
        "ring": ["ring.metacarpal", "ring.knuckle", "ring.intermediateBase", "ring.intermediateTip", "ring.tip"],
        "little": ["little.metacarpal", "little.knuckle", "little.intermediateBase", "little.intermediateTip", "little.tip"],
        "forearm": ["forearm.wrist", "forearm.arm"]
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Hand Coordinate Monitor", systemImage: "hand.raised.fill")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Hand", selection: $selectedHand) {
                    Text("Left").tag("Left")
                    Text("Right").tag("Right")
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            
            // Filter Controls
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Show All Joints", isOn: $showAllJoints)
                    .onChange(of: showAllJoints) { _, newValue in
                        if newValue {
                            selectedFingers.removeAll()
                        }
                    }
                
                if !showAllJoints {
                    Text("Select Fingers:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        ForEach(Array(fingerGroups.keys.sorted()), id: \.self) { finger in
                            Toggle(finger.capitalized, isOn: Binding(
                                get: { selectedFingers.contains(finger) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedFingers.insert(finger)
                                    } else {
                                        selectedFingers.remove(finger)
                                    }
                                }
                            ))
                            .toggleStyle(.button)
                            .font(.caption)
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Joint Data Display
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    let currentHand = selectedHand == "Left" ? HandTrackingData.shared.leftHand : HandTrackingData.shared.rightHand
                    
                    if currentHand.isTracked {
                        ForEach(fingerGroups.keys.sorted(), id: \.self) { fingerKey in
                            if showAllJoints || selectedFingers.contains(fingerKey) {
                                FingerGroupView(
                                    fingerName: fingerKey,
                                    joints: currentHand.joints.filter { joint in
                                        fingerGroups[fingerKey]?.contains(joint.name) ?? false
                                    }
                                )
                            }
                        }
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "hand.raised.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("\(selectedHand) hand not tracked")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
                .padding()
            }
            
            // Summary Stats
            if selectedHand == "Left" ? HandTrackingData.shared.leftHand.isTracked : HandTrackingData.shared.rightHand.isTracked {
                let currentHand = selectedHand == "Left" ? HandTrackingData.shared.leftHand : HandTrackingData.shared.rightHand
                HStack(spacing: 20) {
                    StatCard(title: "Tracked Joints", value: "\(currentHand.joints.filter { $0.isTracked }.count)/27")
                    StatCard(title: "Hand Status", value: currentHand.isTracked ? "Active" : "Lost", color: currentHand.isTracked ? .green : .red)
                }
                .padding()
                .background(Color.black.opacity(0.7))
            }
        }
        .frame(width: 400, height: 600)
        .background(Color.black.opacity(0.9))
        .cornerRadius(20)
    }
}

struct FingerGroupView: View {
    let fingerName: String
    let joints: [HandTrackingData.JointData]
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .foregroundColor(.blue)
                    Text(fingerName.capitalized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(joints.filter { $0.isTracked }.count)/\(joints.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(joints, id: \.name) { joint in
                        JointDetailRow(joint: joint)
                    }
                }
                .padding(.leading, 20)
            }
        }
        .padding(.vertical, 5)
    }
}

struct JointDetailRow: View {
    let joint: HandTrackingData.JointData
    
    var body: some View {
        HStack {
            Circle()
                .fill(joint.isTracked ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(joint.name.components(separatedBy: ".").last ?? joint.name)
                .font(.system(.caption, design: .monospaced))
                .frame(width: 100, alignment: .leading)
            
            if joint.isTracked {
                HStack(spacing: 15) {
                    CoordinateLabel(axis: "X", value: joint.position.x, color: .red)
                    CoordinateLabel(axis: "Y", value: joint.position.y, color: .green)
                    CoordinateLabel(axis: "Z", value: joint.position.z, color: .blue)
                }
            } else {
                Text("Not tracked")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CoordinateLabel: View {
    let axis: String
    let value: Float
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(axis)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(String(format: "%+.4f", value))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    var color: Color = .blue
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

#Preview {
    HandCoordinateMonitorView()
}