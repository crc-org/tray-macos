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
    @IBOutlet weak var releaseNotes: HyperLinkTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        SendTelemetry(Actions.OpenAbout)

        let versions = FetchVersionInfoFromDaemon()
        crcVersionField.stringValue = versions.0
        openshiftVersionField.stringValue = versions.1
        let nsObject: AnyObject? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as AnyObject?
        trayVersionField.stringValue = nsObject as? String ?? ""

        // original: 1.24.0+9dce9bee; releaseNotesVersion: 1.24.0
        let crcVersionForReleaseNotes = String(versions.0.split(separator: "+")[0])

        releaseNotes.href = "https://access.redhat.com/documentation/en-us/red_hat_codeready_containers/\(crcVersionForReleaseNotes)/html-single/release_notes_and_known_issues/index"

    }

    override func viewDidAppear() {
        view.window?.level = .floating
        view.window?.center()
    }
}
