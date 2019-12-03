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
    @IBOutlet weak var diskSize: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViewWithClusterStatus()
    }
    
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func updateViewWithClusterStatus() {
        let r = SendCommandToDaemon(command: Request(command: "status", args: nil))
        guard let data = r else { return }
        do {
            let status = try JSONDecoder().decode(ClusterStatus.self, from: data)
            if status.Success {
                self.vmStatus.stringValue = status.CrcStatus
                self.ocpStatus.stringValue = status.OpenshiftStatus
                self.diskSize.stringValue = String(status.DiskSize)
                self.diskUsage.stringValue = String(status.DiskUse)
            }
        } catch let jsonErr {
            print(jsonErr.localizedDescription)
        }
    }


}

