/*
 * (C) 2017 Dirk W. Hoffmann. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */


//! @brief   Holds and manages an array of GamePad objects
/*! @details Up to four devices are managed. The first two are always present and represent
 *           keyboard emulates joysticks. The other two slots are dynamically added when,
 *           a USB joystick or game pad is plugged in.
 */
@objc class GamePadManager: NSObject {
    
    // private let inputLock = NSLock()
    // Such a thing is used here: TODO: Check if we need this
    // https://github.com/joekarl/swift_handmade_hero/blob/master/Handmade%20Hero%20OSX/Handmade%20Hero%20OSX/InputManager.swift
    
    //! @brief   Reference to the the controller
    private var controller: MyController!
    
    //! @brief   Reference to the HID manager
    private var hidManager: IOHIDManager

    //! @brief   References to all registered game pads
    /*! @details Each device ist referenced by a slot number
     */
    var gamePads: [Int:GamePad] = [:]

    override init()
    {
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        super.init()
    }
    
    @objc convenience init?(controller: MyController) {
        
        self.init()
        self.controller = controller
        
        // Add  generic devices (two keyboard emulated joysticks)
        gamePads[0] = GamePad(manager: self)
        gamePads[1] = GamePad(manager: self)
        restoreFactorySettings()

        // Prepare for accepting HID devices
        let deviceCriteria = [
            [
                kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey: kHIDUsage_GD_Joystick
            ],
            [
                kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey: kHIDUsage_GD_GamePad
            ],
            [
                kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey: kHIDUsage_GD_MultiAxisController
            ]
        ]
        
        // Declare bridging closures (needed to bridge between Swift methods and C callbacks)
        let matchingCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, device in
            let this : GamePadManager = unsafeBitCast(inContext, to: GamePadManager.self)
            this.hidDeviceAdded(context: inContext, result: inResult, sender: inSender, device: device)
        }
        
