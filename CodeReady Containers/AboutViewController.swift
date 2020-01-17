//
//  AboutViewController.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 15/11/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//

import Cocoa

class AboutViewController: NSViewController {
    @IBOutlet weak var trayVersionField: NSTextField!
    @IBOutlet weak var openshiftVersionField: NSTextField!
    @IBOutlet weak var crcVersionField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let versions = FetchVersionInfoFromDaemon()
        crcVersionField.stringValue = versions.0
        openshiftVersionField.stringValue = versions.1
        let nsObject: AnyObject? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as AnyObject?
        trayVersionField.stringValue = nsObject as? String ?? ""
    }
    
    override func viewDidAppear() {
        view.window?.level = .floating
    }
}
