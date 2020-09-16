//
//  customNumberFormatter.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 14/09/20.
//  Copyright © 2020 Red Hat. All rights reserved.
//

import Cocoa

class customNumberFormatter: NumberFormatter {
    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        // Allow blank value
        if partialString.count == 0  {
            return true
        }
        
        // Validate string if it's an int
        if partialString.isInt() {
            return true
        } else {
            NSSound.beep()
            return false
        }
    }
}

extension String {
    func isInt() -> Bool {
        if let intValue = Int(self) {
            if intValue >= 0 {
                return true
            }
        }
        return false
    }
}
