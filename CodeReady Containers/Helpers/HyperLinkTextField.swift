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

// A text field that can contain a hyperlink within a range of characters in the text.
@IBDesignable class SubstringLinkedTextField: NSTextField {
    // the URL that will be opened when the link is clicked.
    public var link: String = ""
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'link' instead.")
    @IBInspectable public var HREF: String {
        get {
            return self.link
        }
        set {
            self.link = newValue
            self.needsDisplay = true
        }
    }

    // the substring within the field's text that will become an underlined link. if empty or no match found, the entire text will become the link.
    public var linkText: String = ""
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'linkText' instead.")
    @IBInspectable public var LinkText: String {
        get {
            return self.linkText
        }
        set {
            self.linkText = newValue
            self.needsDisplay = true
        }
    }

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.allowsEditingTextAttributes = true
        self.isSelectable = true

        let url = URL(string: self.link)
        let attributes: [NSAttributedString.Key: AnyObject] = [
            NSAttributedString.Key(rawValue: NSAttributedString.Key.link.rawValue): url as AnyObject
        ]
        let attributedStr = NSMutableAttributedString(string: self.stringValue)

        if self.linkText.count > 0 {
            if let range = self.stringValue.range(of: self.linkText) {
                attributedStr.setAttributes(attributes, range: range.nsRange(in: self.linkText))
            } else {
                attributedStr.setAttributes(attributes, range: NSRange(location: 0, length: self.stringValue.count))
            }
        } else {
            attributedStr.setAttributes(attributes, range: NSRange(location: 0, length: self.stringValue.count))
        }
        self.attributedStringValue = attributedStr
    }

    override func mouseDown(with event: NSEvent) {
        NSWorkspace.shared.open(URL(string: self.link)!)
    }
}

extension RangeExpression where Bound == String.Index {
    func nsRange<S: StringProtocol>(in string: S) -> NSRange { .init(self, in: string) }
}
