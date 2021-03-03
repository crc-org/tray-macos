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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
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
    
    let statusRefreshRate: TimeInterval = 5 // seconds
    var kubeadminPass: String!
    var apiEndpoint: String!
    var status: String = ""
    
    weak var pullSecretWindowController: PullSecretWindowController?
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            let menubarIcon = NSImage(named:NSImage.Name("TrayIcon"))
            menubarIcon?.isTemplate = true
            button.image = menubarIcon
        }
        menu.delegate = self
        statusItem.menu = self.menu
        
        let applications = NSWorkspace.shared.runningApplications
        for app in applications {
            if app == NSWorkspace.shared.self {
                NSApplication.shared.terminate(self)
            }
        }
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound], completionHandler: { (granted, error) in
            notificationAllowed = granted
            print(error?.localizedDescription ?? "Notification Request: No Error")
        })
        
        DispatchQueue.global(qos: .background).async {
            self.refreshStatusAndMenu()
        }
        
        Timer.scheduledTimer(timeInterval: statusRefreshRate, target: self, selector: #selector(refreshStatusAndMenu), userInfo: nil, repeats: true)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        // Maybe kill the daemon too
    }

    @IBAction func startMenuClicked(_ sender: Any) {
        // check if pull-secret-file is configured
        // if yes call HadleStart("")
        // otherwise invoke the pullSecretPicker view
        let response = GetConfigFromDaemon(properties: ["pull-secret-file"])
        if self.status == "Stopped" {
            DispatchQueue.global(qos: .userInteractive).async {
                HandleStart(pullSecretPath: "")
                DispatchQueue.main.sync {
                    self.statusItem.button?.appearsDisabled = false
                }
            }
        }
        else if response["pull-secret-file"] == "" {
            if pullSecretWindowController == nil {
                pullSecretWindowController = PullSecretWindowController.loadFromStoryBoard()
            }
            pullSecretWindowController?.showWindow(self)
        } else {
            DispatchQueue.global(qos: .userInteractive).async {
                HandleStart(pullSecretPath: "")
                DispatchQueue.main.sync {
                    self.statusItem.button?.appearsDisabled = false
                }
            }
        }
    }
    
    @IBAction func stopMenuClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInteractive).async {
            HandleStop()
            DispatchQueue.main.sync {
                self.statusItem.button?.appearsDisabled = true
            }
        }
    }
    
    @IBAction func deleteMenuClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInteractive).async {
            HandleDelete()
            DispatchQueue.main.sync {
                self.statusItem.button?.appearsDisabled = true
            }
        }
    }
    
    @IBAction func webConsoleMenuClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInteractive).async {
            HandleWebConsoleURL()
        }
    }
    
    @IBAction func copyOcLoginForKubeadminMenuClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInteractive).async {
            HandleLoginCommandForKubeadmin()
        }
    }
    
    @IBAction func copyOcLoginForDeveloperMenuClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInteractive).async {
            HandleLoginCommandForDeveloper()
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
    
    func showClusterStatusUnknownOnStatusMenuItem() {
        self.statusMenuItem.title = "Status Unknown"
        self.statusMenuItem.image = NSImage(named: NSImage.statusNoneName)
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
    
    func initializeMenus(status: String) {
        self.statusMenuItem.title = "Status Unknown"
        self.statusMenuItem.image = NSImage(named:NSImage.statusNoneName)
        updateStatusMenuItem(status: status)
        if status == "Running" {
            self.startMenuItem.isEnabled = false
            self.stopMenuItem.isEnabled = true
            self.deleteMenuItem.isEnabled = true
            self.webConsoleMenuItem.isEnabled = true
            self.copyOcLoginCommand.isEnabled = true
            self.ocLoginForDeveloper.isEnabled = true
            self.ocLoginForKubeadmin.isEnabled = true
            self.statusItem.button?.appearsDisabled = false
        } else if status == "Stopped" {
            self.startMenuItem.isEnabled = true
            self.stopMenuItem.isEnabled = false
            self.deleteMenuItem.isEnabled = true
            self.webConsoleMenuItem.isEnabled = false
            self.copyOcLoginCommand.isEnabled = false
            self.ocLoginForDeveloper.isEnabled = false
            self.ocLoginForKubeadmin.isEnabled = false
            self.statusItem.button?.appearsDisabled = true
        } else {
            self.startMenuItem.isEnabled = true
            self.stopMenuItem.isEnabled = false
            self.deleteMenuItem.isEnabled = false
            self.webConsoleMenuItem.isEnabled = false
            self.copyOcLoginCommand.isEnabled = false
            self.ocLoginForDeveloper.isEnabled = false
            self.ocLoginForKubeadmin.isEnabled = false
            self.statusItem.button?.appearsDisabled = true
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        DispatchQueue.global(qos: .background).async {
            self.refreshStatusAndMenu()
        }
    }
    
    @objc func refreshStatusAndMenu() {
        let status = clusterStatus()
        self.status = status
        DispatchQueue.main.async {
            self.initializeMenus(status: status)
        }
    }
}
