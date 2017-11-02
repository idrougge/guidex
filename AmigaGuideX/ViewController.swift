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
        textView.alignLeft(nil)
        var typingAttributes = textView.typingAttributes
        typingAttributes.updateValue(fixedWidth, forKey: .font)
        textView.typingAttributes = typingAttributes
        textView.textStorage?.addAttributes(typingAttributes, range: NSMakeRange(0, 0) )
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
                textView.insertText(text)
                typingAttributes.removeValue(forKey: .link)
            case .escaped(let escaped):
                textView.textStorage?.append(NSAttributedString(string: escaped, attributes: typingAttributes))
            case .normal(.amigaguide):
                textView.textStorage?.append(NSAttributedString(string: "AmigaGuide®", attributes: typingAttributes))
            case .normal(.lindent(let indentation)):
                let p = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                p.headIndent = CGFloat(indentation*40)
                p.firstLineHeadIndent = CGFloat(indentation*40)
                typingAttributes.updateValue(p, forKey: .paragraphStyle)
                textView.textStorage?.append(NSAttributedString(string: "LINDENT \(indentation) \(textView.textStorage!.length) \(textView.textStorage!.paragraphs.count)", attributes: typingAttributes))
                break
                //paragraph.headIndent = 200.0
                let lastParagraph = textView.textStorage!.paragraphs.last!
                lastParagraph.addAttribute(.paragraphStyle, value: paragraph, range: NSRange.init(location: 0, length: lastParagraph.length))
                lastParagraph.insert(NSAttributedString(string: "LINDENT \(indentation) \(lastParagraph.length) \(textView.textStorage!.paragraphs.count)"), at: 0)
                break
                textView.insertText("<LINDENT \(indentation) (\(paragraph.firstLineHeadIndent) \(paragraph.headIndent))")
                setIndentation(to: indentation, in: textView)
                textView.insertText(">LINDENT \(indentation) (\(paragraph.firstLineHeadIndent) \(paragraph.headIndent))")
                break
                let level = CGFloat(indentation*10)
                paragraph.headIndent = level
                paragraph.firstLineHeadIndent = level
                //paragraph.tailIndent = 200.0
                
                textView.insertParagraphSeparator(nil)
                textView.defaultParagraphStyle = paragraph // Unless default paragraph style is reassigned, no change is visible
                textView.alignLeft(nil) // Unless alignment is set, indentation is not respected for first line
                textView.insertText("LINDENT \(indentation) (\(level))")
                
            case .normal(.code):
                // TODO: Turn off word wrapping
                let paragraph = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                paragraph.lineBreakMode = .byTruncatingTail
                typingAttributes[.paragraphStyle] = paragraph
                //paragraph.tailIndent = 200.0
            case .normal(.pari(let indentation)):
                textView.textStorage?.append(NSAttributedString(string: "PARI \(indentation)", attributes: typingAttributes))
                break
                textView.insertText("PARI \(indentation)")
                //let paragraph = NSMutableParagraphStyle()
                //paragraph.headIndent = CGFloat(indentation*40)
                //paragraph.firstLineHeadIndent = CGFloat(indentation*40)
                paragraph.headIndent = 20
                paragraph.firstLineHeadIndent = CGFloat(indentation*10)
                paragraph.tailIndent = 0
                textView.insertParagraphSeparator(nil)
                textView.defaultParagraphStyle = paragraph
                textView.insertText("PARI \(indentation)")
            case .normal(.pard):
                typingAttributes.removeValue(forKey: .foregroundColor)
                typingAttributes.updateValue(paragraph, forKey: .paragraphStyle)
                break
                paragraph.headIndent = 0
                paragraph.firstLineHeadIndent = 0
                break
                setIndentation(to: 0, in: textView)
                textView.insertText("PARD (\(paragraph.firstLineHeadIndent) \(paragraph.headIndent))")
                break
                paragraph.headIndent = 0
                paragraph.firstLineHeadIndent = 0
                textView.insertParagraphSeparator(nil)
                textView.defaultParagraphStyle = paragraph
                textView.alignLeft(nil)
                textView.insertText("PARD")
            case .normal(.jcenter):
                let paragraph = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = .center
                typingAttributes.updateValue(paragraph, forKey: .paragraphStyle)
                break
                textView.insertParagraphSeparator(nil)
                textView.alignCenter(nil)
            case .normal(.jleft):
                let paragraph = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = .left
                typingAttributes.updateValue(paragraph, forKey: .paragraphStyle)
                break
                textView.insertParagraphSeparator(nil)
                textView.alignLeft(nil)
            case .normal(.jright):
                let paragraph = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = .right
                typingAttributes.updateValue(paragraph, forKey: .paragraphStyle)
                break
                textView.insertParagraphSeparator(nil)
                textView.alignRight(nil)
            case .global(.endnode):
                textView.textStorage?.append(NSAttributedString(string: "\r\n"))
                break
                textView.insertParagraphSeparator(nil)
            case .global(.node(let node, let headline)):
                textView.textStorage?.append(NSAttributedString(string: "\r\n\(node): \(headline ?? "<nil>")"))
                //textView.insertText("\(node): \(headline ?? "<nil>")")
                //textView.insertLineBreak(nil)
            case .normal(.foreground(let pen)):
                let pens:[String:NSColor] =
                    ["detail":.brown, "text":.textColor, "block":.blue, "shine":.gray,
                     "shadow":.darkGray, "fill":.systemBlue, "filltext":.lightGray,
                     "background":.textBackgroundColor,
                     "highlighttext":.alternateSelectedControlTextColor]
                guard let colour = pens[pen] else { break }
                typingAttributes.updateValue(colour, forKey: .foregroundColor)
            /*
            case .normal(.settabs(_)):
                paragraph.tabStops
             */
            default:
                typingAttributes.updateValue(NSColor.red, forKey: .foregroundColor)
                textView.textStorage?.append(NSAttributedString(string: String(describing: token), attributes: typingAttributes))
                typingAttributes.removeValue(forKey: .foregroundColor)
            }
        }
    }

    func setIndentation(to indentation:Int, in textView:NSTextView) {
        let level = CGFloat(indentation * 10)
        paragraph.headIndent = level
        paragraph.firstLineHeadIndent = level
        //paragraph.tailIndent = 200.0
        textView.insertParagraphSeparator(nil)
        //textView.textStorage!.addAttribute(.paragraphStyle, value: paragraph, range: NSRange.init(location: textView.textStorage!.length-1, length: 1))
        textView.defaultParagraphStyle = paragraph // Unless default paragraph style is reassigned, no change is visible
        textView.alignLeft(nil) // Unless alignment is set, indentation is not respected for first line
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
