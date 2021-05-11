//
//  Handlers.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 22/11/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//
import Cocoa

struct StopResult: Decodable {
    let Name: String?
    let Success: Bool
    let State: Int?
    let Error: String?
}

struct StartResult: Decodable {
    let Name: String?
    let Status: String?
    let Error: String?
    let ClusterConfig: ClusterConfigType?
    let KubeletStarted: Bool?
}

struct DeleteResult: Decodable {
    let Name: String?
    let Success: Bool
    let Error: String?
}
struct ProxyConfigType: Decodable {
    let HTTPProxy: String
    let HTTPSProxy: String
    let ProxyCACert: String
}

struct ClusterConfigType: Decodable {
    let ClusterCACert: String
    let KubeConfig: String
    let KubeAdminPass: String
    let WebConsoleURL: String
    let ClusterAPI: String
    let ProxyConfig: ProxyConfigType?
}

struct Request: Encodable {
    let command: String
    let args: [String: String]?
}

struct ConfigGetRequest: Encodable {
    let command: String
    let args: PropertiesArray
}

struct PropertiesArray: Encodable {
    let properties: [String]
}

struct ConfigGetResult: Decodable {
    let Error: String?
    let Configs: [String: String]
}

struct WebConsoleResult: Decodable {
    let ClusterConfig: ClusterConfigType
    let Success: Bool
    let Error: String?
}

struct VersionResult: Decodable {
    let CrcVersion: String
    let CommitSha: String
    let OpenshiftVersion: String
    let Success: Bool
}

struct GetconfigResult: Decodable {
    let Error: String?
    let Configs: CrcConfigs
}

struct CrcConfigs: Codable {
    var bundle: String?
    var cpus: Int?
    var disableUpdateCheck: Bool?
    var enableExperimentalFeatures: Bool?
    var httpProxy: String?
    var httpsProxy: String?
    var memory: Int?
    var diskSize: Int?
    var nameserver: String?
    var noProxy: String?
    var proxyCaFile: String?
    var pullSecretFile: String?
    var networkMode: String?
    var consentTelemetry: String?
    var autostartTray: Bool?
    var skipCheckBundleExtracted: Bool?
    var skipCheckHostsFilePermissions: Bool?
    var skipCheckHyperkitDriver: Bool?
    var skipCheckHyperkitInstalled: Bool?
    var skipCheckPodmanCached: Bool?
    var skipCheckRam: Bool?
    var skipCheckResolverFilePermissions: Bool?
    var skipCheckRootUser: Bool?
    var skipCheckOcCached: Bool?
    var skipCheckGoodhostsCached: Bool?

    enum CodingKeys: String, CodingKey {
        case bundle
        case cpus
        case memory
        case nameserver

        case disableUpdateCheck = "disable-update-check"
        case enableExperimentalFeatures = "enable-experimental-features"
        case httpProxy = "http-proxy"
        case httpsProxy = "https-proxy"
        case noProxy = "no-proxy"
        case proxyCaFile = "proxy-ca-file"
        case pullSecretFile = "pull-secret-file"
        case diskSize = "disk-size"
        case networkMode = "network-mode"
        case consentTelemetry = "consent-telemetry"
        case autostartTray = "autostart-tray"
        case skipCheckBundleExtracted = "skip-check-bundle-extracted"
        case skipCheckHostsFilePermissions = "skip-check-hosts-file-permissions"
        case skipCheckHyperkitDriver = "skip-check-hyperkit-driver"
        case skipCheckHyperkitInstalled = "skip-check-hyperkit-installed"
        case skipCheckPodmanCached = "skip-check-podman-cached"
        case skipCheckRam = "skip-check-ram"
        case skipCheckResolverFilePermissions = "skip-check-resolver-file-permissions"
        case skipCheckRootUser = "skip-check-root-user"
        case skipCheckOcCached = "skip-check-oc-cached"
        case skipCheckGoodhostsCached = "skip-check-goodhosts-cached"
    }
}

