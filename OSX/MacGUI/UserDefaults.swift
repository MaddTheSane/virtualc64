//
//  UserDefaults.swift
//  VirtualC64
//
//  Created by Dirk Hoffmann on 10.02.18.
//

import Foundation

struct VC64Keys {
    
    // General
    static let basicRom  = "VC64BasicRomFileKey"
    static let charRom   = "VC64CharRomFileKey"
    static let kernelRom = "VC64KernelRomFileKey"
    static let vc1541Rom = "VC64VC1541RomFileKey"

    // Emulator preferences dialog
    static let eyeX = "VC64EyeX"
    static let eyeY = "VC64EyeY"
    static let eyeZ = "VC64EyeZ"
    
    static let colorScheme    = "VC64ColorSchemeKey"
    static let videoUpscaler  = "VC64VideoUpscalerKey"
    static let videoFilter    = "VC64VideoFilterKey"
    static let aspectRatio    = "VC64FullscreenKeepAspectRatioKey"

    static let joyKeyMap1     = "VC64JoyKeyMap1"
    static let joyKeyMap2     = "VC64JoyKeyMap2"
    static let disconnectKeys = "VC64DisconnectKeys"
    
    // Hardware preferences dialog
    static let ntsc = "VC64PALorNTSCKey"
    
    static let warpLoad    = "VC64WarpLoadKey"
    static let driveNoise  = "VC64DriveNoiseKey"
    static let bitAccuracy = "VC64BitAccuracyKey"

    static let reSID          = "VC64SIDReSIDKey"
    static let audioChip      = "VC64SIDChipModelKey"
    static let audioFilter    = "VC64SIDFilterKey"
    static let samplingMethod = "VC64SIDSamplingMethodKey"
}

/// This class extension handles the UserDefaults management

extension MyController {
    
    // --------------------------------------------------------------------------------
    //                                 Default values
    // --------------------------------------------------------------------------------


    /// Registers the default values of all user definable properties
    @objc static func registerUserDefaults() {
        
        track()
        registerEmulatorUserDefaults()
        registerHardwareUserDefaults()
        
        let dictionary : [String:Any] = [
        
            VC64Keys.basicRom: "",
            VC64Keys.charRom: "",
            VC64Keys.kernelRom: "",
            VC64Keys.vc1541Rom: ""
        ]
        
        let defaults = UserDefaults.standard
        defaults.register(defaults: dictionary)
    }
    
    /// Registers the default values for all proporties that are set in the hardware dialog
    static func registerEmulatorUserDefaults() {
        
        track()
        let dictionary : [String:Any] = [
            
            VC64Keys.eyeX: 0.0,
            VC64Keys.eyeY: 0.0,
            VC64Keys.eyeZ: 0.0,
        
            VC64Keys.colorScheme: VICE.rawValue,
            VC64Keys.videoUpscaler: 1,
            VC64Keys.videoFilter: 2,
            VC64Keys.aspectRatio: false,
        
            VC64Keys.disconnectKeys: true
        ]
        
        let defaults = UserDefaults.standard
        defaults.register(defaults: dictionary)
    }
    
    /// Registers the default values for all proporties that are set in the hardware dialog
    static func registerHardwareUserDefaults() {
        
        track()
        let dictionary : [String:Any] = [
        
            VC64Keys.ntsc: false,
        
            VC64Keys.warpLoad: true,
            VC64Keys.driveNoise: true,
            VC64Keys.bitAccuracy: true,
        
            VC64Keys.reSID: true,
            VC64Keys.audioChip: 1,
            VC64Keys.audioFilter: false,
            VC64Keys.samplingMethod: 0
        ]
        
        let defaults = UserDefaults.standard
        defaults.register(defaults: dictionary)
    }
    
    // --------------------------------------------------------------------------------
    //                                  Loading
    // --------------------------------------------------------------------------------

    /// Loads all user defaults from database
    @objc func loadUserDefaults() {
        
        track()
        loadEmulatorUserDefaults()
        loadHardwareUserDefaults()
    }
    
    /// Loads the user defaults for all properties that are set in the hardware dialog
    @objc func loadEmulatorUserDefaults() {
        
        track()
        let defaults = UserDefaults.standard
        eyeX = defaults.float(forKey: VC64Keys.eyeX)
        eyeY = defaults.float(forKey: VC64Keys.eyeY)
        eyeZ = defaults.float(forKey: VC64Keys.eyeZ)
		c64.vic.colorScheme = defaults.integer(forKey: VC64Keys.colorScheme)
        videoUpscaler = defaults.integer(forKey: VC64Keys.videoUpscaler)
        videoFilter = defaults.integer(forKey: VC64Keys.videoFilter)
        fullscreenKeepAspectRatio = defaults.bool(forKey: VC64Keys.aspectRatio)
        if let data = defaults.data(forKey: VC64Keys.joyKeyMap1) {
            if let keymap = try? JSONDecoder().decode(KeyMap.self, from: data) {
               gamePadManager.gamePads[0]?.keymap = keymap
            }
        }
        if let data = defaults.data(forKey: VC64Keys.joyKeyMap2) {
            if let keymap = try? JSONDecoder().decode(KeyMap.self, from: data) {
                gamePadManager.gamePads[1]?.keymap = keymap
            }
        }
        keyboardcontroller.setDisconnectEmulationKeys(defaults.bool(forKey: VC64Keys.disconnectKeys))
    }
    
