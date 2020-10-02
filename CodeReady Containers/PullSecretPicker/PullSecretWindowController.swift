//
//  PullSecretWindowController.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 29/09/20.
//  Copyright © 2020 Red Hat. All rights reserved.
//

import Cocoa

class PullSecretWindowController: NSWindowController {
    class func loadFromStoryBoard() -> PullSecretWindowController? {
        let controller = NSStoryboard(name: "pullSecretStoryBoard", bundle: nil).instantiateController(withIdentifier: "PullSecretWindowController") as! PullSecretWindowController
        return controller
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}
