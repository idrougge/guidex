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
        let fixedWidth = NSFont.userFixedPitchFont(ofSize: 12)!
        let manager = NSFontManager.shared
        manager.addFontTrait(NSFontItalicTrait)
        let italic = manager.convert(fixedWidth, toHaveTrait: NSFontTraitMask(rawValue: UInt(NSFontItalicTrait)))
        let bold = manager.convert(fixedWidth, toHaveTrait: NSFontTraitMask.boldFontMask)
        textView.font = fixedWidth
        /*
        NSFontManager.trait
        NSFontMonoSpaceTrait
 */
        let parser = Parser(file: "/Dropbox/AGReader/Docs/test.guide")
        for token in parser.parseResult {
            switch token {
            case .newline, .normal(.linebreak): textView.insertLineBreak(nil)
            case .plaintext(let text): textView.insertText(text)
            case .normal(.italic):
                textView.typingAttributes = [NSAttributedStringKey.font:italic]
            case .normal(.noitalic): textView.typingAttributes = [NSAttributedStringKey.font:fixedWidth]
            case .normal(.bold): textView.typingAttributes = [NSAttributedStringKey.font:bold]
            case .normal(.nobold):
                let font = manager.convert(textView.font!, toNotHaveTrait: .boldFontMask)
                textView.typingAttributes = [.font: font]
            case .normal(.underline):
                textView.typingAttributes.updateValue(NSUnderlineStyle.styleSingle.rawValue, forKey: .underlineStyle)
            case .normal(.nounderline):
                textView.typingAttributes.removeValue(forKey: .underlineStyle)
            case .normal(.plain): textView.typingAttributes = [.font:fixedWidth]
            case .normal(.link(let label, let node, _)):
                // FIXME: System and REXX links must be discarded in a sensible way
                // TODO: Register URL scheme
                textView.typingAttributes.updateValue("url", forKey: .link)
                textView.insertText("\(label) -> \(node)")
                textView.typingAttributes.removeValue(forKey: .link)
            case .escaped(let escaped):
                textView.insertText(escaped)
            case .normal(.amigaguide): textView.insertText("AmigaGuide®")
            case .normal(.jcenter):
                textView.insertParagraphSeparator(nil)
                textView.alignCenter(nil)
            case .normal(.jleft):
                textView.insertParagraphSeparator(nil)
                textView.alignLeft(nil)
            case .normal(.jright):
                textView.insertParagraphSeparator(nil)
                textView.alignRight(nil)
            case .global(.endnode):
                textView.insertParagraphSeparator(nil)
            case .global(.node(let node, let headline)):
                textView.insertText("\(node): \(headline ?? "<nil>")")
                textView.insertLineBreak(nil)
            default:
                textView.typingAttributes.updateValue(NSColor.red, forKey: .foregroundColor)
                textView.insertText(String(describing: token))
                textView.typingAttributes.removeValue(forKey: .foregroundColor)
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

