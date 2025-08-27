import SwiftUI

struct ContentView: View {
    @StateObject private var kickDetector = KickDetector()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Kick-up Counter")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingSettings.toggle()
                    }) {
                        Image(systemName: "gear")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                
                // Kick Count Display
                VStack {
                    Text("\(kickDetector.kickCount)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: kickDetector.kickCount)
                    
                    Text("Kick-ups")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                
                // Camera View
                CameraView(kickDetector: kickDetector)
                    .aspectRatio(4/3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(kickDetector.isInCooldown ? Color.green : Color.red, lineWidth: 3)
                    )
                    .animation(.easeInOut(duration: 0.3), value: kickDetector.isInCooldown)
                
                // Distance Plot
                DistancePlotView(distances: kickDetector.distanceHistory, isInCooldown: kickDetector.isInCooldown)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(UIColor.systemGray6))
                    )
                
                // Control Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        kickDetector.reset()
                    }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    
                    Button(action: {
                        kickDetector.isDetectionEnabled.toggle()
                    }) {
                        Label(kickDetector.isDetectionEnabled ? "Stop" : "Start", 
                              systemImage: kickDetector.isDetectionEnabled ? "stop.fill" : "play.fill")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(kickDetector.isDetectionEnabled ? .red : .green)
                }
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(kickDetector: kickDetector)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var kickDetector: KickDetector
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Detection Settings") {
                    HStack {
                        Text("Contact Threshold")
                        Spacer()
                        Text("\(Int(kickDetector.contactThreshold))")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $kickDetector.contactThreshold, in: 30...150, step: 5)
                    
                    HStack {
                        Text("Cooldown Frames")
                        Spacer()
                        Text("\(kickDetector.cooldownFrames)")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: .constant(Double(kickDetector.cooldownFrames)), in: 5...30, step: 1) { editing in
                        if !editing {
                            kickDetector.cooldownFrames = Int(Double(kickDetector.cooldownFrames))
                        }
                    }
                }
                
                Section("Contact Points") {
                    Toggle("Use Ankle Detection", isOn: $kickDetector.useAnkleDetection)
                    Toggle("Use Foot Detection", isOn: $kickDetector.useFootDetection)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}