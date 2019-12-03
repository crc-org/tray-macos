//
//  AppDelegate.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 12/11/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//

import Cocoa
import UserNotifications

var notificationAllowed: Bool = false

// MenuStates is used to update the state of the menus
struct MenuStates {
    let startMenuEnabled: Bool
    let stopMenuEnabled: Bool
    let deleteMenuEnabled: Bool
    let webconsoleMenuEnabled: Bool
    let ocLoginForDeveloperEnabled: Bool
    let ocLoginForAdminEnabled: Bool
    let copyOcLoginCommand: Bool
}

struct ClusterStatus: Decodable {
    let Name: String
    let CrcStatus: String
    let OpenshiftStatus: String
    let DiskUse: Int64
    let DiskSize: Int64
    let Error: String
    let Success: Bool
}

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
    @IBOutlet weak var detailedStatusMenuItem: NSMenuItem!
    @IBOutlet weak var copyOcLoginCommand: NSMenuItem!
    
    var kubeadminPass: String!
    var apiEndpoint: String!
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            let menubarIcon = NSImage(named:NSImage.Name("TrayIcon"))
            menubarIcon?.isTemplate = true
            button.image = menubarIcon
        }
        statusItem.menu = self.menu
        initializeMenus()
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound], completionHandler: { (granted, error) in
            notificationAllowed = granted
            print(error?.localizedDescription ?? "Notification Request: No Error")
        })
    
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        // Maybe kill the daemon too
    }

    @IBAction func startMenuClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInteractive).async {
            HandleStart()
        }
    }
    
    @IBAction func stopMenuClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInteractive).async {
            HandleStop()
        }
    }
    
    @IBAction func deleteMenuClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInteractive).async {
            HandleDelete()
        }
    }
    
    @IBAction func webConsoleMenuClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInteractive).async {
            HandleWebConsoleURL()
        }
    }
    
    @IBAction func copyOcLoginForKubeadminMenuClicked(_ sender: Any) {
        if kubeadminPass != nil && apiEndpoint != nil {
            let loginCommand = String(format: "oc login -u kubeadmin -p %s %s", kubeadminPass, apiEndpoint)
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteboard.setString(loginCommand, forType: NSPasteboard.PasteboardType.string)
            print(pasteboard.string(forType: NSPasteboard.PasteboardType.string)!)
            displayNotification(title: "OC Login with kubeadmin", body: "OC Login command copied to clipboard, go ahead an login to your cluster")
        } else {
            displayNotification(title: "Failed to get login command", body: "Unable to find kubeadmin users credentials to login to the cluster")
        }
    }
    
    @IBAction func copyOcLoginForDeveloperMenuClicked(_ sender: Any) {
        if apiEndpoint != nil {
            let loginCommand = String(format: "oc login -u developer -p developer %s", apiEndpoint)
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteboard.setString(loginCommand, forType: NSPasteboard.PasteboardType.string)
            print(pasteboard.string(forType: NSPasteboard.PasteboardType.string)!)
            displayNotification(title: "OC Login with developer", body: "OC Login command copied to clipboard, go ahead an login to your cluster")
        } else {
            displayNotification(title: "Failed to get login command", body: "Unable to find api end point of the cluster")
        }
    }
    
    @IBAction func quitTrayMenuClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    func updateStatusMenuItem(status: String) {
        if status == "Stopped" {
            self.statusMenuItem.title = "Cluster is Stopped"
            self.statusMenuItem.image = NSImage(named:NSImage.statusUnavailableName)
        }
        if status == "Running" {
            self.statusMenuItem.title = "Cluster is Running"
            self.statusMenuItem.image = NSImage(named:NSImage.statusAvailableName)
        }
    }
    
    func showClusterStartingMessageOnStatusMenuItem() {
        self.statusMenuItem.title = "Cluster is starting..."
        self.statusMenuItem.image = nil
    }
    
    func updateMenuStates(state: MenuStates) {
        self.startMenuItem.isEnabled = state.startMenuEnabled
        self.stopMenuItem.isEnabled = state.stopMenuEnabled
        self.deleteMenuItem.isEnabled = state.deleteMenuEnabled
        self.webConsoleMenuItem.isEnabled = state.webconsoleMenuEnabled
        self.ocLoginForDeveloper.isEnabled = state.ocLoginForDeveloperEnabled
        self.ocLoginForKubeadmin.isEnabled = state.ocLoginForAdminEnabled
        self.copyOcLoginCommand.isEnabled = state.copyOcLoginCommand
    }
    
    func initializeMenus() {
        self.statusMenuItem.title = "Status Unknown"
        self.statusMenuItem.image = NSImage(named:NSImage.statusNoneName)
        let status = clusterStatus()
        updateStatusMenuItem(status: status)
        if status == "Running" {
            self.startMenuItem.isEnabled = false
            self.stopMenuItem.isEnabled = true
            self.deleteMenuItem.isEnabled = true
            self.webConsoleMenuItem.isEnabled = true
            self.copyOcLoginCommand.isEnabled = true
            self.ocLoginForDeveloper.isEnabled = true
            self.ocLoginForKubeadmin.isEnabled = true
        }
        if status == "Stopped" {
            self.startMenuItem.isEnabled = true
            self.stopMenuItem.isEnabled = false
            self.deleteMenuItem.isEnabled = true
            self.webConsoleMenuItem.isEnabled = false
            self.copyOcLoginCommand.isEnabled = false
            self.ocLoginForDeveloper.isEnabled = false
            self.ocLoginForKubeadmin.isEnabled = false
        } else {
            self.startMenuItem.isEnabled = true
            self.stopMenuItem.isEnabled = false
            self.deleteMenuItem.isEnabled = false
            self.webConsoleMenuItem.isEnabled = false
            self.copyOcLoginCommand.isEnabled = false
            self.ocLoginForDeveloper.isEnabled = false
            self.ocLoginForKubeadmin.isEnabled = false
        }
    }
}
