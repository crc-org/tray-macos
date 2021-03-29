//
//  ViewController.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 12/11/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//

import Cocoa

class DetailedStatusViewController: NSViewController {

    @IBOutlet weak var vmStatus: NSTextField!
    @IBOutlet weak var ocpStatus: NSTextField!
    @IBOutlet weak var diskUsage: NSTextField!
    @IBOutlet weak var cacheSize: NSTextField!
    @IBOutlet weak var cacheDirectory: NSTextField!
    @IBOutlet weak var logs: NSTextView!

    let cacheDirPath: URL = userHomePath.appendingPathComponent(".crc").appendingPathComponent("cache")

    var timer: Timer?
    var font: NSFont?    = .systemFont(ofSize: 14, weight: .regular)

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }

        self.updateViewWithClusterStatus(appDelegate.status)
        self.timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(updateViewWithLogs), userInfo: nil, repeats: true)

        DispatchQueue.main.async {
            appDelegate.pollStatus()
            self.updateViewWithLogs()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(updateViewWithNotification(_:)), name: statusNotification, object: nil)
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    override func viewDidAppear() {
        self.logs.font = font
        self.logs.string = "Loading..."
        view.window?.level = .floating
        view.window?.center()
    }

    override func viewDidDisappear() {
        self.timer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "status"), object: nil)
    }

    @objc func updateViewWithLogs() {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try SendCommandToDaemon(command: Request(command: "logs", args: nil))
                let result = try JSONDecoder().decode(LogsResult.self, from: data)
                DispatchQueue.main.async {
                    let lines = result.Messages.joined(separator: "\n")
                    if lines != self.logs.string {
                        self.logs.string = lines
                        self.logs.scrollToEndOfDocument(nil)
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    self.logs.string =  "Failed to get logs. Error: \(error)"
                }
            }
        }
    }

    @objc private func updateViewWithNotification(_ notification: Notification) {
        guard let status = notification.object as? ClusterStatus else {
            return
        }
        DispatchQueue.main.async {
            self.updateViewWithClusterStatus(status)
        }
    }

    func updateViewWithClusterStatus(_ status: ClusterStatus) {
        var ocpVersion: String?
        DispatchQueue.global(qos: .background).sync {
            let versionInfo = FetchVersionInfoFromDaemon()
            ocpVersion = versionInfo.1
        }

        if status.Success {
            self.vmStatus.stringValue = status.CrcStatus!
            self.ocpStatus.stringValue = "\(status.OpenshiftStatus!) (v\(ocpVersion!))"
        } else {
            self.vmStatus.stringValue = status.Error!
            self.ocpStatus.stringValue = "Unknown"
        }
        self.diskUsage.stringValue = "\(Units(bytes: status.DiskUse ?? 0).getReadableUnit()) of \(Units(bytes: status.DiskSize ?? 0).getReadableUnit()) (Inside the VM)"
        self.cacheSize.stringValue = Units(bytes: folderSize(folderPath: self.cacheDirPath)).getReadableUnit()
        self.cacheDirectory.stringValue = self.cacheDirPath.path
    }
}
