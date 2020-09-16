//
//  ConfigViewController.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 01/07/20.
//  Copyright © 2020 Red Hat. All rights reserved.
//

import Cocoa

class ConfigViewController: NSViewController {
    // preferences->Advaced controls
    @IBOutlet weak var checkBundleCached: NSPopUpButton!
    @IBOutlet weak var checkHyperkitDriverCached: NSPopUpButton!
    @IBOutlet weak var checkPodmanCached: NSPopUpButton!
    @IBOutlet weak var checkResolverFilePermission: NSPopUpButton!
    @IBOutlet weak var checkRunningAsRoot: NSPopUpButton!
    @IBOutlet weak var checkRamSize: NSPopUpButton!
    @IBOutlet weak var checkHostsFilePermissions: NSPopUpButton!
    @IBOutlet weak var disableUpdateCheck: NSButton!
    @IBOutlet weak var nameservers: NSTextField!
    
    // preferences->properties controls
    @IBOutlet weak var bundlePathField: NSTextField!
    @IBOutlet weak var cpusTextField: NSTextField!
    @IBOutlet weak var enableExperimentalFeatures: NSButton!
    @IBOutlet weak var httpProxy: NSTextField!
    @IBOutlet weak var httpsProxy: NSTextField!
    @IBOutlet weak var memory: NSTextField!
    @IBOutlet weak var noProxy: NSTextField!
    @IBOutlet weak var pullSecretFilePathTextField: NSTextField!
    @IBOutlet weak var proxyCaFile: NSTextField!
    @IBOutlet weak var useProxy: NSButton!
    
    // change trackers
    var textFiedlChangeTracker: [NSTextField : NSTextField]? = [:]
    var buttonChangeTracker: [NSButton : NSButton]? = [:]
    var popupButtonChangeTracker: [NSPopUpButton : NSPopUpButton]? = [:]
    var changedConfigs: CrcConfigs?
    var configsNeedingUnset: [String] = []
    
