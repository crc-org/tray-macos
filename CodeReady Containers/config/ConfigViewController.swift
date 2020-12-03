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
    @IBOutlet weak var checkBundleCached: NSPopUpButton!
    @IBOutlet weak var checkHyperkitDriverCached: NSPopUpButton!
    @IBOutlet weak var checkPodmanCached: NSPopUpButton!
    @IBOutlet weak var checkResolverFilePermission: NSPopUpButton!
    @IBOutlet weak var checkRunningAsRoot: NSPopUpButton!
    @IBOutlet weak var checkRamSize: NSPopUpButton!
    @IBOutlet weak var checkHostsFilePermissions: NSPopUpButton!
    @IBOutlet weak var disableUpdateCheck: NSButton!
    @IBOutlet weak var nameservers: NSTextField!
    @IBOutlet weak var checkOcCached: NSPopUpButton!
    @IBOutlet weak var checkGoodhostsCached: NSPopUpButton!
    
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
        let viewsAndConfigs: [(NSPopUpButton?, Bool?, Bool?)] = [
            (self.checkBundleCached, configs?.skipCheckBundleCached, configs?.warnCheckBundleCached),
            (self.checkHyperkitDriverCached, configs?.skipCheckHyperkitDriver, configs?.warnCheckHyperkitDriver),
            (self.checkPodmanCached, configs?.skipCheckPodmanCached, configs?.warnCheckPodmanCached),
            (self.checkResolverFilePermission, configs?.skipCheckResolverFilePermissions, configs?.warnCheckResolverFilePermissions),
            (self.checkRunningAsRoot, configs?.skipCheckRootUser, configs?.warnCheckRootUser),
            (self.checkRamSize, configs?.skipCheckRam, configs?.warnCheckRam),
            (self.checkHostsFilePermissions, configs?.skipCheckHostsFilePermissions, configs?.warnCheckHostsFilePermissions),
            (self.checkGoodhostsCached, configs?.skipCheckGoodhostsCached, configs?.warnCheckGoodhostsCached),
            (self.checkOcCached, configs?.skipCheckOcCached, configs?.warnCheckOcCached)
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
        for c in preflightChecksInitialConfig {
            switch c.key {
            case self.checkResolverFilePermission:
                switch self.checkResolverFilePermission.indexOfSelectedItem {
                case 0:
                    self.needsUnset = true
                    configsNeedingUnset.append(contentsOf: ["skip-check-resolver-file-permissions", "warn-check-resolver-file-permissions"])
                case 1:
                    self.changedConfigs?.skipCheckResolverFilePermissions = true
                    self.changedConfigs?.warnCheckResolverFilePermissions = false
                case 2:
                    self.changedConfigs?.warnCheckResolverFilePermissions = true
                    self.changedConfigs?.skipCheckResolverFilePermissions = false
                default:
                    print("should not reach here")
                }
            case self.checkBundleCached:
                switch self.checkBundleCached?.indexOfSelectedItem {
                case 0:
                    self.needsUnset = true
                    configsNeedingUnset.append(contentsOf: ["skip-check-bundle-cached", "warn-check-bundle-cached"])
                case 1:
                    self.changedConfigs?.skipCheckBundleCached = true
                    self.changedConfigs?.warnCheckBundleCached = false
                case 2:
                    self.changedConfigs?.warnCheckBundleCached = true
                    self.changedConfigs?.skipCheckBundleCached = false
                default:
                    print("should not reach here")
                }
            case self.checkHyperkitDriverCached:
                switch self.checkHyperkitDriverCached?.indexOfSelectedItem {
                case 0:
                    self.needsUnset = true
                    configsNeedingUnset.append(contentsOf: ["skip-check-hyperkit-driver", "warn-check-hyperkit-driver"])
                case 1:
                    self.changedConfigs?.skipCheckHyperkitDriver = true
                    self.changedConfigs?.warnCheckHyperkitDriver = false
                case 2:
                    self.changedConfigs?.warnCheckHyperkitDriver = true
                    self.changedConfigs?.skipCheckHyperkitDriver = false
                default:
                    print("should not reach here")
                }
            case self.checkPodmanCached:
                switch self.checkPodmanCached?.indexOfSelectedItem {
                case 0:
                    self.needsUnset = true
                    configsNeedingUnset.append(contentsOf: ["skip-check-podman-cached", "warn-check-podman-cached"])
                case 1:
                    self.changedConfigs?.skipCheckPodmanCached = true
                    self.changedConfigs?.warnCheckPodmanCached = false
                case 2:
                    self.changedConfigs?.warnCheckPodmanCached = true
                    self.changedConfigs?.skipCheckPodmanCached = false
                default:
                    print("should not reach here")
                }
            case self.checkRunningAsRoot:
                switch self.checkRunningAsRoot.indexOfSelectedItem {
                case 0:
                    self.needsUnset = true
                    configsNeedingUnset.append(contentsOf: ["skip-check-root-user", "warn-check-root-user"])
                case 1:
                    self.changedConfigs?.skipCheckRootUser = true
                    self.changedConfigs?.warnCheckRootUser = false
                case 2:
                    self.changedConfigs?.warnCheckRootUser = true
                    self.changedConfigs?.skipCheckRootUser = false
                default:
                    print("should not reach here")
                }
            case self.checkRamSize:
                switch self.checkRamSize.indexOfSelectedItem {
                case 0:
                    self.needsUnset = true
                    configsNeedingUnset.append(contentsOf: ["skip-check-ram", "warn-check-ram"])
                case 1:
                    self.changedConfigs?.skipCheckRam = true
                    self.changedConfigs?.warnCheckRam = false
                case 2:
                    self.changedConfigs?.warnCheckRam = true
                    self.changedConfigs?.skipCheckRam = false
                default:
                    print("should not reach here")
                }
            case self.checkHostsFilePermissions:
                switch self.checkHostsFilePermissions.indexOfSelectedItem {
                case 0:
                    self.needsUnset = true
                    configsNeedingUnset.append(contentsOf: ["skip-check-hosts-file-permissions", "warn-check-hosts-file-permissions"])
                case 1:
                    self.changedConfigs?.skipCheckHostsFilePermissions = true
                    self.changedConfigs?.warnCheckHostsFilePermissions = false
                case 2:
                    self.changedConfigs?.warnCheckHostsFilePermissions = true
                    self.changedConfigs?.skipCheckHostsFilePermissions = false
                default:
                    print("should not reach here")
                }
            case self.checkOcCached:
                switch self.checkOcCached.indexOfSelectedItem {
                case 0:
                    self.needsUnset = true
                    configsNeedingUnset.append(contentsOf: ["skip-check-oc-cached", "warn-check-oc-cached"])
                case 1:
                    self.changedConfigs?.skipCheckOcCached = true
                    self.changedConfigs?.warnCheckOcCached = false
                case 2:
                    self.changedConfigs?.warnCheckOcCached = true
                    self.changedConfigs?.skipCheckOcCached = false
                default:
                    print("should not reach here")
                }
            case self.checkGoodhostsCached:
                switch self.checkGoodhostsCached.indexOfSelectedItem {
                case 0:
                    self.needsUnset = true
                    configsNeedingUnset.append(contentsOf: ["skip-check-goodhosts-cached", "warn-check-goodhosts-cached"])
                case 1:
                    self.changedConfigs?.skipCheckGoodhostsCached = true
                    self.changedConfigs?.warnCheckGoodhostsCached = false
                case 2:
                    self.changedConfigs?.warnCheckGoodhostsCached = true
                    self.changedConfigs?.skipCheckGoodhostsCached = false
                default:
                    print("should not reach here")
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
