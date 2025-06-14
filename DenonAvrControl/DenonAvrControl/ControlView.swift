//
//  ControlView.swift
//  DenonAvrControl
//
//  Created by Nicholas Long on 6/14/25.
//

import SwiftUI

import SwiftUI

struct IconButtonStyle: ButtonStyle {
    var background: Color = .accentColor
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 32, height: 32)
            .background(background.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.white)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.15), radius: configuration.isPressed ? 1 : 3, x: 0, y: configuration.isPressed ? 0 : 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

struct ModernButtonStyle: ButtonStyle {
    var background: Color = Color.accentColor
    var foreground: Color = Color.white
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(background.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(foreground)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.15), radius: configuration.isPressed ? 1 : 3, x: 0, y: configuration.isPressed ? 0 : 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

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
                HStack(alignment: .center) {
                    Text("Input:").padding(.leading, 12)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(snapshot.input)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                    Button(action: {
                        receiverModel.setPower(to: !snapshot.isOn)
                    }) {
                        Image(systemName: "power")
                            .foregroundStyle(snapshot.isOn ? .green : .red)
                            .help(snapshot.isOn ? "Power Off" : "Power On")
                    }
                    .buttonStyle(IconButtonStyle(background: .gray))
                }
                .padding(.vertical, 4)
                .padding(.trailing, 4)

                Divider()

                HStack(alignment: .center, spacing: 12) {
                    VolumeSliderView(snapshot: snapshot, receiverModel: receiverModel)
                    Button(action: {
                        receiverModel.setMute(to: !snapshot.isMuted)
                    }) {
                        Image(systemName: snapshot.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundStyle(snapshot.isMuted ? .red : .primary)
                    }
                    .buttonStyle(IconButtonStyle(background: snapshot.isMuted ? .red : .blue))
                    .help(snapshot.isMuted ? "Unmute" : "Mute")
                }
                .padding(.top, 16)

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
                if let snapshot = receiverModel.lastPolledState {
                    Text("Last updated: \(snapshot.lastUpdated.formatted(.dateTime.hour().minute().second()))")
                        .font(.footnote).padding(.leading, 12)
                }
                Spacer()
                Button(action: { openWindow(id: "settings") }) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                        .padding(.trailing, 0)
                        .padding(.bottom, 0)
                        .help("Settings")
                }
                .buttonStyle(IconButtonStyle(background: .gray))
                .padding(.trailing, 12)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 0)
            .padding(.bottom, 4)
        }
        .frame(width: 300)
    }
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSnapshot = ReceiverStateSnapshot(
            isOn: true,
            volume: -40.0,
            isMuted: false,
            input: "CD",
            lastUpdated: Date()
        )
        let mockModel = ReceiverStateModel(ipAddress: "0.0.0.0")
        mockModel.lastPolledState = mockSnapshot
        return ControlView(receiverModel: mockModel)
    }
}

