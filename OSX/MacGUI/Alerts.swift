//
//  Alerts.swift
//  VirtualC64
//
//  Created by Dirk Hoffmann on 29.01.18.
//

import Foundation

public extension MetalView {
    
    func showNoMetalSupportAlert() {
        
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.icon = #imageLiteral(resourceName: "metal")
        alert.messageText = "No suitable GPU hardware found"
        alert.informativeText = "VirtualC64 can only run on machines supporting the Metal graphics technology (2012 models and above)."
        alert.addButton(withTitle: "Exit")
        alert.runModal()
    }
}

extension MyDocument {
    
    func showSnapshotVersionAlert() {
        
        let alert = NSAlert()
        alert.alertStyle = .warning
        // alert.icon = NSImage.init(named: NSImage.Name(rawValue: ""))
        alert.messageText = "Snapshot from other VirtualC64 release"
        alert.informativeText = "The snapshot was created with a different version of VirtualC64 and cannot be opened."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
    
public extension MyController {
    
    @discardableResult
    func showDiskIsUnsafedAlert() -> NSApplication.ModalResponse {
       
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.icon = #imageLiteral(resourceName: "diskette")
        alert.messageText = "The inserted floppy disk has not yet been saved."
        alert.informativeText = "All data will be lost if you proceed."
        alert.addButton(withTitle: "Proceed")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal()
    }
 
    func showDiskIsEmptyAlert(format: String) {
        
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.icon = #imageLiteral(resourceName: "diskette")
        alert.messageText = "Cannot export empty disk."
        alert.informativeText = "The \(format) format is designed to store a single file."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
 
    func showDiskHasMultipleFilesAlert(format: String) {
        
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.icon = #imageLiteral(resourceName: "diskette")
        alert.messageText = "Only the first file will be exported."
        alert.informativeText = "The \(format) format is designed to store a single file."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func showUnsupportedCartridgeAlert(_ container: CRTProxy) {
        
        let name = container.cartridgeTypeName
        
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.icon = #imageLiteral(resourceName: "cartridge")
        alert.messageText = "Unsupported cartridge type: \(name)"
        alert.informativeText = "The provided cartridge contains special hardware which is not supported by the emulator yet."
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window!, completionHandler: nil)
    }

}
