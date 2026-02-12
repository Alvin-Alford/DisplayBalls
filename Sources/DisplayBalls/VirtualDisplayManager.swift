import Foundation
import CoreGraphics
import CGVirtualDisplay

public class VirtualDisplayManager {
    public var virtualDisplay: AnyObject?
    public var displayID: CGDirectDisplayID = 0

    public init() {}
    public func createVirtualDisplay(width: UInt32, height: UInt32, ppiX: Double = 96, ppiY: Double = 96, hiDPI: Bool, name: String) -> Bool {
        // Create descriptor
        guard let descriptor = VirtualDisplayBridge.createDescriptor(
            withWidth: width,
            height: height,
            ppiX: ppiX,
            ppiY: ppiY,
            hiDPI: hiDPI,
            name: name
        ) else {
            print("Failed to create descriptor")
            return false
        }

        // Create virtual display
        guard let display = VirtualDisplayBridge.createDisplay(withDescriptor: descriptor) else {
            print("Failed to create virtual display")
            return false
        }

        self.virtualDisplay = display as AnyObject
        self.displayID = VirtualDisplayBridge.getDisplayID(fromVirtualDisplay: display)

        print("Created virtual display with ID: \(displayID)")
        return true
    }

    public func getDisplayID() -> CGDirectDisplayID {
        return displayID
    }

    public func mirrorToDisplay(_ targetDisplayID: CGDirectDisplayID) -> Bool {
        guard displayID != 0 else {
            print("No virtual display created")
            return false
        }

        var config: CGDisplayConfigRef?
        var error = CGBeginDisplayConfiguration(&config)

        guard error == .success, let config = config else {
            print("Failed to begin display configuration")
            return false
        }

        error = CGConfigureDisplayMirrorOfDisplay(config, targetDisplayID, displayID)

        if error == .success {
            error = CGCompleteDisplayConfiguration(config, .permanently)
            if error == .success {
                print("Successfully configured mirroring")
                return true
            } else {
                print("Failed to complete configuration: \(error)")
            }
        } else {
            print("Failed to configure mirroring: \(error)")
            CGCancelDisplayConfiguration(config)
        }

        return false
    }

    public func destroy() {
        guard let display = virtualDisplay else { return }

        if VirtualDisplayBridge.destroyDisplay(display) {
            print("Virtual display destroyed")
            virtualDisplay = nil
            displayID = 0
        }
    }

    public static func listAllDisplays() -> [(String, CGDirectDisplayID)] {
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
}