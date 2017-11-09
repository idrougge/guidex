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
        //let fixedWidth = NSFont(name: "TopazPlus a600a1200a4000", size: 14)
        let fixedWidth = NSFont.userFixedPitchFont(ofSize: 12)!
        let manager = NSFontManager.shared
        textView.enclosingScrollView?.hasHorizontalScroller = true
        /*
        textView.maxSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.containerSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
        textView.isHorizontallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        paragraph.lineBreakMode = .byWordWrapping
         */
        /*
        let storage = textView.textStorage!
        var atts = [NSAttributedStringKey:Any]()
        atts[.font] = fixedWidth
        atts[.paragraphStyle] = paragraph
        let str = NSAttributedString(string: "Hej", attributes: atts)
        storage.append(str)
        storage.append(NSAttributedString(string: "\r\n"))
        paragraph.alignment = .right
        let p2 = paragraph.mutableCopy() as! NSMutableParagraphStyle
        p2.alignment = .center
        atts[.paragraphStyle] = p2
        atts[.font] = nil
        storage.append(NSAttributedString(string: "Svejs", attributes: atts))
        storage.append(NSAttributedString(string: "\r\n"))
        return
         */
        //textView.font = fixedWidth
        //let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        //paragraph.headIndent = 100.0
        //paragraph.firstLineHeadIndent = 100.0
        //textView.defaultParagraphStyle = paragraph
        var typingAttributes = textView.typingAttributes
        typingAttributes.updateValue(fixedWidth, forKey: .font)
        let parser = Parser(file: "/Dropbox/AGReader/Docs/test.guide")
        
        for token in parser.parseResult {
            switch token {
            case .newline, .normal(.linebreak):
                textView.textStorage?.insert(NSAttributedString(string:"\r\n"), at: textView.textStorage!.length)
            case .plaintext(let text):
                //paragraph.alignment = .center
                //typingAttributes.updateValue(paragraph, forKey: .paragraphStyle)
                let text = NSMutableAttributedString(string: text, attributes: typingAttributes)
                //text.addAttribute(.paragraphStyle, value: paragraph, range: NSMakeRange(0, text.length))
                textView.textStorage?.append(text)
                /*
                let insertpoint = textView.textStorage!.length
                let range = NSMakeRange(insertpoint, text.count)
                textView.textStorage?.insert(NSAttributedString(string: text), at: insertpoint)
                //textView.textStorage!.addAttribute(.paragraphStyle, value: paragraph, range: range)
                textView.textStorage?.addAttributes(typingAttributes, range: range)
                 */
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
                textView.textStorage?.append(text)
                //textView.insertText(text)
                typingAttributes.removeValue(forKey: .link)
            case .escaped(let escaped):
                textView.textStorage?.append(NSAttributedString(string: escaped, attributes: typingAttributes))
            case .normal(.amigaguide):
                textView.textStorage?.append(NSAttributedString(string: "AmigaGuide®", attributes: typingAttributes))
            case .normal(.lindent(let indentation)):
                let width = tabSize(spaces: indentation, attributes: typingAttributes)
                let p = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                p.headIndent = width
                p.firstLineHeadIndent = width
                typingAttributes.updateValue(p, forKey: .paragraphStyle)
                textView.textStorage?.append(NSAttributedString(string: "LINDENT \(indentation) \(textView.textStorage!.length) \(width)", attributes: typingAttributes))
            case .normal(.code):
                // TODO: Turn off word wrapping
                let paragraph = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                paragraph.lineBreakMode = .byTruncatingTail
                paragraph.lineBreakMode = .byClipping
                typingAttributes[.paragraphStyle] = paragraph
            case .normal(.pari(let indentation)):
                textView.textStorage?.append(NSAttributedString(string: "PARI \(indentation)", attributes: typingAttributes))
                break
            // TODO: Reset indentation for PARD?
            case .normal(.pard):
                typingAttributes.removeValue(forKey: .foregroundColor)
                typingAttributes.updateValue(paragraph, forKey: .paragraphStyle)
            case .normal(.jcenter):
                let paragraph = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = .center
                typingAttributes.updateValue(paragraph, forKey: .paragraphStyle)
            case .normal(.jleft):
                let paragraph = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = .left
                typingAttributes.updateValue(paragraph, forKey: .paragraphStyle)
            case .normal(.jright):
                let paragraph = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = .right
                typingAttributes.updateValue(paragraph, forKey: .paragraphStyle)
            case .global(.endnode):
                textView.textStorage?.append(NSAttributedString(string: "\r\n"))
            case .global(.node(let node, let headline)):
                textView.textStorage?.append(NSAttributedString(string: "\r\n\(node): \(headline ?? "<nil>")"))
            case .normal(.foreground(let pen)):
                let pens:[String:NSColor] =
                    ["detail":.brown, "text":.textColor, "block":.blue, "shine":.gray,
                     "shadow":.darkGray, "fill":.systemBlue, "filltext":.lightGray,
                     "background":.textBackgroundColor,
                     "highlighttext":.alternateSelectedControlTextColor]
                guard let colour = pens[pen] else { break }
                typingAttributes.updateValue(colour, forKey: .foregroundColor)
            case .normal(.settabs(let tabs)):
                let paragraph = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                paragraph.tabStops = tabs
                    .map{tab in tabSize(spaces: tab, attributes: typingAttributes)}
                    .map{location in NSTextTab(type: .leftTabStopType, location: location)}
                typingAttributes.updateValue(paragraph, forKey: .paragraphStyle)
            case .normal(.cleartabs):
                let p = typingAttributes[.paragraphStyle] as? NSMutableParagraphStyle ?? self.paragraph
                let paragraph = p.mutableCopy() as! NSMutableParagraphStyle
                paragraph.tabStops = self.paragraph.tabStops
                typingAttributes[.paragraphStyle] = paragraph
            default:
                typingAttributes.updateValue(NSColor.red, forKey: .foregroundColor)
                textView.textStorage?.append(NSAttributedString(string: String(describing: token), attributes: typingAttributes))
                typingAttributes.removeValue(forKey: .foregroundColor)
            }
        }
    }

    func tabSize(spaces:Int, attributes:[NSAttributedStringKey:Any]) -> CGFloat {
        return String(repeating: " ", count: spaces).size(withAttributes: attributes).width
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func didPressButton(_ sender: NSButton) {
    }
    @IBAction func didPressPrevious(_ sender: NSButton) {
    }
    @IBAction func didPressNext(_ sender: NSButton) {
    }
    @IBAction func didPressContents(_ sender: Any) {
    }
    
}
