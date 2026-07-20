import AudioToolbox
import CoreAudio
import Foundation
import LocusCore

enum AudioServiceError: LocalizedError {
    case noDefaultOutput
    case propertyUnavailable(String)
    case operationFailed(String, OSStatus)
    case deviceNotFound

    var errorDescription: String? {
        switch self {
        case .noDefaultOutput:
            return "未找到默认音频输出设备。"
        case .propertyUnavailable(let name):
            return "当前设备不支持“\(name)”。"
        case .operationFailed(let operation, let status):
            return "\(operation)失败（CoreAudio \(status)）。"
        case .deviceNotFound:
            return "目标输出设备当前不可用。"
        }
    }
}

final class CoreAudioService {
    private let systemObject = AudioObjectID(kAudioObjectSystemObject)

    func currentOutputDeviceID() throws -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            systemObject,
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        guard status == noErr, deviceID != 0 else {
            throw AudioServiceError.noDefaultOutput
        }
        return deviceID
    }

    func currentOutputDevice() throws -> AudioOutputDevice {
        try outputDevice(for: currentOutputDeviceID())
    }

    func outputDevices() throws -> [AudioOutputDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            systemObject,
            &address,
            0,
            nil,
            &size
        )
        guard status == noErr else {
            throw AudioServiceError.operationFailed("读取音频设备列表", status)
        }

        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(
            systemObject,
            &address,
            0,
            nil,
            &size,
            &ids
        )
        guard status == noErr else {
            throw AudioServiceError.operationFailed("读取音频设备列表", status)
        }

        return ids
            .filter { outputChannelCount(for: $0) > 0 }
            .compactMap { try? outputDevice(for: $0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func setOutputDevice(uid: String) throws {
        guard let target = try deviceID(forUID: uid) else {
            throw AudioServiceError.deviceNotFound
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var mutableTarget = target
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectSetPropertyData(
            systemObject,
            &address,
            0,
            nil,
            size,
            &mutableTarget
        )
        guard status == noErr else {
            throw AudioServiceError.operationFailed("切换输出设备", status)
        }
    }

    func currentVolume() throws -> Double {
        let deviceID = try currentOutputDeviceID()
        if let value = try readScalar(
            selector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            deviceID: deviceID,
            element: kAudioObjectPropertyElementMain
        ) {
            return Double(value)
        }

        let channels = [UInt32(1), UInt32(2)]
        let values = try channels.compactMap {
            try readScalar(
                selector: kAudioDevicePropertyVolumeScalar,
                deviceID: deviceID,
                element: $0
            )
        }
        guard !values.isEmpty else {
            throw AudioServiceError.propertyUnavailable("系统音量")
        }
        return Double(values.reduce(0, +) / Float32(values.count))
    }

    func setVolume(_ value: Double) throws {
        let deviceID = try currentOutputDeviceID()
        let scalar = Float32(min(max(value, 0), 1))
        if try writeScalar(
            scalar,
            selector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            deviceID: deviceID,
            element: kAudioObjectPropertyElementMain
        ) {
            return
        }

        var didWrite = false
        for channel in [UInt32(1), UInt32(2)] {
            didWrite = try writeScalar(
                scalar,
                selector: kAudioDevicePropertyVolumeScalar,
                deviceID: deviceID,
                element: channel
            ) || didWrite
        }
        guard didWrite else {
            throw AudioServiceError.propertyUnavailable("系统音量")
        }
    }

    func isMuted() throws -> Bool {
        let deviceID = try currentOutputDeviceID()
        if let value = try readUInt32(
            selector: kAudioDevicePropertyMute,
            deviceID: deviceID,
            element: kAudioObjectPropertyElementMain
        ) {
            return value != 0
        }
        return false
    }

    func setMuted(_ muted: Bool) throws {
        let deviceID = try currentOutputDeviceID()
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectHasProperty(deviceID, &address) else {
            if muted {
                try setVolume(0)
                return
            }
            throw AudioServiceError.propertyUnavailable("静音")
        }

        var value: UInt32 = muted ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectSetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            size,
            &value
        )
        guard status == noErr else {
            throw AudioServiceError.operationFailed("设置静音", status)
        }
    }

    private func outputDevice(for id: AudioDeviceID) throws -> AudioOutputDevice {
        let name = try stringProperty(
            selector: kAudioObjectPropertyName,
            objectID: id
        )
        let uid = try stringProperty(
            selector: kAudioDevicePropertyDeviceUID,
            objectID: id
        )
        return AudioOutputDevice(uid: uid, name: name)
    }

    private func deviceID(forUID uid: String) throws -> AudioDeviceID? {
        let devices = try outputDeviceIDs()
        return devices.first { id in
            (try? stringProperty(
                selector: kAudioDevicePropertyDeviceUID,
                objectID: id
            )) == uid
        }
    }

    private func outputDeviceIDs() throws -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            systemObject,
            &address,
            0,
            nil,
            &size
        )
        guard status == noErr else {
            throw AudioServiceError.operationFailed("读取音频设备", status)
        }
        var ids = [AudioDeviceID](
            repeating: 0,
            count: Int(size) / MemoryLayout<AudioDeviceID>.size
        )
        status = AudioObjectGetPropertyData(
            systemObject,
            &address,
            0,
            nil,
            &size,
            &ids
        )
        guard status == noErr else {
            throw AudioServiceError.operationFailed("读取音频设备", status)
        }
        return ids
    }

    private func outputChannelCount(for deviceID: AudioDeviceID) -> Int {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            deviceID,
            &address,
            0,
            nil,
            &size
        ) == noErr, size > 0 else {
            return 0
        }

        let raw = UnsafeMutableRawPointer.allocate(
            byteCount: Int(size),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { raw.deallocate() }
        let list = raw.bindMemory(to: AudioBufferList.self, capacity: 1)
        guard AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            list
        ) == noErr else {
            return 0
        }

        return UnsafeMutableAudioBufferListPointer(list).reduce(0) {
            $0 + Int($1.mNumberChannels)
        }
    }

    private func stringProperty(
        selector: AudioObjectPropertySelector,
        objectID: AudioObjectID
    ) throws -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(
            objectID,
            &address,
            0,
            nil,
            &size,
            &value
        )
        guard status == noErr, let value else {
            throw AudioServiceError.operationFailed("读取设备信息", status)
        }
        return value.takeUnretainedValue() as String
    }

    private func readScalar(
        selector: AudioObjectPropertySelector,
        deviceID: AudioDeviceID,
        element: AudioObjectPropertyElement
    ) throws -> Float32? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: element
        )
        guard AudioObjectHasProperty(deviceID, &address) else { return nil }
        var value = Float32(0)
        var size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &value
        )
        guard status == noErr else {
            throw AudioServiceError.operationFailed("读取系统音量", status)
        }
        return value
    }

    private func writeScalar(
        _ value: Float32,
        selector: AudioObjectPropertySelector,
        deviceID: AudioDeviceID,
        element: AudioObjectPropertyElement
    ) throws -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: element
        )
        guard AudioObjectHasProperty(deviceID, &address) else { return false }

        var settable = DarwinBoolean(false)
        let settableStatus = AudioObjectIsPropertySettable(
            deviceID,
            &address,
            &settable
        )
        guard settableStatus == noErr, settable.boolValue else { return false }

        var mutableValue = value
        let size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectSetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            size,
            &mutableValue
        )
        guard status == noErr else {
            throw AudioServiceError.operationFailed("设置系统音量", status)
        }
        return true
    }

    private func readUInt32(
        selector: AudioObjectPropertySelector,
        deviceID: AudioDeviceID,
        element: AudioObjectPropertyElement
    ) throws -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: element
        )
        guard AudioObjectHasProperty(deviceID, &address) else { return nil }
        var value = UInt32(0)
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &value
        )
        guard status == noErr else {
            throw AudioServiceError.operationFailed("读取静音状态", status)
        }
        return value
    }
}