enum DaemonError: Error {
    case io // input/output error
    case noResponse
    case badResponse
    case undefined
}

struct LogsResult: Decodable {
    let Success: Bool
    let Messages: [String]
}

func HandleStop() {
    SendTelemetry(Actions.ClickStop)

    var data: Data
    do {
        data = try SendCommandToDaemon(command: Request(command: "stop", args: nil))
    } catch let error {
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            appDelegate?.pollStatus()
            showAlertFailedAndCheckLogs(message: "Failed deleting the CRC cluster", informativeMsg: "Make sure the CRC daemon is running, or check the logs to get more information. Error: \(error)")
        }
        return
    }
    do {
        let stopResult = try JSONDecoder().decode(StopResult.self, from: data)
        if stopResult.Success {
            DispatchQueue.main.async {
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.pollStatus()
                displayNotification(title: "Successfully Stopped Cluster", body: "The OpenShift Cluster was successfully stopped")
            }
        }
        if stopResult.Error != "" {
            DispatchQueue.main.async {
                showAlertFailedAndCheckLogs(message: "Failed to stop OpenShift cluster", informativeMsg: "\(stopResult.Error)")
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.pollStatus()
            }
        }
    } catch let jsonErr {
        displayNotification(title: "Cannot parse daemon answer", body: jsonErr.localizedDescription)
    }
}

func HandleStart(pullSecretPath: String) {
    DispatchQueue.main.async {
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        appDelegate?.initializeMenus(status: "Starting")
    }
    var response: Data
    do {
        if pullSecretPath == "" {
            response = try SendCommandToDaemon(command: Request(command: "start", args: nil))
        } else {
            response = try SendCommandToDaemon(command: Request(command: "start", args: ["pullSecretFile": pullSecretPath]))
        }
        displayNotification(title: "Starting Cluster", body: "Starting OpenShift Cluster, this could take a few minutes..")
    } catch let error {
        // show notification about the failure
        // Adjust the menus
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            appDelegate?.pollStatus()
            showAlertFailedAndCheckLogs(message: "Failed to start OpenShift cluster", informativeMsg: "CodeReady Containers failed to start the OpenShift cluster, ensure the CRC daemon is running or check the logs to find more information. Error: \(error)")
        }
        return
    }
    do {
        let startResult = try JSONDecoder().decode(StartResult.self, from: response)
        if startResult.Status == "Running" {
            DispatchQueue.main.async {
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.pollStatus()
                displayNotification(title: "Successfully started Cluster", body: "OpenShift Cluster is running")
            }
        }
        if let error = startResult.Error {
            DispatchQueue.main.async {
                let errMsg = error.split(separator: "\n")
                showAlertFailedAndCheckLogs(message: "Failed to start OpenShift cluster", informativeMsg: "\(errMsg[0])")
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.pollStatus()
            }
        }
    } catch let jsonErr {
        displayNotification(title: "Cannot parse daemon answer", body: jsonErr.localizedDescription)
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

    SendTelemetry(Actions.ClickDelete)

    do {
        let data = try SendCommandToDaemon(command: Request(command: "delete", args: nil))
        let deleteResult = try JSONDecoder().decode(DeleteResult.self, from: data)
        if deleteResult.Success {
            // send notification that delete succeeded
            // rearrage menus
            DispatchQueue.main.async {
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.pollStatus()
                displayNotification(title: "Cluster Deleted", body: "The OpenShift Cluster is successfully deleted")
            }
        }
        if deleteResult.Error != "" {
            DispatchQueue.main.async {
                showAlertFailedAndCheckLogs(message: "Failed to delete OpenShift cluster", informativeMsg: "\(deleteResult.Error)")
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                appDelegate?.pollStatus()
            }
        }
    } catch let error {
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            appDelegate?.pollStatus()
            showAlertFailedAndCheckLogs(message: "Failed to delete cluster", informativeMsg: "CRC failed to delete the OCP cluster, make sure the CRC daemom is running or check the logs to find more information. Error: \(error)")
        }
    }
}

