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

        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }
        self.updateViewWithClusterStatus(appDelegate.status)

        DispatchQueue.main.async {
            appDelegate.pollStatus()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(updateViewWithNotification(_:)), name: statusNotification, object: nil)
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

    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "status"), object: nil)
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
        if status.Success {
            self.vmStatus.stringValue = status.CrcStatus!
            self.ocpStatus.stringValue = status.OpenshiftStatus!
        } else {
            self.vmStatus.stringValue = status.Error!
            self.ocpStatus.stringValue = "Unknown"
        }
        self.diskUsage.stringValue = "\(Units(bytes: status.DiskUse ?? 0).getReadableUnit()) of \(Units(bytes: status.DiskSize ?? 0).getReadableUnit()) (Inside the VM)"
        self.cacheSize.stringValue = Units(bytes: folderSize(folderPath: self.cacheDirPath)).getReadableUnit()
        self.cacheDirectory.stringValue = self.cacheDirPath.path
    }
}
