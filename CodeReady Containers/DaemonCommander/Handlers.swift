//
//  Handlers.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 22/11/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//
import Cocoa

struct StopResult: Decodable {
    let Name: String
    let Success: Bool
    let State: Int
    let Error: String
}

struct StartResult: Decodable {
    let Name: String
    let Status: String
    let Error: String
    let ClusterConfig: ClusterConfigType
    let KubeletStarted: Bool
}

struct DeleteResult: Decodable {
    let Name: String
    let Success: Bool
    let Error: String
}

struct ClusterConfigType: Decodable {
    let KubeConfig: String
    let KubeAdminPass: String
    let WebConsoleURL: String
    let ClusterAPI: String
}

struct Request: Encodable {
    let command: String
    let args: Dictionary<String, String>?
}

struct WebConsoleResult: Decodable {
    let ClusterConfig: ClusterConfigType
    let State: Int
    let Success: Bool
    let Error: String
}

struct VersionResult: Decodable {
    let CrcVersion: String
    let CommitSha: String
    let OpenshiftVersion: String
    let Success: Bool
}

func HandleStop() {
    let r = SendCommandToDaemon(command: Request(command: "stop", args: nil))
    guard let data = r else { return }
    if String(bytes: data, encoding: .utf8) == "Failed" {
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            appDelegate?.updateMenuStates(state: MenuStates(startMenuEnabled: true,
                                                            stopMenuEnabled: false,
                                                            deleteMenuEnabled: true,
                                                            webconsoleMenuEnabled: true,
                                                            ocLoginForDeveloperEnabled: true,
                                                            ocLoginForAdminEnabled: true,
                                                            copyOcLoginCommand: true)
            )
            
            showAlertFailedAndCheckLogs(message: "Failed deleting the CRC cluster", informativeMsg: "Make sure the CRC daemon is running, or check the logs to get more information")
        }
        return
    }
    do {
        let stopResult = try JSONDecoder().decode(StopResult.self, from: r!)
        if stopResult.Success {
            DispatchQueue.main.async {
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.updateMenuStates(state: MenuStates(startMenuEnabled: true,
                                                                stopMenuEnabled: false,
                                                                deleteMenuEnabled: true,
                                                                webconsoleMenuEnabled: false,
                                                                ocLoginForDeveloperEnabled: false,
                                                                ocLoginForAdminEnabled: false,
                                                                copyOcLoginCommand: false)
                )
                appDelegate?.updateStatusMenuItem(status: "Stopped")
                
                displayNotification(title: "Successfully Stopped Cluster", body: "The CRC Cluster was successfully stopped")
            }
        }
        if stopResult.Error != "" {
            DispatchQueue.main.async {
                showAlertFailedAndCheckLogs(message: "Failed to stop OpenShift cluster", informativeMsg: "\(stopResult.Error)")
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.showClusterStatusUnknownOnStatusMenuItem()
                appDelegate?.updateMenuStates(state: MenuStates(startMenuEnabled: false,
                                                                stopMenuEnabled: true,
                                                                deleteMenuEnabled: true,
                                                                webconsoleMenuEnabled: true,
                                                                ocLoginForDeveloperEnabled: true,
                                                                ocLoginForAdminEnabled: true,
                                                                copyOcLoginCommand: true)
                )
            }
        }
    } catch let jsonErr {
        print(jsonErr.localizedDescription)
    }
    
}