func HandleWebConsoleURL() {
    do {
        let data = try SendCommandToDaemon(command: Request(command: "webconsoleurl", args: nil))
        let webConsoleResult = try JSONDecoder().decode(WebConsoleResult.self, from: data)
        if webConsoleResult.Success {
            // open the webconsoleURL
            NSWorkspace.shared.open(URL(string: webConsoleResult.ClusterConfig.WebConsoleURL)!)
        }
    } catch let error {
        showAlertFailedAndCheckLogs(message: "Failed to launch web console",
                                    informativeMsg: "Ensure the CRC daemon is running and a CRC cluster is running, for more information please check the logs. Error: \(error)")
    }
}

func HandleLoginCommandForKubeadmin() {
    do {
        let data = try SendCommandToDaemon(command: Request(command: "webconsoleurl", args: nil))
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
                displayNotification(title: "OC Login with kubeadmin", body: "OC Login command copied to clipboard, go ahead and login to your cluster")
            }
        }
    } catch let error {
        showAlertFailedAndCheckLogs(message: "Failed to get login command", informativeMsg: "Ensure the CRC daemon is running and a CRC cluster is running, for more information please check the logs. Error: \(error)")
    }
}

func HandleLoginCommandForDeveloper() {
    do {
        let data = try SendCommandToDaemon(command: Request(command: "webconsoleurl", args: nil))
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
                displayNotification(title: "OC Login with developer", body: "OC Login command copied to clipboard, go ahead and login to your cluster")
            }
        }
    } catch let error {
        showAlertFailedAndCheckLogs(message: "Failed to get login command", informativeMsg: "Ensure the CRC daemon is running and a CRC cluster is running, for more information please check the logs. Error: \(error)")
    }
}

func FetchVersionInfoFromDaemon() -> (String, String) {
    do {
        let data = try SendCommandToDaemon(command: Request(command: "version", args: nil))
        let versionResult = try JSONDecoder().decode(VersionResult.self, from: data)
        if versionResult.Success {
            let crcVersion = "\(versionResult.CrcVersion)+\(versionResult.CommitSha)"
            return (crcVersion, versionResult.OpenshiftVersion)
        }
    } catch let error {
        showAlertFailedAndCheckLogs(message: "Failed to fetch version", informativeMsg: "Ensure the CRC daemon is running, for more information please check the logs. Error: \(error)")
        return ("", "")
    }
    return ("", "")
}

func GetConfigFromDaemon(properties: [String]) throws -> [String: String] {
    let data = try SendCommandToDaemon(command: ConfigGetRequest(command: "getconfig", args: PropertiesArray(properties: properties)))
    let configGetResult = try JSONDecoder().decode(ConfigGetResult.self, from: data)
    return configGetResult.Configs
}

func GetAllConfigFromDaemon() throws -> CrcConfigs {
    let data = try SendCommandToDaemon(command: Request(command: "getconfig", args: nil))
    let decoder = JSONDecoder()
    let configResult = try decoder.decode(GetconfigResult.self, from: data)
    if configResult.Error == "" {
        return configResult.Configs
    }
    throw DaemonError.badResponse
}

enum Actions: String {
    case Start = "start application"
    case OpenMenu = "open menu"
    case ClickStart = "click start"
    case EnterPullSecret = "enter pull secret"
    case ClickStop = "click stop"
    case ClickDelete = "click delete"
    case ClickOpenConsole = "click open web console"
    case OpenPreferences = "open preferences"
    case ApplyPreferences = "apply new preferences"
    case OpenStatus = "open status"
    case OpenAbout = "open about"
    case CopyOCLoginForDeveloper = "copy oc login for developer"
    case CopyOCLoginForAdmin = "copy oc login for admin"
    case Quit = "quit application"
    case ChangeKubernetesContext = "change Kubernetes context"
}

func SendTelemetry(_ action: Actions) {
    _ = try? SendCommandToDaemon(command: Request(command: "telemetry", args: ["action": action.rawValue, "source": "tray"]))
}
