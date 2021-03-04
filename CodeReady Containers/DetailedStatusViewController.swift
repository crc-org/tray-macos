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
    
    let cacheDirPath: URL = userHomePath.appendingPathComponent(".crc").appendingPathComponent("cache")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViewWithClusterStatus()
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func viewDidAppear() {
        view.window?.level = .floating
        view.window?.center()
    }
    
    func updateViewWithClusterStatus() {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try SendCommandToDaemon(command: Request(command: "status", args: nil))
                let status = try JSONDecoder().decode(ClusterStatus.self, from: data)
                if status.Success {
                    DispatchQueue.main.async {
                        self.vmStatus.stringValue = status.CrcStatus
                        self.ocpStatus.stringValue = status.OpenshiftStatus
                        self.diskUsage.stringValue = "\(Units(bytes: status.DiskUse).getReadableUnit()) of \(Units(bytes: status.DiskSize).getReadableUnit()) (Inside the VM)"
                        self.cacheSize.stringValue = Units(bytes: folderSize(folderPath: self.cacheDirPath)).getReadableUnit()
                        self.cacheDirectory.stringValue = self.cacheDirPath.path
                    }
                } else {
                    showAlertFailedAndCheckLogs(message: "Failed to get status", informativeMsg: status.Error)
                }
            } catch {
                showAlertFailedAndCheckLogs(message: "Failed to get status", informativeMsg: error.localizedDescription)
            }
        }
    }
}

