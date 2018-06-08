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
    var hasIndex: Bool {get}
    func goBack()
    func goForward()
    func retrace()
    func goToMain()
    func goToIndex()
}

class ViewController: NSViewController, NSTextViewDelegate {

    @IBOutlet var textView: NSTextView!
    private let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
    private let manager = NSFontManager.shared
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        print(#function, menuItem)
        return true
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
        //let fixedWidth = NSFont.userFixedPitchFont(ofSize: 12)!
        
        textView.enclosingScrollView?.hasHorizontalScroller = true
        textView.isEditable = false
        #if DEBUG
        //let parser = Parser(file: "/Dropbox/AGReader/Docs/test.guide")
        //let parser = Parser(file: "/Desktop/System3.9/Locale/Help/svenska/Sys/amigaguide.guide")
        //let parser = Parser(file: "/Downloads/E_v3.3a/Docs/BeginnersGuide/Appendices.guide")
        openFile("/Downloads/E_v3.3a/Bin/Tools/AProf/AProf.guide")
        //let parser = Parser(file: "/Dropbox/bb2guide13/Blitz2_V1.3.guide")
        #endif
    }
    /// Only for debug purposes
    private func openFile(_ name:String) {
        let url = URL(fileURLWithPath: NSHomeDirectory() + name)
        openNewFile(from: url)
    }
    
    func openNewFile(from url:URL) {
        do {
            let parser = try Parser(file: url)
            print(url.deletingLastPathComponent().path)
            guard FileManager.default.changeCurrentDirectoryPath(url.deletingLastPathComponent().path) else {
                throw NSError(domain: NSCocoaErrorDomain,
                              code: NSFileNoSuchFileError,
                              userInfo: [NSFilePathErrorKey:url.path])
                }
            let result = parser.parseResult
            let fixedWidth = NSFont.userFixedPitchFont(ofSize: 12)!
            var typingAttributes = textView.typingAttributes
            typingAttributes.updateValue(fixedWidth, forKey: .font)
            nodeOrder.removeAll()
            allNodes.removeAll()
            navigationHistory.removeAll()
            parse(result, attributes: typingAttributes)
            guard !allNodes.isEmpty else { return print("Found no nodes") }
            guard let main = getMainNode() else { return print("Found no main node") }
            parse(main.contents, attributes: main.typingAttributes)
            present(node: main)
        } catch {
            print(error)
            self.presentError(error)
        }
    }
    
    /// All nodes in a parsed file
    fileprivate var allNodes:[String:Node] = [:]
    /// Names of all nodes in order of appearance, for fetching
    fileprivate var nodeOrder:[String] = []
    /// Name of @NEXT node
    fileprivate var nextNode:String?
    /// Name of @PREV node
    fileprivate var precedingNode:String?
    // TODO: Can be surmised from top of navigationHistory
    /// Name of current node
    fileprivate var currentNode:String? {
        return navigationHistory.last?.name
    }
    /// Name of table of contents node
    fileprivate var tocNode:String?
    /// Current navigation history
    fileprivate var navigationHistory:[Node] = []
    
    fileprivate func present(node: Node) {
        parse(node.contents, attributes: node.typingAttributes)
        navigationHistory.append(node)
        self.view.window?.title = node.title ?? node.name
    }

