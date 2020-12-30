//
//  ConfigViewController.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 01/07/20.
//  Copyright © 2020 Red Hat. All rights reserved.
//

import Cocoa

struct configResult: Decodable {
    let Error: String
    let Properties: [String]?
}

class ConfigViewController: NSViewController {
    // preferences->Advaced controls
    
    @IBOutlet weak var skipCheckBundleCached: NSButton!
    @IBOutlet weak var skipCheckHyperkitDriverCached: NSButton!
    @IBOutlet weak var skipCheckPodmanCached: NSButton!
    @IBOutlet weak var skipCheckResolverFilePermission: NSButton!
    @IBOutlet weak var skipCheckRunningAsRoot: NSButton!
    @IBOutlet weak var skipCheckRAMSize: NSButton!
    @IBOutlet weak var skipCheckHostsFilePermission: NSButton!
    @IBOutlet weak var skipCheckOCCached: NSButton!
    @IBOutlet weak var skipCheckAdminHelperCached: NSButton!
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
    @IBOutlet weak var proxyCAFileButton: NSButton!
    @IBOutlet weak var diskSize: NSTextField!
    
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
                
                // check if proxy configs are set and display them in the preferences window
                self.httpProxy?.stringValue = configs?.httpProxy ?? "Unset"
                self.httpsProxy?.stringValue = configs?.httpsProxy ?? "Unset"
                self.proxyCaFile?.stringValue = configs?.proxyCaFile ?? "Unset"
                self.noProxy?.stringValue = configs?.noProxy ?? "Unset"
                if configs?.httpProxy != "" || configs?.httpsProxy != "" {
                    self.httpProxy?.isEnabled = true
                    self.httpsProxy?.isEnabled = true
                    self.noProxy?.isEnabled = true
                    self.proxyCaFile?.isEnabled = true
                    self.proxyCAFileButton?.isEnabled = true
                    self.useProxy?.state = .on
                } else {
                    self.useProxy?.state = .off
                    self.useProxyClicked(self)
                }
                
