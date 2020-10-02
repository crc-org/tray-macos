//
//  PullSecretViewController.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 29/09/20.
//  Copyright © 2020 Red Hat. All rights reserved.
//

import Cocoa

class PullSecretViewController: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var pullSecretFilePath: NSTextField!
    @IBOutlet weak var helpLabel: NSTextField!
    
    let helpString: String = "Please visit cloud.redhat.com to obtain Pull Secret"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.height)
    }
    
    override func viewDidAppear() {
        view.window?.title = self.title!
        view.window?.level = .floating
    }
    
    @IBAction func browseButtonClicked(_ sender: Any) {
        // show the filepicker
        // set the path of the file as filepath in the textfield
        showFilePicker(msg: "Select Pull Secret File", txtField: self.pullSecretFilePath)
    }
    
    @IBAction func okButtonClicked(_ sender: Any) {
        // check if the textfield is empty
        // if not communicate the filepath back to app delegate
        if self.pullSecretFilePath.stringValue == "" {
            // show help string to get pull secret
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.red,
                .font: NSFont(name: "Helvetica Neue Italic", size: 12) as Any
            ]
            let styledString = NSAttributedString(string: self.helpString, attributes: attributes)
            self.helpLabel.attributedStringValue = styledString
        } else {
            self.view.window?.close()
            let path = self.pullSecretFilePath.stringValue
            DispatchQueue.global(qos: .userInteractive).async {
                HandleStart(pullSecretPath: path)
            }
        }
    }
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        self.helpLabel.attributedStringValue = NSAttributedString(string: "")
    }
}
