//
//  ControlView.swift
//  DenonAvrControl
//
//  Created by Nicholas Long on 6/14/25.
//

import SwiftUI

import SwiftUI

struct ControlView: View {
    @ObservedObject var receiverModel: ReceiverStateModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Volume: \(receiverModel.volume)")
                Spacer()
                if receiverModel.isOn {
                    Image(systemName: "power")
                        .foregroundStyle(.green)
                        .help("Receiver ON")
                } else {
                    Image(systemName: "power")
                        .foregroundStyle(.red)
                        .help("Receiver OFF")
                }
            }
            .padding(.top, 6)

            Divider()

            HStack {
                Text("Input: ")
                Text(receiverModel.input)
                Spacer()
            }
            .padding(.vertical, 4)

            if let updated = receiverModel.lastUpdated {
                Text("Last updated: \(updated.formatted(.dateTime.hour().minute().second()))")
                    .font(.footnote)
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
        .frame(width: 220)
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

