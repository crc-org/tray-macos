//
//  HyperLinkTextField.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 02/12/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//

// Following code is based on https://stackoverflow.com/a/38342144

import Cocoa

@IBDesignable class HyperLinkTextField: NSTextField {
    @IBInspectable var href: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let attributes: [NSAttributedString.Key: AnyObject] = [
            NSAttributedString.Key(rawValue: NSAttributedString.Key.underlineStyle.rawValue): NSUnderlineStyle.single.rawValue as AnyObject,
            NSAttributedString.Key(rawValue: NSAttributedString.Key.link.rawValue): URL(string: self.href) as AnyObject
        ]
        self.attributedStringValue = NSAttributedString(string: self.stringValue, attributes: attributes)
    }
    
    override func mouseDown(with event: NSEvent) {
        NSWorkspace.shared.open(URL(string: self.href)!)
    }
}
