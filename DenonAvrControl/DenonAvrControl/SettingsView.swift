import SwiftUI

import SwiftUI

struct TestResult: Equatable {
    var success: Bool?
    var message: String?
}

struct SettingsView: View {
    @Binding var ipAddress: String
    var errorMessage: String?
    var onSave: () -> Void
    var onTest: ((String) -> Void)? = nil
    var testResult: TestResult = .init(success: nil, message: nil)
    var isTesting: Bool = false
    var receiverModel: ReceiverStateModel

    @State private var localIsTesting: Bool = false
    @State private var showSpinner: Bool = false
    @State private var plainTextBoxValue: String = ""
    
    var body: some View {
        // Pause polling while settings window is active to avoid the
        // menu-bar window becoming key and hijacking keystrokes.
        // Resume polling once the window is closed again.
        VStack(alignment: .leading, spacing: 16) {
            Text("Plain Text Box:")
            TextEditor(text: $plainTextBoxValue)
                .frame(height: 80)
                .border(Color.gray.opacity(0.5))
            Text("Receiver Settings")
                .font(.title)
                .padding(.bottom, 8)
            // Receiver Settings
            Text("Receiver IP Address")
                .font(.headline)
            HStack {
                TextField("Enter IP Address", text: $ipAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Open") {
                    if let url = URL(string: "http://\(ipAddress)"), !ipAddress.isEmpty {
                        NSWorkspace.shared.open(url)
                    }
                }
                .help("Open the receiver's web interface in your browser")
            }

            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            if let result = testResult.success {
                if result {
                    Text("Connection succeeded!")
                        .foregroundStyle(.green)
                        .font(.footnote)
                }
            }
            if let result = testResult.success, !result, let msg = testResult.message {
                Text("Test failed: \(msg)")
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            HStack(spacing: 12) {
                Button(action: {
                    localIsTesting = true
                    showSpinner = false
                    // Show spinner if still testing after 0.3s
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if localIsTesting {
                            showSpinner = true
                        }
                    }
                    onTest?(ipAddress)
                }) {
                    Text("Test Connection")
                }
                .opacity(localIsTesting ? 0.5 : 1.0)
                .disabled(localIsTesting)
                if localIsTesting && showSpinner {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: 12, height: 12)
                }
                Spacer()
                Button("Save") {
                    onSave()
                    if let window = NSApp.windows.first(where: { $0.isKeyWindow }) {
                        window.close()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!(testResult.success ?? false))
            }
        }
        .padding(32)
        .frame(minWidth: 300, minHeight: 200)
        .onChange(of: testResult) { _ in
            localIsTesting = false
            showSpinner = false
        }
        .onChange(of: isTesting) { newValue in
            localIsTesting = newValue
            if !newValue { showSpinner = false }
        }
        .onChange(of: ipAddress) { _ in
            localIsTesting = false
            showSpinner = false
        }
        .onAppear {
            // Pause polling so the menu-bar window doesn't steal focus while this window is active
            receiverModel.stopPolling()
        }
        .onDisappear {
            // Resume polling once the settings window closes
            receiverModel.startPolling()
        }
    }
}

#Preview {
    let mockModel = ReceiverStateModel(ipAddress: "192.168.1.100")
    SettingsView(
        ipAddress: .constant("192.168.1.100"),
        onSave: {},
        onTest: { _ in },
        testResult: TestResult(success: nil, message: nil),
        isTesting: false,
        receiverModel: mockModel
    )
}
