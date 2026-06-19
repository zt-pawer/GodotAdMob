import SwiftGodotRuntime

private func makeGodotAdMobTypes() -> [ExtensionInitializationLevel: [Object.Type]] {
    do {
        return try [
            GodotAdMob.self,
        ].prepareForRegistration()
    } catch {
        fatalError("Failed to prepare GodotAdMob registrations: \(error)")
    }
}

private let godotAdMobTypes = makeGodotAdMobTypes()

public let godotAdMobMinimumInitializationLevel = minimumInitializationLevel(
    for: godotAdMobTypes
)

public func godotAdMobInitialize(level: ExtensionInitializationLevel) {
    godotAdMobTypes[level]?.forEach(register)
}

public func godotAdMobDeinitialize(level: ExtensionInitializationLevel) {
    godotAdMobTypes[level]?.reversed().forEach(unregister)
}

@_cdecl("godot_ad_mob_start")
public func godotAdMobStart(interface: OpaquePointer?, library: OpaquePointer?, extension: OpaquePointer?) -> UInt8 {
    guard let interface, let library, let `extension` else {
        print("Error: Not all parameters were initialized.")
        return 0
    }
    initializeSwiftModule(
        interface,
        library,
        `extension`,
        initHook: godotAdMobInitialize,
        deInitHook: godotAdMobDeinitialize,
        minimumInitializationLevel: godotAdMobMinimumInitializationLevel
    )
    return 1
}
