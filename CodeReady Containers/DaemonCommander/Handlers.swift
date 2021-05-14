//
//  Handlers.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 22/11/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//
import Cocoa
import NIOHTTP1

struct StartResult: Decodable {
    let Name: String?
    let Status: String?
    let ClusterConfig: ClusterConfigType?
    let KubeletStarted: Bool?
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
    let Configs: [String: String]
}

struct WebConsoleResult: Decodable {
    let ClusterConfig: ClusterConfigType
}

struct VersionResult: Decodable {
    let CrcVersion: String
    let CommitSha: String
    let OpenshiftVersion: String
}

struct GetconfigResult: Decodable {
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
    case badResponse
    case internalServerError(message: String)
}

extension DaemonError: CustomStringConvertible {
    public var description: String {
      switch self {
      case .io:
          return "input/output error"
      case .badResponse:
          return "bad response from the server"
      case .internalServerError(let message):
        return message
    }
  }
}

struct LogsResult: Decodable {
    let Messages: [String]
}

struct ConfigsetRequest: Encodable {
    var command: String
    var args: Configset
}

struct ConfigunsetRequest: Encodable {
    var command: String
    var args: Configunset
}

struct Configset: Encodable {
    var properties: CrcConfigs?
}

struct Configunset: Encodable {
    var properties: [String]
}

func HandleStop() {
    SendTelemetry(Actions.ClickStop)

    do {
        _ = try SendCommandToDaemon(HTTPMethod.GET, "/api/stop")
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            appDelegate?.pollStatus()
            displayNotification(title: "Successfully Stopped Cluster", body: "The OpenShift Cluster was successfully stopped")
        }
    } catch let error {
        DispatchQueue.main.async {
            showAlertFailedAndCheckLogs(message: "Failed to stop OpenShift cluster", informativeMsg: "\(error)")
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            appDelegate?.pollStatus()
        }
    }
}

func HandleStart() {
    DispatchQueue.main.async {
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        appDelegate?.initializeMenus(status: "Starting")
    }
    do {
        displayNotification(title: "Starting Cluster", body: "Starting OpenShift Cluster, this could take a few minutes..")
        _ = try SendCommandToDaemon(HTTPMethod.GET, "/api/start")
        displayNotification(title: "Successfully started cluster", body: "OpenShift cluster is running")
    } catch let error {
        showAlertFailedAndCheckLogs(message: "Failed to start OpenShift cluster", informativeMsg: "\(error)")
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
        _ = try SendCommandToDaemon(HTTPMethod.GET, "/api/delete")
        // send notification that delete succeeded
        // rearrage menus
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            appDelegate?.pollStatus()
            displayNotification(title: "Cluster Deleted", body: "The OpenShift Cluster is successfully deleted")
        }
    } catch let error {
        DispatchQueue.main.async {
            showAlertFailedAndCheckLogs(message: "Failed to delete OpenShift cluster", informativeMsg: "\(error)")
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            appDelegate?.pollStatus()
        }
    }
}

func HandleWebConsoleURL() {
    do {
        let data = try SendCommandToDaemon(HTTPMethod.GET, "/api/webconsoleurl")
        let webConsoleResult = try JSONDecoder().decode(WebConsoleResult.self, from: data)
        // open the webconsoleURL
        NSWorkspace.shared.open(URL(string: webConsoleResult.ClusterConfig.WebConsoleURL)!)
    } catch let error {
        showAlertFailedAndCheckLogs(message: "Failed to launch web console",
                                    informativeMsg: "Ensure the CRC daemon is running and a CRC cluster is running, for more information please check the logs. Error: \(error)")
    }
}

func HandleLoginCommandForKubeadmin() {
    do {
        let data = try SendCommandToDaemon(HTTPMethod.GET, "/api/webconsoleurl")
        let webConsoleResult = try JSONDecoder().decode(WebConsoleResult.self, from: data)

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
    } catch let error {
        showAlertFailedAndCheckLogs(message: "Failed to get login command", informativeMsg: "Ensure the CRC daemon is running and a CRC cluster is running, for more information please check the logs. Error: \(error)")
    }
}

func HandleLoginCommandForDeveloper() {
    do {
        let data = try SendCommandToDaemon(HTTPMethod.GET, "/api/webconsoleurl")
        let webConsoleResult = try JSONDecoder().decode(WebConsoleResult.self, from: data)

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
    } catch let error {
        showAlertFailedAndCheckLogs(message: "Failed to get login command", informativeMsg: "Ensure the CRC daemon is running and a CRC cluster is running, for more information please check the logs. Error: \(error)")
    }
}

func FetchVersionInfoFromDaemon() -> (String, String) {
    do {
        let data = try SendCommandToDaemon(HTTPMethod.GET, "/api/version")
        let versionResult = try JSONDecoder().decode(VersionResult.self, from: data)
        let crcVersion = "\(versionResult.CrcVersion)+\(versionResult.CommitSha)"
        return (crcVersion, versionResult.OpenshiftVersion)
    } catch let error {
        showAlertFailedAndCheckLogs(message: "Failed to fetch version", informativeMsg: "Ensure the CRC daemon is running, for more information please check the logs. Error: \(error)")
        return ("", "")
    }
}

func GetConfigFromDaemon(properties: [String]) throws -> [String: String] {
    let data = try SendCommandToDaemon(HTTPMethod.GET, "/api/config/get", PropertiesArray(properties: properties))
    let configGetResult = try JSONDecoder().decode(ConfigGetResult.self, from: data)
    return configGetResult.Configs
}

func GetAllConfigFromDaemon() throws -> CrcConfigs {
    let data = try SendCommandToDaemon(HTTPMethod.GET, "/api/config/get")
    let decoder = JSONDecoder()
    let configResult = try decoder.decode(GetconfigResult.self, from: data)
    return configResult.Configs
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
    _ = try? SendCommandToDaemon(HTTPMethod.POST, "/api/telemetry", ["action": action.rawValue, "source": "tray"])
}

func IsPullSecretDefined() -> Bool {
    do {
        _ = try SendCommandToDaemon(HTTPMethod.GET, "/api/pull-secret")
        return true
    } catch {
        return false
    }
}
