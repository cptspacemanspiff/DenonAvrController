//
//  ControlView.swift
//  DenonAvrControl
//
//  Created by Nicholas Long on 6/14/25.
//

import SwiftUI

struct IconButtonStyle: ButtonStyle {
    var background: Color = .accentColor
    var foreground: Color = .white
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 32, height: 32)
            .background(background.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(foreground)
            .clipShape(Circle())
            .shadow(
                color: .black.opacity(0.15), radius: configuration.isPressed ? 1 : 3, x: 0,
                y: configuration.isPressed ? 0 : 2
            )
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
            .shadow(
                color: .black.opacity(0.15), radius: configuration.isPressed ? 1 : 3, x: 0,
                y: configuration.isPressed ? 0 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

struct ControlView: View {
    // ...

    private struct VolumeSliderView: View {
        let snapshot: ReceiverStateSnapshot
        let receiverModel: ReceiverStateModel
        @State private var sliderValue: Double = 0.0
        @State private var isEditing: Bool = false

        var body: some View {
            HStack {
                Text("Volume:")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Slider(
                    value: Binding(
                        get: { sliderValue },
                        set: { newValue in
                            let snapped = (newValue * 2).rounded() / 2  // Snap to nearest 0.5
                            sliderValue = snapped
                        }
                    ),
                    in: -80.5...18.0,
                    onEditingChanged: { editing in
                        isEditing = editing
                        if !editing {
                            receiverModel.setVolume(to: Float(sliderValue))
                        }
                    }
                )
                .frame(width: 105)
                Text("\(String(format: "%.1f dB", sliderValue))")
                    .font(.footnote)
            }
            .onAppear {
                sliderValue = Double(snapshot.volume)
            }
            .onChange(of: snapshot.volume) { newVolume in
                if !isEditing {
                    sliderValue = Double(newVolume)
                }
            }
        }
    }

    @ObservedObject var receiverModel: ReceiverStateModel
    @Environment(\.openWindow) private var openWindow
    @State private var isSettingsHovered: Bool = false
    @State private var isQuitHovered: Bool = false
    var body: some View {
        VStack(spacing: 0) {
            if let snapshot = receiverModel.lastPolledState {
                HStack(alignment: .center, spacing: 0) {
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        SourcePickerInline(
                            receiverModel: receiverModel,
                            currentInput: snapshot.input
                        )
                    }
                    .frame(width: 180, alignment: .leading)
                    Spacer()
                    Toggle(
                        isOn: Binding(
                            get: { snapshot.isOn },
                            set: { newValue in receiverModel.setPower(to: newValue) }
                        )
                    ) {
                        Image(systemName: "power")
                            .foregroundColor(.secondary)
                            .help(snapshot.isOn ? "Power Off" : "Power On")
                    }
                    .toggleStyle(.switch).tint(.accentColor)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)

                Divider()
                    .padding(.horizontal, 8)

                HStack(alignment: .center, spacing: 0) {
                    VolumeSliderView(snapshot: snapshot, receiverModel: receiverModel)
                        .frame(width: 210, alignment: .leading)
                    Spacer()
                    Toggle(
                        isOn: Binding(
                            get: { !snapshot.isMuted },
                            set: { newValue in receiverModel.setMute(to: !newValue) }
                        )
                    ) {
                        Image(
                            systemName: snapshot.isMuted
                                ? "speaker.slash.fill" : "speaker.wave.2.fill"
                        )
                        .foregroundColor(.secondary)
                    }
                    .toggleStyle(.switch).tint(.accentColor)
                    .help(snapshot.isMuted ? "Mute" : "Unmute")
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)

            } else {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.top, 20)
                    Text(
                        receiverModel.isConnected
                            ? "Loading receiver state..." : "Not connected to receiver."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }

            if let error = receiverModel.errorMessage {
                Text("Error: \(error)")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer(minLength: 0)
            HStack(alignment: .center) {
                if let snapshot = receiverModel.lastPolledState {
                    Text(
                        "Last updated: \(snapshot.lastUpdated.formatted(.dateTime.hour().minute().second()))"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { openWindow(id: "settings") }) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                        .foregroundColor(isSettingsHovered ? .accentColor : .secondary)
                        .help("Settings")
                        .scaleEffect(isSettingsHovered ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: isSettingsHovered)
                }
                .buttonStyle(IconButtonStyle(background: .clear, foreground: .secondary))
                .onHover { hovering in
                    isSettingsHovered = hovering
                }

                Button(action: { NSApp.terminate(nil) }) {
                    Text("Quit")
                        .help("Quit the app")
                }
                .buttonStyle(
                    IconButtonStyle(
                        background: .clear,
                        foreground: isQuitHovered ? .accentColor : .secondary)
                )
                .scaleEffect(isQuitHovered ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isQuitHovered)
                .onHover { hovering in
                    isQuitHovered = hovering
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 320)
    }
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSnapshot = ReceiverStateSnapshot(
            isOn: true,
            volume: -40.0,
            isMuted: true,
            input: "CD",
            lastUpdated: Date()
        )
        let mockModel = ReceiverStateModel(ipAddress: "0.0.0.0")
        mockModel.lastPolledState = mockSnapshot
        return ControlView(receiverModel: mockModel)
    }
}