    /// Loads the user defaults for all properties that are set in the hardware dialog
    @objc func loadHardwareUserDefaults() {
        
        track()
        let defaults = UserDefaults.standard
		c64.isNTSC = defaults.bool(forKey: VC64Keys.ntsc)
		c64.warpLoad = defaults.bool(forKey: VC64Keys.warpLoad)
        c64.vc1541.setSendSoundMessages(defaults.bool(forKey: VC64Keys.driveNoise))
		c64.vc1541.bitAccuracy = defaults.bool(forKey: VC64Keys.bitAccuracy)
		c64.reSID = defaults.bool(forKey: VC64Keys.reSID)
        c64.setChipModel(defaults.integer(forKey: VC64Keys.audioChip))
		c64.audioFilter = defaults.bool(forKey: VC64Keys.audioFilter)
        c64.setSamplingMethod(defaults.integer(forKey: VC64Keys.samplingMethod))
    }
    
    // --------------------------------------------------------------------------------
    //                                  Saving
    // --------------------------------------------------------------------------------

    /// Saves all user defaults from database
    @objc func saveUserDefaults() {
        
        track()
        saveEmulatorUserDefaults()
        saveHardwareUserDefaults()
    }
    
    /// Saves the user defaults for all properties that are set in the hardware dialog
    @objc func saveEmulatorUserDefaults() {
     
        track()
        let defaults = UserDefaults.standard
        defaults.set(eyeX, forKey: VC64Keys.eyeX)
        defaults.set(eyeY, forKey: VC64Keys.eyeY)
        defaults.set(eyeZ, forKey: VC64Keys.eyeZ)
        defaults.set(c64.vic.colorScheme, forKey: VC64Keys.colorScheme)
        defaults.set(videoUpscaler, forKey: VC64Keys.videoUpscaler)
        defaults.set(videoFilter, forKey: VC64Keys.videoFilter)
        defaults.set(fullscreenKeepAspectRatio, forKey: VC64Keys.aspectRatio)
        if let keymap = try? JSONEncoder().encode(gamePadManager.gamePads[0]?.keymap) {
            defaults.set(keymap, forKey: VC64Keys.joyKeyMap1)
        }
        if let keymap = try? JSONEncoder().encode(gamePadManager.gamePads[1]?.keymap) {
            defaults.set(keymap, forKey: VC64Keys.joyKeyMap2)
        }
        defaults.set(getDisconnectEmulationKeys, forKey: VC64Keys.disconnectKeys)
    }
    
    /// Saves the user defaults for all properties that are set in the hardware dialog
    @objc func saveHardwareUserDefaults() {
        
        track()
        let defaults = UserDefaults.standard
        defaults.set(c64.isNTSC, forKey: VC64Keys.ntsc)
        defaults.set(c64.warpLoad, forKey: VC64Keys.warpLoad)
        defaults.set(c64.vc1541.soundMessagesEnabled, forKey: VC64Keys.driveNoise)
        defaults.set(c64.vc1541.bitAccuracy, forKey: VC64Keys.bitAccuracy)
        defaults.set(c64.reSID, forKey: VC64Keys.reSID)
        defaults.set(c64.chipModel(), forKey: VC64Keys.audioChip)
        defaults.set(c64.audioFilter, forKey: VC64Keys.audioFilter)
        defaults.set(c64.samplingMethod(), forKey: VC64Keys.samplingMethod)
    }
    
    // --------------------------------------------------------------------------------
    //                          Restore factory settings
    // --------------------------------------------------------------------------------

    /// Restores the factory settings for all user defaults except the ROM settings
    func restoreUserDefaults() {
        
        track()
        restoreEmulatorUserDefaults()
        restoreHardwareUserDefaults()
    }
    
    /// Restores the factory settings for all properties that are set in the hardware dialog
    @objc func restoreEmulatorUserDefaults() {
        
        track()
        gamePadManager.restoreFactorySettings()
        
        // Remove keys
        let keys: [String] = [
            VC64Keys.eyeX,
            VC64Keys.eyeY,
            VC64Keys.eyeZ,
            VC64Keys.colorScheme,
            VC64Keys.videoUpscaler,
            VC64Keys.videoFilter,
            VC64Keys.aspectRatio,
            VC64Keys.joyKeyMap1,
            VC64Keys.joyKeyMap2,
            VC64Keys.disconnectKeys
        ]
        let defaults = UserDefaults.standard
        for key in keys {
            defaults.removeObject(forKey: key)
        }

        // Reload to restore the registered default values
        loadEmulatorUserDefaults()
    }
    
    /// Restores the factory settings for all properties that are set in the hardware dialog
    @objc func restoreHardwareUserDefaults() {
        
        track()
        // Remove keys
        let keys: [String] = [
            VC64Keys.ntsc,
            VC64Keys.warpLoad,
            VC64Keys.driveNoise,
            VC64Keys.bitAccuracy,
            VC64Keys.reSID,
            VC64Keys.audioChip,
            VC64Keys.audioFilter,
            VC64Keys.samplingMethod
        ]
        let defaults = UserDefaults.standard
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        
        // Reload to restore the registered default values
        loadHardwareUserDefaults()
    }
}
