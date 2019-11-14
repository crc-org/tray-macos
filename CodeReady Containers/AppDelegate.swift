//
//  AppDelegate.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 12/11/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var statusMenuItem: NSMenuItem!
    @IBOutlet weak var deleteMenuItem: NSMenuItem!
    @IBOutlet weak var stopMenuItem: NSMenuItem!
    @IBOutlet weak var startMenuItem: NSMenuItem!
    @IBOutlet weak var webConsoleMenuItem: NSMenuItem!
    @IBOutlet weak var ocLoginForKubeadmin: NSMenuItem!
    @IBOutlet weak var ocLoginForDeveloper: NSMenuItem!
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("crcEye"))
        }
        statusItem.menu = self.menu
        
        updateStatusMenuItem()

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func startMenuClicked(_ sender: Any) {
    }
    @IBAction func stopMenuClicked(_ sender: Any) {
    }
    @IBAction func deleteMenuClicked(_ sender: Any) {
    }
    @IBAction func webConsoleMenuClicked(_ sender: Any) {
    }
    @IBAction func copyOcLoginForKubeadminMenuClicked(_ sender: Any) {
    }
    @IBAction func copyOcLoginForDeveloperMenuClicked(_ sender: Any) {
    }
    
    func updateStatusMenuItem() {
        self.statusMenuItem.title = "OpenShift Cluster is running"
        self.statusMenuItem.image = NSImage(named:NSImage.statusAvailableName)
    }
    
    @IBAction func quitTrayMenuClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
}

