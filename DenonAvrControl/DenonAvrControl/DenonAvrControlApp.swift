//
//  DenonAvrControlApp.swift
//  DenonAvrControl
//
//  Created by Nicholas Long on 6/14/25.
//

import SwiftUI

@main
struct DenonAvrControlApp: App {
    @StateObject private var receiverModel = ReceiverStateModel(ipAddress: UserDefaults.standard.string(forKey: "ReceiverIP") ?? "")
    @State private var ipAddress: String = UserDefaults.standard.string(forKey: "ReceiverIP") ?? ""
    @State private var testResult: TestResult = TestResult(success: nil, message: nil)
    @State private var isTestingConnection: Bool = false

    @State private var didPollOnLaunch = false
    var body: some Scene {
        MenuBarExtra("🔊 Volume", systemImage: "speaker.wave.2") {
            ControlView(receiverModel: receiverModel)
                .frame(width: 320)
                .onAppear {
                    receiverModel.startPolling()
                    if !didPollOnLaunch {
                        receiverModel.performImmediatePoll()
                        didPollOnLaunch = true
                    }
                }
                .onDisappear {
                    receiverModel.stopPolling()
                }
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: "settings") {
            SettingsView(
                ipAddress: $ipAddress,
                onSave: {
                    UserDefaults.standard.set(ipAddress, forKey: "ReceiverIP")
                    receiverModel.updateIPAddress(ipAddress)
                    receiverModel.startPolling()
                },
                onTest: { testIP in
                    isTestingConnection = true
                    receiverModel.validateConnection(ip: testIP) { success, message in
                        DispatchQueue.main.async {
                            testResult = TestResult(success: success, message: message)
                            isTestingConnection = false
                        }
                    }
                },
                testResult: testResult,
                isTesting: isTestingConnection,
                receiverModel: receiverModel,
            )
        }
    }
}
