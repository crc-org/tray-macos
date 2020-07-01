//
//  ConfigViewController.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 01/07/20.
//  Copyright © 2020 Red Hat. All rights reserved.
//

import Cocoa

class ConfigViewController: NSViewController {
    // preflight check controls
    @IBOutlet weak var checkBundleCached: NSPopUpButton!
    @IBOutlet weak var checkHyperkitDriverCached: NSPopUpButton!
    @IBOutlet weak var checkPodmanCached: NSPopUpButton!
    @IBOutlet weak var checkResolverFilePermission: NSPopUpButton!
    @IBOutlet weak var checkRunningAsRoot: NSPopUpButton!
    
    // config properties controls
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.height)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.parent?.view.window?.title = self.title!
    }
    
}