func HandleStart() {
    DispatchQueue.main.async {
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        appDelegate?.showClusterStartingMessageOnStatusMenuItem()
    }
    let r = SendCommandToDaemon(command: Request(command: "start", args: nil))
    guard let data = r else { return }
    if String(bytes: data, encoding: .utf8) == "Failed" {
        // show notification about the failure
        // Adjust the menus
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            appDelegate?.updateMenuStates(state: MenuStates(startMenuEnabled: true,
                                                            stopMenuEnabled: false,
                                                            deleteMenuEnabled: true,
                                                            webconsoleMenuEnabled: false,
                                                            ocLoginForDeveloperEnabled: false,
                                                            ocLoginForAdminEnabled: false,
                                                            copyOcLoginCommand: false))
            
            showAlertFailedAndCheckLogs(message: "Failed to start OpenShift cluster", informativeMsg: "CodeReady Containers failed to start the OpenShift cluster, ensure the CRC daemon is running or check the logs to find more information")
        }
    } else {
        displayNotification(title: "CodeReady Containers", body: "Starting OpenShift Cluster, this could take a few minutes..")
    }
    do {
        let startResult = try JSONDecoder().decode(StartResult.self, from: data)
        if startResult.Status == "Running" {
            DispatchQueue.main.async {
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.showClusterStartingMessageOnStatusMenuItem()
                appDelegate?.updateMenuStates(state: MenuStates(startMenuEnabled: false, stopMenuEnabled: true, deleteMenuEnabled: true, webconsoleMenuEnabled: false, ocLoginForDeveloperEnabled: false, ocLoginForAdminEnabled: false, copyOcLoginCommand: false))
            }
            // if vm is running but kubelet not yet started
            if !startResult.KubeletStarted {
                DispatchQueue.main.async {
                    let appDelegate = NSApplication.shared.delegate as? AppDelegate
                    appDelegate?.showClusterStatusUnknownOnStatusMenuItem()
                    displayNotification(title: "CodeReady Containers", body: "CodeReady Containers OpenShift Cluster is taking longer to start")
                }
            } else {
                DispatchQueue.main.async {
                    let appDelegate = NSApplication.shared.delegate as? AppDelegate
                    appDelegate?.updateStatusMenuItem(status: startResult.Status)
                    appDelegate?.updateMenuStates(state: MenuStates(startMenuEnabled: false, stopMenuEnabled: true, deleteMenuEnabled: true, webconsoleMenuEnabled: true, ocLoginForDeveloperEnabled: true, ocLoginForAdminEnabled: true, copyOcLoginCommand: true))
                    
                    displayNotification(title: "CodeReady Containers", body: "OpenShift Cluster is running")
                }
            }
        }
        if startResult.Error != "" {
            DispatchQueue.main.async {
                var errMsg = startResult.Error.split(separator: "\n")
                showAlertFailedAndCheckLogs(message: "Failed to start OpenShift cluster", informativeMsg: "\(errMsg[0])")
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.showClusterStatusUnknownOnStatusMenuItem()
                appDelegate?.updateMenuStates(state: MenuStates(startMenuEnabled: true,
                                                                stopMenuEnabled: false,
                                                                deleteMenuEnabled: true,
                                                                webconsoleMenuEnabled: false,
                                                                ocLoginForDeveloperEnabled: false,
                                                                ocLoginForAdminEnabled: false,
                                                                copyOcLoginCommand: false)
                )
            }
        }
    } catch let jsonErr {
        print(jsonErr.localizedDescription)
    }
}

func HandleDelete() {
    // prompt for confirmation and bail if No
    var yes: Bool = false
    DispatchQueue.main.sync {
        yes = promptYesOrNo(message: "Deleting CodeReady Containers Cluster", informativeMsg: "Are you sure you want to delete the crc instance")
    }
    if !yes {
        return
    }
    let r = SendCommandToDaemon(command: Request(command: "delete", args: nil))
    guard let data = r else { return }
    if String(bytes: data, encoding: .utf8) == "Failed" {
        // handle failure to delete
        // send alert that delete failed
        // rearrange menu states
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            appDelegate?.updateMenuStates(state: MenuStates(startMenuEnabled: true, stopMenuEnabled: false, deleteMenuEnabled: true, webconsoleMenuEnabled: false, ocLoginForDeveloperEnabled: false, ocLoginForAdminEnabled: false, copyOcLoginCommand: false))
            
            showAlertFailedAndCheckLogs(message: "Failed to delete cluster", informativeMsg: "CRC failed to delete the OCP cluster, make sure the CRC daemom is running or check the logs to find more information")
        }
    }
    do {
        let deleteResult = try JSONDecoder().decode(DeleteResult.self, from: data)
        if deleteResult.Success {
            // send notification that delete succeeded
            // rearrage menus
            DispatchQueue.main.async {
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.updateMenuStates(state: MenuStates(startMenuEnabled: true, stopMenuEnabled: false, deleteMenuEnabled: false, webconsoleMenuEnabled: false, ocLoginForDeveloperEnabled: false, ocLoginForAdminEnabled: false, copyOcLoginCommand: false))
                appDelegate?.showClusterStatusUnknownOnStatusMenuItem()
                displayNotification(title: "Cluster Deleted", body: "The CRC Cluster is successfully deleted")
            }
        }
        if deleteResult.Error != "" {
            DispatchQueue.main.async {
                showAlertFailedAndCheckLogs(message: "Failed to delete OpenShift cluster", informativeMsg: "\(deleteResult.Error)")
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.showClusterStatusUnknownOnStatusMenuItem()
            }
        }
    } catch let jsonErr {
        print(jsonErr.localizedDescription)
    }
}

