//
//  ViewController.swift
//  AmigaGuideX
//
//  Created by Iggy Drougge on 2017-10-10.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var textView: NSTextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        if #available(OSX 10.11, *) {
            textView.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        } else {
            textView.font = NSFont.systemFont(ofSize: 12).fontDescriptor.withSymbolicTraits(NSFontDescriptor.SymbolicTraits.monoSpace)
        }
 */
        let fixedWidth = NSFont.userFixedPitchFont(ofSize: 12)
        let manager = NSFontManager.shared//NSFontManager()
        //manager.setSelectedFont(fixedWidth!, isMultiple: false)
        manager.addFontTrait(NSFontItalicTrait)
        let italic = manager.convert(fixedWidth!, toHaveTrait: NSFontTraitMask(rawValue: UInt(NSFontItalicTrait)))
        //let bold = manager.convert(fixedWidth!, toHaveTrait: NSFontTraitMask(rawValue: UInt(NSFontBoldTrait)))
        let bold = manager.convert(fixedWidth!, toHaveTrait: NSFontTraitMask.boldFontMask)
        textView.font = fixedWidth
        /*
        NSFontManager.trait
        NSFontMonoSpaceTrait
 */
        textView.insertText("Hej")
        let parser = Parser(file: "/Dropbox/AGReader/Docs/test.guide")
        //textView.insertText( parser.parseResult.first)
        let first = parser.parseResult.first
        print(first)
        //textView.insertText("bläj")
        //textView.insertText(first)
        print("first:",String(describing: first))
        textView.insertText(String(describing: first))
        for token in parser.parseResult {
            switch token {
            case .newline, .normal(.linebreak): textView.insertLineBreak(nil)
            case .plaintext(let text): textView.insertText(text)
            case .normal(.italic): //textView.font = NSFont.systemFont(ofSize: 14)
            //textView.typingAttributes = [NSAttributedStringKey.strikethroughStyle:NSUnderlineStyle.styleDouble]
            //textView.typingAttributes = [NSAttributedStringKey.foregroundColor:NSColor.green]
            //textView.setFont(NSFont.systemFont(ofSize: 14), range: NSMakeRange(textView.range, <#T##len: Int##Int#>))
                textView.typingAttributes = [NSAttributedStringKey.font:italic]
            case .normal(.noitalic): textView.typingAttributes = [NSAttributedStringKey.font:fixedWidth]
            case .normal(.bold): textView.typingAttributes = [NSAttributedStringKey.font:bold]
            case .normal(.nobold): textView.typingAttributes = [:]
            default: break
            }
        }
        //textView.insertLineBreak(nil)
        //textView.insertLineBreak(nil)
        //textView.insertLineBreak(nil)
        textView.insertText("SLUT")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func didPressButton(_ sender: NSButton) {
    }
    
}

