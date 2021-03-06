//
//  String+Extensions.swift
//  Whereno
//
//  Created by Kyle Bashour on 4/26/16.
//  Copyright © 2016 Kyle Bashour. All rights reserved.
//

import Foundation

extension String {

    // Separate based on white space, then join with no whitespace
    func stringByRemovingWhiteSpace() -> String {
        let components = self.componentsSeparatedByCharactersInSet(.whitespaceAndNewlineCharacterSet())
        return components.joinWithSeparator("")
    }
}