func HandleWebConsoleURL() {
    let r = SendCommandToDaemon(command: Request(command: "webconsoleurl", args: nil))
    guard let data = r else { return }
    if String(bytes: data, encoding: .utf8) == "Failed" {
        // Alert show error
        DispatchQueue.main.async {
            showAlertFailedAndCheckLogs(message: "Failed to launch web console", informativeMsg: "Ensure the CRC daemon is running and a CRC cluster is running, for more information please check the logs")
        }        
    }
    do {
        let webConsoleResult = try JSONDecoder().decode(WebConsoleResult.self, from: data)
        if webConsoleResult.Success {
            // open the webconsoleURL
            NSWorkspace.shared.open(URL(string: webConsoleResult.ClusterConfig.WebConsoleURL)!)
        }
    } catch let jsonErr {
        print(jsonErr.localizedDescription)
    }
}

func HandleLoginCommandForKubeadmin() {
    let r = SendCommandToDaemon(command: Request(command: "webconsoleurl", args: nil))
    guard let data = r else { return }
    if String(bytes: data, encoding: .utf8) == "Failed" {
        // Alert show error
        DispatchQueue.main.async {
            showAlertFailedAndCheckLogs(message: "Failed to get login command", informativeMsg: "Ensure the CRC daemon is running and a CRC cluster is running, for more information please check the logs")
        }
    }
    do {
        let webConsoleResult = try JSONDecoder().decode(WebConsoleResult.self, from: data)
        if webConsoleResult.Success {
            // form the login command, put in clipboard and show notification
            let apiURL = webConsoleResult.ClusterConfig.ClusterAPI
            let kubeadminPass = webConsoleResult.ClusterConfig.KubeAdminPass
            
            let loginCommand = "oc login -u kubeadmin -p \(kubeadminPass) \(apiURL)"
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteboard.setString(loginCommand, forType: NSPasteboard.PasteboardType.string)
            
            // show notification on main thread
            DispatchQueue.main.async {
                displayNotification(title: "OC Login with kubeadmin", body: "OC Login command copied to clipboard, go ahead an login to your cluster")
            }
        }
    } catch let jsonErr {
        print(jsonErr.localizedDescription)
    }
}

func HandleLoginCommandForDeveloper() {
    let r = SendCommandToDaemon(command: Request(command: "webconsoleurl", args: nil))
    guard let data = r else { return }
    if String(bytes: data, encoding: .utf8) == "Failed" {
        // Alert show error
        DispatchQueue.main.async {
            showAlertFailedAndCheckLogs(message: "Failed to get login command", informativeMsg: "Ensure the CRC daemon is running and a CRC cluster is running, for more information please check the logs")
        }
    }
    do {
        let webConsoleResult = try JSONDecoder().decode(WebConsoleResult.self, from: data)
        if webConsoleResult.Success {
            // form the login command, put in clipboard and show notification
            let apiURL = webConsoleResult.ClusterConfig.ClusterAPI
            
            let loginCommand = "oc login -u developer -p developer \(apiURL)"
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteboard.setString(loginCommand, forType: NSPasteboard.PasteboardType.string)
            
            // show notification on main thread
            DispatchQueue.main.async {
                displayNotification(title: "OC Login with developer", body: "OC Login command copied to clipboard, go ahead an login to your cluster")
            }
        }
    } catch let jsonErr {
        print(jsonErr.localizedDescription)
    }
}

func FetchVersionInfoFromDaemon() -> (String, String) {
    let r = SendCommandToDaemon(command: Request(command: "version", args: nil))
    guard let data = r else { return ("", "") }
    if String(bytes: data, encoding: .utf8) == "Failed" {
        // Alert show error
        DispatchQueue.main.async {
            showAlertFailedAndCheckLogs(message: "Failed to fetch version", informativeMsg: "Ensure the CRC daemon is running, for more information please check the logs")
        }
        return ("","")
    }
    do {
        let versionResult = try JSONDecoder().decode(VersionResult.self, from: data)
        if versionResult.Success {
            let crcVersion = "\(versionResult.CrcVersion)+\(versionResult.CommitSha)"
            return (crcVersion, versionResult.OpenshiftVersion)
        }
    } catch let jsonErr {
        print(jsonErr.localizedDescription)
    }
    return ("","")
}
