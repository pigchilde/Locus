import SwiftUI

struct AddRuleSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var ssid = ""
    @State private var volume = 0.35
    @State private var outputDeviceUID: String?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Image(systemName: "wifi")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 11))
                Text("添加 Wi‑Fi 规则")
                    .font(.system(size: 17, weight: .bold))
                Text("设置连接这个网络后要自动恢复的音量。")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)

            Form {
                TextField("网络名称", text: $ssid)
                    .textFieldStyle(.roundedBorder)

                Picker("输出设备", selection: $outputDeviceUID) {
                    Text("保持当前设备").tag(String?.none)
                    ForEach(model.availableDevices) { device in
                        Text(device.name).tag(Optional(device.uid))
                    }
                }

                HStack {
                    Text("系统音量")
                    Slider(value: $volume, in: 0...1)
                    Text(volume, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .trailing)
                }
            }
            .formStyle(.grouped)
            .frame(height: 178)

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("添加规则") {
                    if model.addRule(
                        ssid: ssid,
                        volume: volume,
                        outputDeviceUID: outputDeviceUID
                    ) != nil {
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, 16)
        }
        .padding(24)
        .frame(width: 430)
        .onAppear {
            ssid = model.currentSSID ?? ""
            volume = model.currentVolume
            outputDeviceUID = nil
        }
    }
}