        let removalCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, device in
            let this : GamePadManager = unsafeBitCast(inContext, to: GamePadManager.self)
            this.hidDeviceRemoved(context: inContext, result: inResult, sender: inSender, device: device)
        }
        
        // Configure HID manager
        let hidContext = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        IOHIDManagerSetDeviceMatchingMultiple(hidManager, deviceCriteria as CFArray)
        IOHIDManagerRegisterDeviceMatchingCallback(hidManager, matchingCallback, hidContext)
        IOHIDManagerRegisterDeviceRemovalCallback(hidManager, removalCallback, hidContext)
        IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
    
    deinit {
        track()
        IOHIDManagerClose(hidManager, IOOptionBits(kIOHIDOptionsTypeNone));
    }
    
    //! @brief   Removes all registered devices
    @objc func shutDown() {
        
        gamePads = [:];

    }
    
    //
    // Slot handling
    //
    
    //! @brief   Returns true iff the specified game pad slot is free
    @objc public func slotIsEmpty(_ nr: Int) -> Bool {
        return gamePads[nr] == nil
    }
    
    //! @brief   Returns the lowest free slot number
    /*! @details Returns nil if all slots are already filled up
     */

    func findFreeSlot() -> Int? {
        
        var nr = 0
        while !slotIsEmpty(nr) {
            nr += 1
        }
        
        // We support four devices max
        return (nr < 4) ? nr : nil
    }
    
    //! @brief   Lookup gamePad
    /*! @details Returns slot number or -1, if no such gamePad was found
     */
    func lookupGamePad(_ gamePad: GamePad) -> Int {
        
        for (slotNr, device) in gamePads {
            if (device === gamePad) {
                return slotNr
            }
        }
        return -1
    }
    
    //! @brief   Lookup gamePad by locationID
    /*! @details Returns slot number or -1, if no such gamePad was found
     */
    @objc func lookupGamePad(locationID: String) -> Int {
        
        for (slotNr, device) in gamePads {
            if (device.locationID == locationID) {
                return slotNr
            }
        }
        return -1
    }
    
    //
    // Keyboard handling
    //
    
    //! @brief   Handles a keyboard down event
    /*! @result  Returns true if a joystick event has been triggered.
     */
    @discardableResult
    func keyDown(_ key: MacKeyFingerprint) -> Bool {
        
        var result = false
        
        for (_, device) in gamePads {
            result = result || device.keyDown(key)
        }
        
        return result
    }

    //! @brief   Handles a keyboard up event
    /*! @result  Returns true if a joystick event has been triggered.
     */
    @discardableResult
    func keyUp(_ key: MacKeyFingerprint) -> Bool {
        
        var result = false
        
        for (_, device) in gamePads {
            result = result || device.keyUp(key)
        }
        
        return result
    }
    
    @objc public func keysetOfDevice(_ slotNr: Int) -> KeyMap? {
        return gamePads[slotNr]?.keymap
    }
    
    //
    // HID stuff
    //
    
    //! @brief   Device matching callback
    /*! @details Method is invoked when a matching HID device is plugged in
     */
    func hidDeviceAdded(context: Optional<UnsafeMutableRawPointer>,
                        result: IOReturn,
                        sender: Optional<UnsafeMutableRawPointer>,
                        device: IOHIDDevice) {
    
        NSLog("\(#function)")
        
        // Find a free slot for the new device
        guard let slotNr = findFreeSlot() else {
            NSLog("Maximum number of devices reached. Ignoring device")
            return
        }
        
        // Create GamePad object
        let vendorIDKey = kIOHIDVendorIDKey as CFString
        let productIDKey = kIOHIDProductIDKey as CFString
        let locationIDKey = kIOHIDLocationIDKey as CFString

        let vendorID = String(describing: IOHIDDeviceGetProperty(device, vendorIDKey))
        let productID = String(describing: IOHIDDeviceGetProperty(device, productIDKey))
        let locationID = String(describing: IOHIDDeviceGetProperty(device, locationIDKey))
        
        gamePads[slotNr] = GamePad(manager: self,
                                   vendorID: vendorID,
                                   productID: productID,
                                   locationID: locationID)
        
        // Open HID device
        let optionBits = kIOHIDOptionsTypeNone // kIOHIDOptionsTypeSeizeDevice
        let status = IOHIDDeviceOpen(device, IOOptionBits(optionBits))
        if (status != kIOReturnSuccess) {
            NSLog("WARNING: Cannot open HID device")
            return
        }
    
        // Register input value callback
        let hidContext = unsafeBitCast(gamePads[slotNr], to: UnsafeMutableRawPointer.self)
        IOHIDDeviceRegisterInputValueCallback(device, gamePads[slotNr]!.actionCallback, hidContext)

        // Inform controller
        controller.validateJoystickToolbarItems()
        
        listDevices()
    }
    
    func hidDeviceRemoved(context: Optional<UnsafeMutableRawPointer>,
                          result: IOReturn,
                          sender: Optional<UnsafeMutableRawPointer>,
                          device: IOHIDDevice) {
        
        NSLog("\(#function)")
        
        let locationIDKey = kIOHIDLocationIDKey as CFString
        let locationID = String(describing: IOHIDDeviceGetProperty(device, locationIDKey))
        
        // Search for a matching locationID and remove device
        for (slotNr, device) in gamePads {
            if (device.locationID == locationID) {
                gamePads[slotNr] = nil
                NSLog("Clearing slot %d", slotNr)
            }
        }
        
        // Closing the HID device always fails.
        // Think, we don't have to close it, because it's disconnected anyway. Am I right?
        /* 
        let optionBits = kIOHIDOptionsTypeNone // kIOHIDOptionsTypeSeizeDevice
        let status = IOHIDDeviceClose(device, IOOptionBits(optionBits))
        if (status != kIOReturnSuccess) {
            NSLog("WARNING: Cannot close HID device")
        }
        */
        
        // Inform controller
        controller.validateJoystickToolbarItems()
        
        listDevices()
    }
    
    //! @brief   Action method for events on a gamePad
    /*! @returns true, iff a joystick event has been triggered on port A or port B
     */
    @discardableResult
    func joystickEvent(_ sender: GamePad!, event: JoystickEvent) -> Bool {
    
        // Find slot of connected GamePad
        let slot = lookupGamePad(sender)
        
        // Pass joystick event to the main controller
        return controller.joystickEvent(slot: slot, event: event)
    }
 
    func listDevices() {
        
        for (slotNr, device) in gamePads {
            if (device.locationID == nil) {
                NSLog("Game pad slot %d: Keyboard emulated device", slotNr)
            } else {
                NSLog("Game pad slot %d: HID USB joystick", slotNr)
                NSLog("  Vendor ID:   %@", device.vendorID ?? "UNKNOWN");
                NSLog("  Product ID:  %@", device.productID ?? "UNKNOWN");
                NSLog("  Location ID: %@", device.locationID ?? "UNKNOWN");
            }
        }
    }
    
    @objc func restoreFactorySettings()
    {
        track()
        
        let keymap1 = gamePads[0]!.keymap
        let keymap2 = gamePads[1]!.keymap
        
        keymap1.setFingerprint(123, for: JOYSTICK_LEFT)
        keymap1.setFingerprint(124, for: JOYSTICK_RIGHT)
        keymap1.setFingerprint(126, for: JOYSTICK_UP)
        keymap1.setFingerprint(125, for: JOYSTICK_DOWN)
        keymap1.setFingerprint(49,  for: JOYSTICK_FIRE)
        
        keymap1.setCharacter(" ", for: JOYSTICK_LEFT)
        keymap1.setCharacter(" ", for: JOYSTICK_RIGHT)
        keymap1.setCharacter(" ", for: JOYSTICK_UP)
        keymap1.setCharacter(" ", for: JOYSTICK_DOWN)
        keymap1.setCharacter(" ", for: JOYSTICK_FIRE)
        
        keymap2.setFingerprint(0,  for: JOYSTICK_LEFT)
        keymap2.setFingerprint(1,  for: JOYSTICK_RIGHT)
        keymap2.setFingerprint(13,  for: JOYSTICK_UP)
        keymap2.setFingerprint(6, for: JOYSTICK_DOWN)
        keymap2.setFingerprint(7,  for: JOYSTICK_FIRE)
        
        keymap2.setCharacter("a", for: JOYSTICK_LEFT)
        keymap2.setCharacter("s", for: JOYSTICK_RIGHT)
        keymap2.setCharacter("w", for: JOYSTICK_UP)
        keymap2.setCharacter("y", for: JOYSTICK_DOWN)
        keymap2.setCharacter("x", for: JOYSTICK_FIRE)
    }
}
