import SwiftUI

struct SourcePickerInline: View {
    @ObservedObject var receiverModel: ReceiverStateModel
    let currentInput: String
    @State private var selectedSource: String = ""

    // Reverse map: if currentInput matches any renameMap value (case-insensitive), use the corresponding key
    func reverseMappedKey(for input: String) -> String {
        if let match = receiverModel.renameMap.first(where: { $0.value.caseInsensitiveCompare(input) == .orderedSame }) {
            return match.key
        }
        return input
    }

    var body: some View {
        let mappedInput = reverseMappedKey(for: currentInput)
        // Ensure mappedInput is always in the Picker list (case-insensitive)
        let allSources: [String] = {
            var list = receiverModel.availableSources
            if !list.contains(where: { $0.caseInsensitiveCompare(mappedInput) == .orderedSame }) {
                list.append(mappedInput)
            }
            return list
        }()
        let isUnknownSource = !receiverModel.availableSources.contains(where: { $0.caseInsensitiveCompare(mappedInput) == .orderedSame })
        VStack(alignment: .leading, spacing: 2) {
            Picker("Select:", selection: $selectedSource) {
                ForEach(allSources, id: \ .self) { source in
                    Text(receiverModel.renameMap[source] ?? source)
                        .tag(source)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 210)
            .font(.subheadline)
            .onAppear {
                if selectedSource.isEmpty {
                    selectedSource = mappedInput
                }
            }
            .onChange(of: currentInput) { newInput in
                selectedSource = reverseMappedKey(for: newInput)
            }
            .onChange(of: selectedSource) { newSource in
                if newSource != mappedInput {
                    receiverModel.setInput(to: newSource)
                    receiverModel.performImmediatePoll()
                }
            }
            if isUnknownSource {
                Text("Unknown source: \(currentInput)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

extension ReceiverStateModel {
    func setInput(to source: String) {
        print("[ReceiverStateModel] Setting input to: \(source)")
        sendPostCommand(cmd: "PutZone_InputFunction/\(source)")
    }
}

#if DEBUG
    struct SourcePickerInline_Previews: PreviewProvider {
        class MockReceiverStateModel: ReceiverStateModel {
            override init(ipAddress: String = "127.0.0.1", pollingInterval: TimeInterval = 3.0) {
                super.init(ipAddress: ipAddress, pollingInterval: pollingInterval)
                availableSources = ["PHONO", "MPLAY", "NET"]
                renameMap = ["PHONO": "Vinyl", "MPLAY": "Spotify", "NET": "Network"]
            }
        }

        static var previews: some View {
            SourcePickerInline(
                receiverModel: MockReceiverStateModel(),
                currentInput: "PHONO"
            )
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
#endif
