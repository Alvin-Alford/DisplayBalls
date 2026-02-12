import Foundation
import IOKit
import IOKit.usb
import CoreGraphics
import AppKit
import SwiftUI


func getUSBDevices() -> [(vendorID: Int?, productID: Int?, productName: String?, SerialString: String?)] {
    let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
    var iterator: io_iterator_t = 0

    let result = IOServiceGetMatchingServices(
        kIOMainPortDefault,
        matchingDict,
        &iterator
    )

    guard result == KERN_SUCCESS else {
        print("Failed to get USB devices")
        return []
    }

    defer { IOObjectRelease(iterator) }
    var shoppingCart: [(vendorID: Int?, productID: Int?, productName: String?, SerialString: String?)]  = []
    while case let device = IOIteratorNext(iterator), device != 0 {
        defer { IOObjectRelease(device) }

        var vendorID: Int?
        var productID: Int?
        var productName: String?
        var SerialString: String?

        if let cfVendorID = IORegistryEntryCreateCFProperty(
            device,
            kUSBVendorID as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Int {
            vendorID = cfVendorID
        }

        if let cfProductID = IORegistryEntryCreateCFProperty(
            device,
            kUSBProductID as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Int {
            productID = cfProductID
        }

        if let cfProductName = IORegistryEntryCreateCFProperty(
            device,
            kUSBProductString as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String {
            productName = cfProductName
        }

        if let cfSerialString = IORegistryEntryCreateCFProperty(
            device,
            kUSBSerialNumberString as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String {
            SerialString = cfSerialString
        }

        // print("""
        // USB Device:
        //     Product Name: \(productName ?? "Unknown")
        //     Vendor ID: \(vendorID ?? -1)
        //     Product ID: \(productID ?? -1)
        //     Serial Number: \(SerialString ?? "idk")
        // """)
        shoppingCart.append((vendorID: vendorID, productID: productID, productName: productName, SerialString: SerialString))
    }
    return shoppingCart
}

func isHub() -> Bool {
    let usbDevices = getUSBDevices()

    if usbDevices.contains(where: { device in device.vendorID == 10522 && device.SerialString == "0000000000000001" }) {
        //print("found andker")
        return true
    }
    return false
}

actor isBenny {
    static let shared = isBenny()

    private var flag: Bool = false

    func set(_ value: Bool) {
        flag = value
    }

    func get() -> Bool {
        flag
    }
}

actor isAnker {
    static let shared = isAnker()

    private var flag: Bool = false

    func set(_ value: Bool) {
        flag = value
    }

    func get() -> Bool {
        flag
    }
}


@MainActor
class mangaerar {
    let VDM: VirtualDisplayManager = VirtualDisplayManager()
    var isBenny: (Bool, CGDirectDisplayID) = (false, CGDirectDisplayID(0))
    var isAnker: Bool = false
    private let notificationPort: IONotificationPortRef
    private let runLoopSource: CFRunLoopSource

    private var addedIter: io_iterator_t = 0
    private var removedIter: io_iterator_t = 0

    static let usbAddedCallback: IOServiceMatchingCallback = { (refCon, iterator) in
        // recover the instance
        let monitor = Unmanaged<mangaerar>.fromOpaque(refCon!).takeUnretainedValue()
        monitor.handle(iterator: iterator, added: true)
    }

    static let usbRemovedCallback: IOServiceMatchingCallback = { (refCon, iterator) in
        // recover the instance
        let monitor = Unmanaged<mangaerar>.fromOpaque(refCon!).takeUnretainedValue()
        monitor.handle(iterator: iterator, added: false)
    }

    private func registerForUSBNotifications() {
        let matchingDict = IOServiceMatching("IOUSBHostDevice")

        // Device added
        let monitorPointer = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())

        IOServiceAddMatchingNotification(
            notificationPort,
            kIOFirstMatchNotification,
            matchingDict,
            mangaerar.usbAddedCallback,
            monitorPointer,
            &addedIter
        )

        // Drain iterator (IMPORTANT)
        self.handle(iterator: addedIter, added: true)

        // Device removed
        IOServiceAddMatchingNotification(
            notificationPort,
            kIOTerminatedNotification,
            IOServiceMatching("IOUSBDevice"),
            mangaerar.usbRemovedCallback,
            monitorPointer,
            &removedIter
        )

        self.handle(iterator: removedIter, added: false)
    }

    private func handle(iterator: io_iterator_t, added: Bool) {
        while case let device = IOIteratorNext(iterator), device != 0 {
            defer { IOObjectRelease(device) }

            let vendorID = getIntProperty(device, kUSBVendorID as CFString)
            let productID = getIntProperty(device, kUSBProductID as CFString)
            let productName = getStringProperty(device, kUSBProductString as CFString)
            let SerialString = getStringProperty(device, kUSBSerialNumberString as CFString)

            if added {
                print("USB device added:",
                    "VID:", vendorID ?? -1,
                    "PID:", productID ?? -1,
                    "Name:", productName ?? "unknown",
                    "Serial:", SerialString ?? "-1")

                if vendorID == 1507 && SerialString == "000000001539" {
                    print("found andker")
                    isAnker = true
                    updateDisplays()
                }
            } else {
                print("USB device removed:",
                    "VID:", vendorID ?? -1,
                    "PID:", productID ?? -1,
                    "Name:", productName ?? "unknown",
                    "Serial:", SerialString ?? "-1")
                if vendorID == 1507 && SerialString == "000000001539" {
                    print("removed andker")
                    isAnker = false
                    updateDisplays()
                }
            }
        }
    }

    private func getIntProperty(_ service: io_service_t, _ key: CFString) -> Int? {
        guard let value = IORegistryEntryCreateCFProperty(
            service,
            key,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else { return nil }

        return value as? Int
    }

    private func getStringProperty(_ service: io_service_t, _ key: CFString) -> String? {
        guard let value = IORegistryEntryCreateCFProperty(
            service,
            key,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else { return nil }

        return value as? String
    }

    static let callback: CGDisplayReconfigurationCallBack = {
        display, flags, userInfo in
        guard let userInfo else { return }
        let monitor = Unmanaged<mangaerar>
            .fromOpaque(userInfo)
            .takeUnretainedValue()
        monitor.handleDisplayChange(display: display, flags: flags)
    }

    func handleDisplayChange(
        display: CGDirectDisplayID,
        flags: CGDisplayChangeSummaryFlags
    ) {
        print("Display Changed")
        if flags.contains(.addFlag) {
            print("Display added:", display)
            //let SerialNumber = CGDisplaySerialNumber(display)
            if CGDisplaySerialNumber(display) == 21573 {
                isBenny = (true, display)
            }
            updateDisplays()
        }
        if flags.contains(.removeFlag) {
            print("Display removed:", display)
            //let SerialNumber = CGDisplaySerialNumber(display)
            if CGDisplaySerialNumber(display) == 21573 {
                isBenny = (false, display)
            }
            updateDisplays()
        }
    }

    func start() {
        CGDisplayRegisterReconfigurationCallback(
            Self.callback,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    func stop() {
        CGDisplayRemoveReconfigurationCallback(
            Self.callback,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    func listAllDisplays() -> [(String, CGDirectDisplayID)] {
        var displayCount: UInt32 = 0
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)

        let error = CGGetActiveDisplayList(16, &displays, &displayCount)

        if error == .success {
            print("Active displays (\(displayCount)):")
            var shoppingCart: [(String, CGDirectDisplayID)] = []
            for i in 0..<Int(displayCount) {
                let displayID = displays[i]
                let bounds = CGDisplayBounds(displayID)
                let SerialNumber = CGDisplaySerialNumber(displayID)
                let realSize = CGDisplayScreenSize(displayID)
                print("  Display \(displayID) | \(SerialNumber): \(Int(bounds.width))x\(Int(bounds.height)) | \(realSize.width)x\(realSize.height)mm")
                shoppingCart.append((String(SerialNumber), displayID))
            }
            return shoppingCart
        } else {
            return []
        }
    }

    func updateDisplays() {
        if isAnker {
            print("Hub is")
            if VDM.virtualDisplay == nil {
                print("creating VD")
                if VDM.createVirtualDisplay(width: 2560, height: 1440, ppiX: 109, ppiY: 109, hiDPI: true, name: "VD") {
                    print("created VD")
                    let displays = VirtualDisplayManager.listAllDisplays()
                    if let benny = displays.first(where: { display in display.0 == "21573" }) {
                        if VDM.mirrorToDisplay(benny.1) {
                            print("Successfully mirrored to benny")
                        } else {
                            print("Failed to mirror to benny")
                        }
                    }
                }
            } else {
                print("VD exists")
            }
        } else {
            print("Hub no")
            if VDM.virtualDisplay != nil {
                VDM.destroy()
                print("removed VD")
            }
        }
    }

    init () {

        notificationPort = IONotificationPortCreate(kIOMainPortDefault)
        runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)


        isAnker = isHub()

        if let benny = listAllDisplays().first(where: { display in display.0 == "21573" }) {
            isBenny = (true, benny.1)
        }


        start()
        print("Monitoring display changes…")


        registerForUSBNotifications()
        print("Monitoring USB devices…")

        let app = NSApplication.shared
        app.setActivationPolicy(.regular) // or .accessory / .prohibited
        app.run()
    }



}

import NetworkExtension

@main
struct DisplayBallsMain: App {

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }

    init () {

        let fah = mangaerar()

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory) // or .accessory / .prohibited
        app.run()
    }
}