    var preflightChecksInitialConfig: [NSPopUpButton : Int] = [:]
    var needsUnset: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.height)
        self.parent?.view.window?.level = .floating
        self.view.window?.level = .floating
        self.LoadConfigs()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.parent?.view.window?.title = self.title!
    }
    
    func LoadConfigs() {
        var configs: CrcConfigs? = nil
        DispatchQueue.global(qos: .background).async {
            do{
                if (try GetAllConfigFromDaemon()) != nil {
                    configs = try GetAllConfigFromDaemon()!
                }
            }
            catch DaemonError.noResponse {
                DispatchQueue.main.async {
                    showAlertFailedAndCheckLogs(message: "Did not receive any response from the daemon", informativeMsg: "Ensure the CRC daemon is running, for more information please check the logs")
                }
            }
            catch {
                DispatchQueue.main.async {
                    showAlertFailedAndCheckLogs(message: "Bad response", informativeMsg: "Undefined error")
                }
            }
            
            
            DispatchQueue.main.async {
                // Load preflight config values
                self.loadPreflightCheckConfigs(configs: configs)
                
                // Load config property values
                self.bundlePathField?.stringValue = configs?.bundle ?? "Unset"
                self.cpusTextField?.intValue = Int32(configs?.cpus ?? 0)
                // determine update check config
                self.disableUpdateCheck?.alternateTitle = "Update Checks are Disabled"
                if configs?.disableUpdateCheck == nil {
                    self.disableUpdateCheck?.state = .off
                } else {
                    self.disableUpdateCheck?.state =
                        (configs?.disableUpdateCheck)! ? .on : .off
                }
                // determine experimental features config
                self.enableExperimentalFeatures?.alternateTitle = "Experimental Features are Enabled"
                if configs?.enableExperimentalFeatures == nil {
                    self.enableExperimentalFeatures?.state = .off
                } else {
                    self.enableExperimentalFeatures?.state = (configs?.enableExperimentalFeatures)! ? .on : .off
                }
                
                self.httpProxy?.stringValue = configs?.httpProxy ?? "Unset"
                self.httpsProxy?.stringValue = configs?.httpsProxy ?? "Unset"
                self.proxyCaFile?.stringValue = configs?.proxyCaFile ?? "Unset"
                self.memory?.intValue = Int32(configs?.memory ?? 0)
                self.nameservers?.stringValue = configs?.nameserver ?? "Unset"
                self.noProxy?.stringValue = configs?.noProxy ?? "Unset"
                self.pullSecretFilePathTextField?.stringValue = configs?.pullSecretFile ?? "Unset"
            }
        }
    }
    
    func loadPreflightCheckConfigs(configs: CrcConfigs?) {
        let viewsAndConfigs: [(NSPopUpButton?, Bool?, Bool?)] = [
            (self.checkBundleCached, configs?.skipCheckBundleCached, configs?.warnCheckBundleCached),
            (self.checkHyperkitDriverCached, configs?.skipCheckHyperkitDriver, configs?.warnCheckHyperkitDriver),
            (self.checkPodmanCached, configs?.skipCheckPodmanCached, configs?.warnCheckPodmanCached),
            (self.checkResolverFilePermission, configs?.skipCheckResolverFilePermissions, configs?.warnCheckResolverFilePermissions),
            (self.checkRunningAsRoot, configs?.skipCheckRootUser, configs?.warnCheckRootUser),
            (self.checkRamSize, configs?.skipCheckRam, configs?.warnCheckRam),
            (self.checkHostsFilePermissions, configs?.skipCheckHostsFilePermissions, configs?.warnCheckHostsFilePermissions)
        ]

        for c in viewsAndConfigs {
            guard  let popbuttonControl = c.0 else { return }
            preflightChecksInitialConfig[popbuttonControl] = c.0?.indexOfSelectedItem
            setPopupButtonViewFromConfig(button: c.0, skip: c.1, warn: c.2)
        }
    }
    
    func setPopupButtonViewFromConfig(button: NSPopUpButton?, skip: Bool?, warn: Bool?) {
        if warn ?? false {
            button?.selectItem(at: 2)
        } else if skip ?? false {
            button?.selectItem(at: 1)
        } else {
            // restore to default state again
            button?.selectItem(at: 0)
            button?.item(at: 0)?.isEnabled = false
        }
    }
    
    func showFilePicker(msg: String, txtField: NSTextField) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = msg
        dialog.showsResizeIndicator    = false
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
        dialog.canCreateDirectories    = false
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = ["json", "txt", "crcbundle"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let filePath = dialog.url // Pathname of the file
            
            if (filePath != nil) {
                txtField.setValue(filePath?.path, forKey: "stringValue")
                return
            }
        }
        // User clicked cancel
        return
    }
    
    @IBAction func bundlePathButtonClicked(_ sender: Any) {
        self.showFilePicker(msg: "Select CodeReady Containers Bundle", txtField: self.bundlePathField)
        self.textFiedlChangeTracker?[self.bundlePathField] = self.bundlePathField
    }
    
    @IBAction func pullSecretFileButtonClicked(_ sender: Any) {
        self.showFilePicker(msg: "Select the Pull Secret file", txtField: self.pullSecretFilePathTextField)
        self.textFiedlChangeTracker?[self.pullSecretFilePathTextField] = self.pullSecretFilePathTextField
    }
    
    @IBAction func proxyCaFileButtonClicked(_ sender: Any) {
    
    }
    
    @IBAction func propertiesRefreshClicked(_ sender: Any) {
        // Empty the change trackers
        textFiedlChangeTracker = [:]
        buttonChangeTracker = [:]
        popupButtonChangeTracker = [:]
        preflightChecksInitialConfig = [:]
        changedConfigs = CrcConfigs()
        configsNeedingUnset = []
        self.LoadConfigs()
    }
    
    @IBAction func propertiesApplyClicked(_ sender: Any) {
        changedConfigs = CrcConfigs()
        if self.textFiedlChangeTracker != nil {
            for c in self.textFiedlChangeTracker! {
                switch c.value.identifier {
                case self.bundlePathField?.identifier:
                    self.changedConfigs?.bundle = c.value.stringValue
                case self.pullSecretFilePathTextField?.identifier:
                    self.changedConfigs?.pullSecretFile = c.value.stringValue
                case self.cpusTextField?.identifier:
                    self.changedConfigs?.cpus = c.value.doubleValue
                case self.httpProxy?.identifier:
                    self.changedConfigs?.httpProxy = c.value.stringValue
                case self.httpsProxy?.identifier:
                    self.changedConfigs?.httpsProxy = c.value.stringValue
                case self.memory?.identifier:
                    self.changedConfigs?.memory = c.value.doubleValue
                case self.nameservers?.identifier:
                    self.changedConfigs?.nameserver = c.value.stringValue
                case self.noProxy?.identifier:
                    self.changedConfigs?.noProxy = c.value.stringValue
                default:
                    print("Should not reach here: TextField")
                }
            }
        }
        if self.buttonChangeTracker != nil {
            for c in self.buttonChangeTracker! {
                print(c.value.title)
                switch c.value {
                case self.enableExperimentalFeatures:
                    self.changedConfigs?.enableExperimentalFeatures = Bool(exactly: NSNumber(value: c.value.state.rawValue))
                default:
                    print("should not reach here: button change tracker")
                }
            }
        }
        // present action sheet alert and ask for confirmation
        let alert = NSAlert()
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.messageText = "Are you sure you want to apply these changes?"
        alert.informativeText = "After clicking Apply all your config changes will be applied"
        alert.beginSheetModal(for: self.view.window!) { (response) in
            if response == .alertFirstButtonReturn {
                // encode the json for configset and send it to the daemon
                let configsJson = configset(properties: self.changedConfigs ?? CrcConfigs())
                guard let res = SendCommandToDaemon(command: ConfigsetRequest(command: "setconfig", args: configsJson)) else { return }
                print(String(data: res, encoding: .utf8) ?? "Nothing")
            }
        }
    }
    
    @IBAction func preflightRefreshClicked(_ sender: Any) {
        // Empty the change trackers
        textFiedlChangeTracker = [:]
        buttonChangeTracker = [:]
        popupButtonChangeTracker = [:]
        preflightChecksInitialConfig = [:]
        changedConfigs = CrcConfigs()
        configsNeedingUnset = []
        self.LoadConfigs()
    }
    
    @IBAction func preflightApplyClicked(_ sender: Any) {
        changedConfigs = CrcConfigs()
        for c in preflightChecksInitialConfig {
            switch c.key {
            case self.checkResolverFilePermission:
                if c.value != self.checkResolverFilePermission?.indexOfSelectedItem {
                    self.changedConfigs?.skipCheckResolverFilePermissions = (self.checkResolverFilePermission?.indexOfSelectedItem == 1)
                }
            case self.checkBundleCached:
                if c.value != self.checkBundleCached?.indexOfSelectedItem {
                    switch self.checkBundleCached?.indexOfSelectedItem {
                    case 0:
                        print("Getting there")
                        self.needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["skip-check-bundle-cached", "warn-check-bundle-cached"])
                    case 1,2:
                        self.changedConfigs?.skipCheckBundleCached = (self.checkBundleCached?.indexOfSelectedItem == 1)
                    default:
                        print("should not reach here")
                    }
                }
            case self.checkHyperkitDriverCached:
                if c.value != self.checkHyperkitDriverCached?.indexOfSelectedItem {
                    self.changedConfigs?.skipCheckHyperkitDriver = (self.checkHyperkitDriverCached?.indexOfSelectedItem == 1)
                }
            case self.checkPodmanCached:
                if c.value != self.checkPodmanCached?.indexOfSelectedItem {
                    self.changedConfigs?.skipCheckPodmanCached = (self.checkPodmanCached?.indexOfSelectedItem == 1)
                }
            case self.checkRunningAsRoot:
                if c.value != self.checkRunningAsRoot?.indexOfSelectedItem {
                    self.changedConfigs?.skipCheckRootUser = (self.checkRunningAsRoot?.indexOfSelectedItem == 1)
                }
            case self.checkRamSize:
                if c.value != self.checkRamSize?.indexOfSelectedItem {
                    self.changedConfigs?.skipCheckRam = (self.checkRamSize?.indexOfSelectedItem == 1)
                }
            case self.checkHostsFilePermissions:
                if c.value != self.checkHostsFilePermissions?.indexOfSelectedItem {
                    self.changedConfigs?.skipCheckHostsFilePermissions = (self.checkHostsFilePermissions?.indexOfSelectedItem == 1)
                }
            default:
                print("Should not reach here")
            }
        }
        
        if self.buttonChangeTracker != nil {
            for c in self.buttonChangeTracker! {
                switch c.value {
                case self.disableUpdateCheck:
                    self.changedConfigs?.disableUpdateCheck = Bool(exactly: NSNumber(value: c.value.state.rawValue))
                default:
                    print("should not reach here")
                }
            }
        }
        
        if self.textFiedlChangeTracker != nil {
            for c in self.textFiedlChangeTracker! {
                switch c.value {
                case self.nameservers:
                    self.changedConfigs?.nameserver = c.value.stringValue
                default:
                    print("should not reach here")
                }
            }
        }
        
        // present action sheet alert and ask for confirmation
        let alert = NSAlert()
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.messageText = "Are you sure you want to apply these changes?"
        alert.informativeText = "After clicking Apply all your config changes will be applied"
        alert.beginSheetModal(for: self.view.window!) { (response) in
            if response == .alertFirstButtonReturn {
                // encode the json for configset and send it to the daemon
                let configsJson = configset(properties: self.changedConfigs ?? CrcConfigs())
                guard let res = SendCommandToDaemon(command: ConfigsetRequest(command: "setconfig", args: configsJson)) else { return }
                print(String(data: res, encoding: .utf8) ?? "Nothing")
                if self.configsNeedingUnset.count > 0 {
                    print(self.configsNeedingUnset)
                    guard let res = SendCommandToDaemon(command: ConfigunsetRequest(command: "unsetconfig", args: configunset(properties: self.configsNeedingUnset))) else { return }
                    print(String(data: res, encoding: .utf8) ?? "Nothing")
                }
            }
        }
    }
    
    @IBAction func disableUpdateCheckClicked(_ sender: Any) {
        trackButtonClicks(sender)
    }
    
    @IBAction func enableExpFeaturesButtonClicked(_ sender: Any) {
        trackButtonClicks(sender)
    }
    
    func trackButtonClicks(_ sender: Any) {
        guard let button = sender as? NSButton else { return }
        self.buttonChangeTracker?[button] = button
    }
}

extension ConfigViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object else { print("False notification, nothing changed"); return }
        self.textFiedlChangeTracker?[textField as! NSTextField] = textField as? NSTextField
    }
}
