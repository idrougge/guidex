//
//  String+Extension.swift
//  AmigaGuideX
//
//  Created by Iggy Drougge on 2017-10-10.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//
import Foundation

extension String {
    func splitFirstWord() -> (pre:String,rest:String?)? {
        guard let spaceRange = self.rangeOfCharacter(from: .whitespaces) else { return (self,nil) }
        let prefix = self[..<spaceRange.lowerBound]
        let suffix = self[spaceRange.upperBound...]
        return (String(prefix),String(suffix))
    }
}
