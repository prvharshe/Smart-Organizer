import SwiftUI
import AppKit

class MenuBarController: NSObject, NSMenuDelegate {
    private var statusBarItem: NSStatusItem
    
    override init() {
        //FileOrganizer.resetFolderAccess()
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()  // Ensure superclass initialization before setting up the menu

        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "folder.fill.badge.gearshape", accessibilityDescription: "File Organizer")
            button.action = #selector(menuButtonClicked)
            button.target = self
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self // Set delegate to enable menu items

        let organizeItem = NSMenuItem(title: "Organize Now", action: #selector(organizeFiles), keyEquivalent: "O")
        organizeItem.target = self  // Ensure target is set

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "Q")
        quitItem.target = self  // Ensure target is set

        menu.addItem(organizeItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)

        statusBarItem.menu = menu
    }
    
    @objc private func menuButtonClicked() {
        statusBarItem.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
    
    @objc private func organizeFiles() {
        print("Organizing files...")
        FileOrganizer.organizeDownloads()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // ✅ Fix: Ensure menu items are enabled
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true  // Enable all menu items
    }
}