    fileprivate func parse(_ tokens:[AmigaGuide.Tokens], attributes:TypingAttributes) {
        var typingAttributes = attributes
        (nextNode, precedingNode, tocNode) = (nil,nil,nil)
        textView.string = ""
        
        for token in tokens {
            switch token {
            case let .node(name: name, title: _, contents: _):
                let node = Node(token, attributes: attributes)
                allNodes[name] = node
                nodeOrder.append(name)
            case .global(.next(let next)):
                self.nextNode = next
            case .global(.prev(let prev)):
                self.precedingNode = prev
            case .global(.index(let index)):
                self.tocNode = index
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
                let paragraph = self.paragraph.mutableCopy() as! NSMutableParagraphStyle
                paragraph.lineBreakMode = .byWordWrapping
                typingAttributes[.paragraphStyle] = paragraph
            case .normal(.link(let label, let node, _)):
                // FIXME: System and REXX links must be discarded in a sensible way
                // TODO: Register URL scheme
                typingAttributes[.link] = node
                let text = NSAttributedString(string: label, attributes: typingAttributes)
                textView.textStorage?.append(text)
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
                // Turn off word wrapping
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

    /// Retrieve MAIN node or, if not available, first node in document
    private func getMainNode() -> Node? {
        // FIXME: Main node can be both upper, lower and mixed case
        guard let first = nodeOrder.first else { return nil }
        return allNodes["MAIN"] ?? allNodes[first]
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        // FIXME: Handle links to other files: @{title link file/node [line]}
        print(#function, "\"\(link)\"", charIndex)
        guard let link = link as? String else { return false }
        if let node = allNodes[link] {
            present(node: node)
            return true // Stop next responder from handling link
        }
        let pathComponents = link.components(separatedBy: "/")
        guard
            pathComponents.count > 1,
            let node = pathComponents.last,
            !node.isEmpty
            else { return true }
        let filename = pathComponents[..<(pathComponents.endIndex-1)].joined(separator: "/")
        let url:URL// = URL(fileURLWithPath: filename)
        /*
        if #available(OSX 10.11, *) {
            url = URL(fileURLWithPath: filename,
                      relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
        } else {
            url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/" + filename)
        }
        */
        url = URL(fileURLWithPath: filename)
        print(url.absoluteString)
        openNewFile(from: url)
        return true
    }

    @IBAction func didSelectOpen(_ sender:NSMenuItem) {
        print(#function, sender)
        let dialogue = NSOpenPanel()
        dialogue.allowsMultipleSelection = false
        dialogue.canChooseDirectories = false
        dialogue.allowedFileTypes = ["guide"]
        guard dialogue.runModal() == .OK, let url = dialogue.url else { return }
        openNewFile(from: url)
    }
    
    override func pageDown(_ sender: Any?) {
        textView.pageDown(sender)
    }
    override func pageUp(_ sender: Any?) {
        textView.pageUp(sender)
    }
}

// MARK: - Navigation
extension ViewController: NavigationController {
    var canGoBack: Bool {
        // TODO: This should only be calculated when navigating between nodes
        // Alternative 1: The current node contains an explicit @PREV marker
        if let prev = precedingNode, let _ = allNodes[prev] {
            return true
        }
        // Alternative 2: Previous node is implicit, so check if not on the very first node in file
        if let currentNode = currentNode,
            let currentIndex = nodeOrder.index(of: currentNode),
            currentIndex > 0,
            let _ = allNodes[nodeOrder[currentIndex - 1]]{
            return true
        }
        return false
    }
    
    var canGoForward: Bool {
        if let _ = self.nextNode {
            return true
        }
        if let current = currentNode,
            let index = nodeOrder.index(of: current) {
            return index < nodeOrder.endIndex - 1
        }
        return false
    }
    
    var canRetrace: Bool {
        return navigationHistory.count > 1
    }
    
    var hasIndex: Bool {
        return tocNode != nil
    }
    
    func goBack() {
        print(#function, precedingNode ?? "")
        guard
            let prevNode = precedingNode,
            let prev = allNodes[prevNode] else {
                if let currentNode = currentNode,
                    let currentIndex = nodeOrder.index(of: currentNode),
                    1..<nodeOrder.endIndex ~= currentIndex,
                    let prev = allNodes[nodeOrder[currentIndex - 1]]{
                    parse(prev.contents, attributes: prev.typingAttributes)
                    //self.currentNode = prev.name
                    navigationHistory.append(prev)
                }
                return
        }
        /*
        parse(prev.contents, attributes: prev.typingAttributes)
        currentNode = prev.name
        navigationHistory.append(prev)
         */
        present(node: prev)
    }
    
    func goForward() {
        print(#function, nextNode ?? "not found")
        guard
            let nextNode = nextNode,
            let next = allNodes[nextNode]
            else {
                if let current = currentNode,
                    let index = nodeOrder.index(of: current),
                    index < nodeOrder.endIndex - 1,
                    let next = allNodes[nodeOrder[index + 1]] {
                    /*
                        parse(next.contents, attributes: next.typingAttributes)
                        currentNode = next.name
                        navigationHistory.append(next)
                     */
                        present(node: next)
                }
                return
        }
        /*
        parse(next.contents, attributes: next.typingAttributes)
        currentNode = next.name
        navigationHistory.append(next)
        */
        present(node: next)
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
        //currentNode = last.name
    }
    
    func goToMain() {
        guard let main = getMainNode() else { return }
        present(node: main)
    }
    
    func goToIndex() {
        guard let name = tocNode, let index = allNodes[name] else { return }
        present(node: index)
    }
    
}
