//
//  ControlView.swift
//  DenonAvrControl
//
//  Created by Nicholas Long on 6/14/25.
//

import SwiftUI

import SwiftUI

struct ControlView: View {
    // ...


private struct VolumeSliderView: View {
    let snapshot: ReceiverStateSnapshot
    let receiverModel: ReceiverStateModel
    @State private var sliderValue: Double
    
    init(snapshot: ReceiverStateSnapshot, receiverModel: ReceiverStateModel) {
        self.snapshot = snapshot
        self.receiverModel = receiverModel
        _sliderValue = State(initialValue: Double(snapshot.volume))
    }

    var body: some View {
        HStack {
            Text("Vol")
            Slider(
                value: $sliderValue,
                in: -80.5...18.0,
                step: 1.0,
                onEditingChanged: { editing in
                    if !editing {
                        print("[DenonAvr] VolumeSliderView: User released slider at \(sliderValue) dB")
                        receiverModel.setVolume(to: Float(sliderValue))
                    }
                }
            )
            .frame(width: 100)
            Text("\(String(format: "%.1f dB", sliderValue))")
                .font(.footnote)
        }
    }
}

    @ObservedObject var receiverModel: ReceiverStateModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            if let snapshot = receiverModel.lastPolledState {
                HStack {
                    Text("Volume: \(String(format: "%.1f", snapshot.volume))")
                    Spacer()
                    Button(action: {
                        receiverModel.setPower(to: !snapshot.isOn)
                    }) {
                        Image(systemName: "power")
                            .foregroundStyle(snapshot.isOn ? .green : .red)
                            .help(snapshot.isOn ? "Power Off" : "Power On")
                    }
                }
                .padding(.top, 6)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Input: ")
                        Text(snapshot.input)
                        Spacer()
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Text("Vol")
                        // Use @State for slider value
                        VolumeSliderView(snapshot: snapshot, receiverModel: receiverModel)

                        Button(action: {
                            receiverModel.setMute(to: !snapshot.isMuted)
                        }) {
                            Image(systemName: snapshot.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .foregroundStyle(snapshot.isMuted ? .red : .primary)
                        }
                        .help(snapshot.isMuted ? "Unmute" : "Mute")
                    }
                }

                Text("Last updated: \(snapshot.lastUpdated.formatted(.dateTime.hour().minute().second()))")
                    .font(.footnote)
            } else {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.top, 20)
                    Text(receiverModel.isConnected ? "Loading receiver state..." : "Not connected to receiver.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = receiverModel.errorMessage {
                Text("Error: \(error)")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()
            HStack {
                Spacer()
                Button(action: { openWindow(id: "settings") }) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                        .padding(.trailing, 6)
                        .padding(.bottom, 4)
                        .help("Settings")
                }
            }
            .padding(.top, 10)
        }
        .frame(width: 300)
    }
}


struct VolumeView: View {
    @Binding var ipAddress: String
    @State private var volume: Double = 0.5
    @State private var status: String = ""

    var body: some View {
        VStack(spacing: 10) {
            Text("Radio Volume")
            Slider(value: $volume)
                .frame(width: 150)
            Button("Set Volume") {
                setVolume()
            }
            if !status.isEmpty {
                Text(status)
                    .font(.footnote)
            }
        }
        .padding()
    }
    
    func setVolume() {
        status = "Set volume to \(volume) for IP: \(ipAddress)"
    }
}

#Preview {
    VolumeView(ipAddress: .constant("192.168.1.100"))
}

