//
//  NSFont+Extension.swift
//  AmigaGuideX
//
//  Created by Iggy Drougge on 2017-11-04.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//

import Cocoa

extension NSFont {
    func withTrait(trait:NSFontTraitMask) -> NSFont {
        let new = NSFontManager.shared.convert(self, toHaveTrait: trait)
        return new
    }
}
