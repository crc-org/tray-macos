//
//  PullSecretViewController.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 29/09/20.
//  Copyright © 2020 Red Hat. All rights reserved.
//

import Cocoa
import NIOHTTP1

class PullSecretViewController: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var pullSecret: NSTextView!
    @IBOutlet weak var helpLabel: NSTextField!

    let helpString: String = "Please visit cloud.redhat.com to obtain Pull Secret"
    var font: NSFont?    = .systemFont(ofSize: 14, weight: .regular)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.preferredContentSize = NSSize(width: self.view.frame.size.width, height: self.view.frame.height)
    }

    override func viewDidAppear() {
        view.window?.title = self.title!
        view.window?.level = .floating
    }

    @IBAction func okButtonClicked(_ sender: Any) {
        SendTelemetry(Actions.EnterPullSecret)
        do {
            _ = try SendRawCommandToDaemon(HTTPMethod.POST, "/api/pull-secret", self.pullSecret.string.data(using: .utf8))
            self.view.window?.close()
            DispatchQueue.global(qos: .userInteractive).async {
                HandleStart()
            }
        } catch let error {
            switch error {
            case DaemonError.internalServerError(let message):
                self.helpLabel.attributedStringValue = NSAttributedString(string: message, attributes: [
                    .foregroundColor: NSColor.red,
                    .font: font as Any
                ])
            default:
                self.helpLabel.attributedStringValue = NSAttributedString(string: error.localizedDescription, attributes: [
                    .foregroundColor: NSColor.red,
                    .font: font as Any
                ])
            }
        }
    }
}
