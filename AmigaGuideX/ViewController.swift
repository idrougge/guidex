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
    let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
    
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
        let italic = manager.convert(fixedWidth, toHaveTrait: NSFontTraitMask(rawValue: UInt(NSFontItalicTrait)))
        let bold = manager.convert(fixedWidth, toHaveTrait: NSFontTraitMask.boldFontMask)
        textView.font = fixedWidth
        //let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        //paragraph.headIndent = 100.0
        //paragraph.firstLineHeadIndent = 100.0
        textView.defaultParagraphStyle = paragraph
        textView.alignLeft(nil)
        /*
        NSFontManager.trait
        NSFontMonoSpaceTrait
 */
        var typingAttributes = textView.typingAttributes
        typingAttributes.updateValue(fixedWidth, forKey: .font)
        textView.typingAttributes = typingAttributes
        textView.textStorage?.addAttributes(typingAttributes, range: NSMakeRange(0, 0) )
        let parser = Parser(file: "/Dropbox/AGReader/Docs/test.guide")
        for token in parser.parseResult {
            switch token {
            case .newline, .normal(.linebreak):
                textView.textStorage?.insert(NSAttributedString(string:"\n"), at: textView.textStorage!.length)
            case .plaintext(let text):
                let insertpoint = textView.textStorage!.length
                let range = NSMakeRange(insertpoint, text.count)
                textView.textStorage?.insert(NSAttributedString(string: text), at: insertpoint)
                textView.textStorage!.addAttribute(.paragraphStyle, value: paragraph, range: range)
                textView.textStorage?.addAttributes(typingAttributes, range: range)
            case .normal(.italic):
                let font = typingAttributes[.font] as! NSFont
                typingAttributes.updateValue(font.withTrait(trait: .italicFontMask), forKey: .font)
            case .normal(.noitalic):
                let font = typingAttributes[.font] as! NSFont
                typingAttributes.updateValue(font.withTrait(trait: .unitalicFontMask), forKey: .font)
            case .normal(.bold):
                let font = typingAttributes[.font] as! NSFont
                typingAttributes.updateValue(font.withTrait(trait: .boldFontMask), forKey: .font)
            case .normal(.nobold):
                let font = typingAttributes[.font] as! NSFont
                typingAttributes.updateValue(font.withTrait(trait: .unboldFontMask), forKey: .font)
            case .normal(.underline):
                typingAttributes.updateValue(NSUnderlineStyle.styleSingle.rawValue, forKey: .underlineStyle)
            case .normal(.nounderline):
                typingAttributes.removeValue(forKey: .underlineStyle)
            case .normal(.plain):
                let font = manager.convert(textView.font!, toNotHaveTrait: [.boldFontMask, .italicFontMask])
                typingAttributes.updateValue(font, forKey: .font)
                typingAttributes.removeValue(forKey: .underlineStyle)
            case .normal(.link(let label, let node, _)):
                // FIXME: System and REXX links must be discarded in a sensible way
                // TODO: Register URL scheme
                typingAttributes[.link] = "url"
                let text = NSAttributedString(string: "\(label) -> \(node)", attributes: typingAttributes)
                textView.insertText(text)
                typingAttributes.removeValue(forKey: .link)
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
            case .normal(.foreground(let pen)):
                let pens:[String:NSColor] =
                    ["detail":NSColor.brown, "text":.textColor, "block":.blue, "shine":.gray,
                     "shadow":.darkGray, "fill":.systemBlue, "filltext":.lightGray,
                     "background":.textBackgroundColor,
                     "highlighttext":.alternateSelectedControlTextColor]
                guard let colour = pens[pen] else { break }
                textView.typingAttributes.updateValue(colour, forKey: .foregroundColor)
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

extension NSFont {
    func withTrait(trait:NSFontTraitMask) -> NSFont {
        let new = NSFontManager.shared.convert(self, toHaveTrait: trait)
        return new
    }
}