                self.memory?.doubleValue = Float64(configs?.memory ?? 0)
                self.nameservers?.stringValue = configs?.nameserver ?? "Unset"
                self.diskSize?.doubleValue = Float64(configs?.diskSize ?? 0)
                self.pullSecretFilePathTextField?.stringValue = configs?.pullSecretFile ?? "Unset"
            }
        }
    }
    
    func loadPreflightCheckConfigs(configs: CrcConfigs?) {
        let preflightCheckBoxes: [(NSButton?, Bool?)] = [
            (self.skipCheckBundleCached, configs?.skipCheckBundleExtracted),
            (self.skipCheckHyperkitDriverCached, configs?.skipCheckHyperkitDriver),
            (self.skipCheckPodmanCached, configs?.skipCheckPodmanCached),
            (self.skipCheckResolverFilePermission, configs?.skipCheckResolverFilePermissions),
            (self.skipCheckRunningAsRoot, configs?.skipCheckRootUser),
            (self.skipCheckRAMSize, configs?.skipCheckRam),
            (self.skipCheckHostsFilePermission, configs?.skipCheckHostsFilePermissions),
            (self.skipCheckOCCached, configs?.skipCheckOcCached),
            (self.skipCheckAdminHelperCached, configs?.skipCheckGoodhostsCached)
        ]
        
        for index in 0...(preflightCheckBoxes.count - 1) {
            guard let checkBox = preflightCheckBoxes[index].0 else { print("Not found in \(index)"); return }
            let config = preflightCheckBoxes[index].1 ?? false
            checkBox.state = config ? .on : .off
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
    
    @IBAction func bundlePathButtonClicked(_ sender: Any) {
        showFilePicker(msg: "Select CodeReady Containers Bundle", txtField: self.bundlePathField, fileTypes: ["crcbundle"])
        self.textFiedlChangeTracker?[self.bundlePathField] = self.bundlePathField
    }
    
    @IBAction func pullSecretFileButtonClicked(_ sender: Any) {
        showFilePicker(msg: "Select the Pull Secret file", txtField: self.pullSecretFilePathTextField, fileTypes: [])
        self.textFiedlChangeTracker?[self.pullSecretFilePathTextField] = self.pullSecretFilePathTextField
    }
    
    @IBAction func proxyCaFileButtonClicked(_ sender: Any) {
        showFilePicker(msg: "Select CA file for your proxy", txtField: self.proxyCaFile, fileTypes: [])
        self.textFiedlChangeTracker?[self.proxyCaFile] = self.proxyCaFile
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
                    if c.value.stringValue == "" {
                        needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["bundle"])
                    } else {
                        self.changedConfigs?.bundle = c.value.stringValue
                    }
                case self.pullSecretFilePathTextField?.identifier:
                    if c.value.stringValue == "" {
                        needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["pull-secret-file"])
                    } else {
                        self.changedConfigs?.pullSecretFile = c.value.stringValue
                    }
                case self.cpusTextField?.identifier:
                    if c.value.stringValue == "" {
                        needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["cpus"])
                    } else {
                        self.changedConfigs?.cpus = c.value.doubleValue
                    }
                case self.httpProxy?.identifier:
                    if c.value.stringValue == "" {
                        needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["http-proxy"])
                    } else {
                        self.changedConfigs?.httpProxy = c.value.stringValue
                    }
                case self.httpsProxy?.identifier:
                    if c.value.stringValue == "" {
                        needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["https-proxy"])
                    } else {
                        self.changedConfigs?.httpsProxy = c.value.stringValue
                    }
                case self.memory?.identifier:
                    if c.value.stringValue == "" {
                        needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["memory"])
                    } else {
                        self.changedConfigs?.memory = c.value.doubleValue
                    }
                case self.diskSize?.identifier:
                    if c.value.stringValue == "" {
                        needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["disk-size"])
                    } else {
                        self.changedConfigs?.diskSize = c.value.doubleValue
                    }
                case self.nameservers?.identifier:
                    if c.value.stringValue == "" {
                        needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["nameserver"])
                    } else {
                        self.changedConfigs?.nameserver = c.value.stringValue
                    }
                case self.noProxy?.identifier:
                    if c.value.stringValue == "" {
                        needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["no-proxy"])
                    } else {
                        self.changedConfigs?.noProxy = c.value.stringValue
                    }
                case self.proxyCaFile?.identifier:
                    if c.value.stringValue == "" {
                        needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["proxy-ca-file"])
                    } else {
                        self.changedConfigs?.proxyCaFile = c.value.stringValue
                    }
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
                do {
                    let result = try JSONDecoder().decode(configResult.self, from: res)
                    if !result.Error.isEmpty {
                        let alert = NSAlert()
                        alert.informativeText = "\(result.Error)"
                        alert.messageText = "Error"
                        alert.alertStyle = .warning
                        alert.runModal()
                    }
                } catch let jsonErr {
                    print(jsonErr)
                }
                if self.configsNeedingUnset.count > 0 {
                    print(self.configsNeedingUnset)
                    guard let res = SendCommandToDaemon(command: ConfigunsetRequest(command: "unsetconfig", args: configunset(properties: self.configsNeedingUnset))) else { return }
                    print(String(data: res, encoding: .utf8) ?? "Nothing")
                }
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
        
        if self.buttonChangeTracker != nil {
            for c in self.buttonChangeTracker! {
                switch c.value {
                case self.disableUpdateCheck:
                    self.changedConfigs?.disableUpdateCheck = Bool(exactly: NSNumber(value: c.value.state.rawValue))
                case self.skipCheckBundleCached:
                    self.changedConfigs?.skipCheckBundleExtracted = (self.skipCheckBundleCached?.state == .on)
                case self.skipCheckOCCached:
                    self.changedConfigs?.skipCheckOcCached = (self.skipCheckOCCached?.state == .on)
                case self.skipCheckPodmanCached:
                    self.changedConfigs?.skipCheckPodmanCached = (self.skipCheckPodmanCached?.state == .on)
                case self.skipCheckHyperkitDriverCached:
                    self.changedConfigs?.skipCheckHyperkitDriver = (self.skipCheckHyperkitDriverCached?.state == .on)
                case self.skipCheckRAMSize:
                    self.changedConfigs?.skipCheckRam = (self.skipCheckRAMSize?.state == .on)
                case self.skipCheckHostsFilePermission:
                    self.changedConfigs?.skipCheckHostsFilePermissions = (self.skipCheckHostsFilePermission?.state == .on)
                case self.skipCheckRunningAsRoot:
                    self.changedConfigs?.skipCheckRootUser = (self.skipCheckRunningAsRoot?.state == .on)
                case self.skipCheckAdminHelperCached:
                    self.changedConfigs?.skipCheckGoodhostsCached = (self.skipCheckAdminHelperCached?.state == .on)
                default:
                    print("should not reach here")
                }
            }
        }
        
        if self.textFiedlChangeTracker != nil {
            for c in self.textFiedlChangeTracker! {
                switch c.value.identifier {
                case self.nameservers?.identifier:
                    if c.value.stringValue == "" {
                        needsUnset = true
                        configsNeedingUnset.append(contentsOf: ["nameserver"])
                    } else {
                        self.changedConfigs?.nameserver = c.value.stringValue
                    }
                default:
                    print("txtfield: should not reach here")
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
                do {
                    let result = try JSONDecoder().decode(configResult.self, from: res)
                    if !result.Error.isEmpty {
                        let alert = NSAlert()
                        alert.informativeText = "\(result.Error)"
                        alert.messageText = "Error"
                        alert.alertStyle = .warning
                        alert.runModal()
                    }
                } catch let jsonErr {
                    print(jsonErr)
                }
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
    
    // Preflight checkbox button handlers
    @IBAction func checkBundleExtractedClicked(_ sender: Any) {
        trackButtonClicks(sender)
    }
    @IBAction func checkHyperkitDriverClicked(_ sender: Any) {
        trackButtonClicks(sender)
    }
    @IBAction func checkPodmanCachedClicked(_ sender: Any) {
        trackButtonClicks(sender)
    }
    @IBAction func checkResolverPermissionClicked(_ sender: Any) {
        trackButtonClicks(sender)
    }
    @IBAction func checkRunningAsRootClicked(_ sender: Any) {
        trackButtonClicks(sender)
    }
    @IBAction func checkRAMSizeClicked(_ sender: Any) {
        trackButtonClicks(sender)
    }
    @IBAction func checkHostsFilePermissionsClicked(_ sender: Any) {
        trackButtonClicks(sender)
    }
    @IBAction func checkOCCachedClicked(_ sender: Any) {
        trackButtonClicks(sender)
    }
    @IBAction func checkAdminHelperCached(_ sender: Any) {
        trackButtonClicks(sender)
    }
    
    @IBAction func useProxyClicked(_ sender: Any) {
        self.httpProxy?.isEnabled = self.useProxy.state == .on ? true : false
        self.httpsProxy?.isEnabled = self.useProxy.state == .on ? true : false
        self.proxyCaFile?.isEnabled = self.useProxy.state == .on ? true : false
        self.noProxy?.isEnabled = self.useProxy.state == .on ? true : false
        self.proxyCAFileButton?.isEnabled = self.useProxy.state == .on ? true : false
    }
}

extension ConfigViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object else { print("False notification, nothing changed"); return }
        print((textField as! NSTextField).stringValue)
        self.textFiedlChangeTracker?[textField as! NSTextField] = textField as? NSTextField
    }
}
