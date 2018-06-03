//
//  ViewController.swift
//  AmigaGuideX
//
//  Created by Iggy Drougge on 2017-10-10.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//

import Cocoa

fileprivate typealias TypingAttributes = [NSAttributedStringKey:Any]
fileprivate class Node {
    let name:String
    let title:String?
    let contents:[AmigaGuide.Tokens]
    let typingAttributes:TypingAttributes
    init?(_ node:AmigaGuide.Tokens?, attributes:TypingAttributes) {
        guard let node = node, case let .node(name: name, title: title, contents: contents) = node else {
            return nil
        }
        self.name = name
        self.title = title
        self.contents = contents
        self.typingAttributes = attributes
    }
}

protocol NavigationController {
    var canGoBack: Bool {get}
    var canGoForward: Bool {get}
    var canRetrace: Bool {get}
    func goBack()
    func goForward()
    func retrace()
}

class ViewController: NSViewController, NSTextViewDelegate {

    @IBOutlet var textView: NSTextView!
    private let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
    private let manager = NSFontManager.shared
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        print(#function, menuItem)
        return true
    }
    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        print(#function, "\"\(link)\"", charIndex)
        guard let link = link as? String, let node = allNodes[link] else { return false }
        parse(node.contents, attributes: node.typingAttributes)
        currentNode = node.name
        navigationHistory.append(node)
        self.view.window?.title = node.title ?? NSLocalizedString("Unnamed node", comment: "")
        return true // Stop next responder from handling link
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        //becomeFirstResponder()
        /*
        if #available(OSX 10.11, *) {
            textView.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        } else {
            textView.font = NSFont.systemFont(ofSize: 12).fontDescriptor.withSymbolicTraits(NSFontDescriptor.SymbolicTraits.monoSpace)
        }
 */
        //let fixedWidth = NSFont(name: "TopazPlus a600a1200a4000", size: 14)
        let fixedWidth = NSFont.userFixedPitchFont(ofSize: 12)!
        
        textView.enclosingScrollView?.hasHorizontalScroller = true
        
        var typingAttributes = textView.typingAttributes
        typingAttributes.updateValue(fixedWidth, forKey: .font)
        #if DEBUG
        //let parser = Parser(file: "/Dropbox/AGReader/Docs/test.guide")
        //let parser = Parser(file: "/Desktop/System3.9/Locale/Help/svenska/Sys/amigaguide.guide")
        //let parser = Parser(file: "/Downloads/E_v3.3a/Docs/BeginnersGuide/Appendices.guide")
        let parser = Parser(file: "/Downloads/E_v3.3a/Bin/Tools/AProf/AProf.guide")
        //let parser = Parser(file: "/Dropbox/bb2guide13/Blitz2_V1.3.guide")
        parse(parser.parseResult, attributes: typingAttributes)
        #endif
        //if let main = allNodes["MAIN"], case let AmigaGuide.Tokens.node(name: _, title: _, contents: contents) = main {
        guard !allNodes.isEmpty else { return print("Found no nodes") }
        // FIXME: While the guard ensures safety, this is nevertheless ugly
        if let main = allNodes["MAIN"] ?? allNodes[nodeOrder.first!] {
            parse(main.contents, attributes: typingAttributes)
            currentNode = main.name
            navigationHistory.append(main)
        }
    }
    
    //var allNodes:[String:AmigaGuide.Tokens] = [:]
    fileprivate var allNodes:[String:Node] = [:]
    /// Names of all nodes in order of appearance, for fetching
    var nodeOrder:[String] = []
    /// Name of @NEXT node
    var nextNode:String?
    /// Name of @PREV node
    var precedingNode:String?
    // TODO: Can be surmised from top of navigationHistory
    /// Name of current node
    var currentNode:String?
    /// Name of table of contents node
    var tocNode:String?
    /// Current navigation history
    fileprivate var navigationHistory:[Node] = []
    
    fileprivate func parse(_ tokens:[AmigaGuide.Tokens], attributes:TypingAttributes) {
        var typingAttributes = attributes
        (nextNode, precedingNode, currentNode) = (nil,nil,nil)
        textView.string = ""
        
        for token in tokens {
            switch token {
            case let .node(name: name, title: _, contents: _):
                //allNodes[name] = token
                let node = Node.init(token, attributes: attributes)
                allNodes[name] = node
                nodeOrder.append(name)
            case .global(.next(let next)):
                self.nextNode = next
            case .global(.prev(let prev)):
                self.precedingNode = prev
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
                typingAttributes[.link] = node
                let text = NSAttributedString(string: label, attributes: typingAttributes)
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
            case .global(.title(let title)): self.view.window?.title = title
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

    @IBAction func didSelectOpen(_ sender:NSMenuItem) {
        print(#function, sender)
    }
}
// MARK: - Navigation
extension ViewController: NavigationController {
    var canGoBack: Bool {
        // TODO: This should only be calculated when navigating between nodes
        if let prev = precedingNode, let _ = allNodes[prev] {
            return true
        }
        if let currentNode = currentNode,
            let currentIndex = nodeOrder.index(of: currentNode),
            1 ..< nodeOrder.count ~= currentIndex,
            let _ = allNodes[nodeOrder[currentIndex - 1]]{
            return true
        }
        return false
    }
    
    var canGoForward: Bool {
        // FIXME: Return correct value
        if let _ = self.nextNode {
            return true
        }
        return false
    }
    
    var canRetrace: Bool {
        return navigationHistory.count > 1
    }
    
    func goBack() {
        print(#function, precedingNode ?? "")
        switch (precedingNode, currentNode) {
        case (let precedingNode?, _): break
        case (_, let current?) where current == "a" && 1>2: break
        case (_, let currentNode?): break
        default: break
        }
        guard let prevNode = precedingNode,
            let prev = allNodes[prevNode] else {
                if let currentNode = currentNode,
                    let currentIndex = nodeOrder.index(of: currentNode),
                    1..<nodeOrder.count ~= currentIndex,
                    let prev = allNodes[nodeOrder[currentIndex - 1]]{
                    parse(prev.contents, attributes: prev.typingAttributes)
                    self.currentNode = prev.name
                }
                return
        }
        parse(prev.contents, attributes: prev.typingAttributes)
        currentNode = prev.name
    }
    
    func goForward() {
        print(#function, nextNode ?? "not found")
        guard let nextNode = nextNode,
            let next = allNodes[nextNode]
            //case .node(name: _, title: _, contents: let contents) = next
            else {
                if let current = currentNode, let index = nodeOrder.index(of: current), index < nodeOrder.count - 1, let next = allNodes[nodeOrder[index + 1]] {
                    parse(next.contents, attributes: next.typingAttributes)
                    currentNode = next.name
                }
                return
        }
        parse(next.contents, attributes: next.typingAttributes)
        currentNode = next.name
    }
    
    func retrace() {
        defer {
            self.view.window?.toolbar?.items.forEach{ item in
                self.view.window?.windowController?.validateToolbarItem(item)
            }
        }
        print(#function, navigationHistory)
        guard canRetrace else {
            return
        }
        _ = navigationHistory.removeLast()
        guard let last = navigationHistory.last//popLast()
            else {
                return
        }
        parse(last.contents, attributes: last.typingAttributes)
        currentNode = last.name
    }
}
