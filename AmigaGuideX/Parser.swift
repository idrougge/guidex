//
//  Parser.swift
//  AmigaGuideX
//
//  Created by Iggy Drougge on 2017-10-10.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//
import Foundation

struct AmigaGuide {
    indirect enum Tokens {
        case global(ToplevelTokens)
        case normal(TextTokens)
        case plaintext(String)
        case escaped(String)
        case newline // Also Texttokens.linebreak
        case node(name:String, title:String?, contents:[Tokens])
    }
    enum ToplevelTokens {
        case database(String)   // name of DATABASE
        case node(String,String?) // NODE has nodename and optional headline
        case endnode
        case prev(String) // PREV has pointer to next nodename
        case next(String) // NEXT has pointer to next nodename
        case index(String) // Name of node to show when Index button is pressed
        indirect case node_(name:String, headline: String?, next:ToplevelTokens?, prev:ToplevelTokens?, contents:[AmigaGuide.Tokens])
        case title(String)
        case wordwrap
        case smartwrap
        case tab(Int)
        case font(name:String, size:Int)
        case author(String)
        case version(String)
        case copyright(String)
        case remark(String)
        case help(String) // Node for "help" button
        
        init?(str:String) {
            guard let str = str.splitFirstWord() else { return nil }
            switch str.pre.lowercased() {
            // FIXME: Node names can be enclosed by parentheses and containing whitespace
            case "node":
                guard let rest = str.rest else { return nil }

                let regex = try! NSRegularExpression(pattern: "^\"?([^\"]+)\"?(?:\\s\"?([^\"]+)\"?)?\\s*$", options: [])
                guard
                    let match = regex.firstMatch(in: rest,
                                                 options: .anchored,
                                                 range: NSRange(rest.startIndex..., in: rest))
                    else {
                        assertionFailure()
                        return nil
                }
                assert(match.numberOfRanges == 3)
                /*
                for i in 0..<match.numberOfRanges {
                    guard let range = Range(match.range(at: i), in: rest) else { continue }
                    print("\(i):", String(rest[Range(match.range(at: i), in: rest)!]))
                }
                 */
                let name = String(rest[Range(match.range(at: 1), in: rest)!])
                var title:String?
                if let range = Range(match.range(at: 2), in: rest) {
                    title = String(rest[range])
                }
                self = .node(name, title)
                //guard let split = str.rest?.splitFirstWord() else { return nil }
                //self = .node(split.pre, split.rest)
            case "endnode": self = .endnode
            case "wordwrap": self = .wordwrap
            case "smartwrap": self = .smartwrap
            case "tab":
                guard let rest = str.rest, let tabsize = Int(rest) else { return nil }
                self = .tab(tabsize)
            case "author": self = .author(str.rest ?? "")
            case "database": self = .database(str.rest ?? "")
            case "$ver:": self = .version(str.rest ?? "")
            case "(c)": self = .copyright(str.rest ?? "")
            case "next":
                guard let node = str.rest else { return nil }
                self = .next(node)
            case "prev":
                guard let node = str.rest else { return nil }
                self = .prev(node)
            case "title":
                // FIXME: Quote marks must be removed from title
                guard let title = str.rest else { return nil }
                self = .title(title)
            case "rem":
                self = .remark(str.rest ?? "")
            case "help":
                guard let node = str.rest else { return nil }
                self = .help(node)
            case "index":
                guard let node = str.rest else { return nil }
                self = .index(node)
            default: return nil
            }
        }
    }
    enum TextTokens {
        case amigaguide // Prints out "AmigaGuide®"
        case apen(Int) // Foreground colour pen
        case bpen(Int) // Background colour pen
        case body // Restore text formatting
        case bold // {b} = bold text, terminated by @{ub}
        case nobold
        case background(String) // Background colour
        case beep(String)
        case cleartabs
        case close(String) // Action when closing doc
        case code
        case foreground(String) // Foreground colour
        case guide(String) // Link to another Amigaguide document
        case italic // {i} = italic text, terminated by @{ui}
        case noitalic
        case jcenter
        case jleft
        case jright
        case lindent(Int) // Indentation level (in spaces) from next line
        case linebreak // Line break
        case link(label:String,node:String,line:Int?) // Link to another file
        case par // Two linebreaks (new paragraph)
        case pard // Default paragraph formatting
        case pari(Int) // Indentation (in spaces) for first line of paragraphs
        case plain // Restore text formatting
        case settabs([Int])
        case system(path:String) // Execute command
        case quit(label:String)
        case tab
        case underline // {u} = underline, terminated by @{ub}
        case nounderline
        
        init?(_ str:String) {
            guard let tok = str.splitFirstWord() else { return nil }
            switch tok.pre.lowercased() {
            case "@{b": self = .bold
            case "@{ub": self = .nobold
            case "@{i": self = .italic
            case "@{ui": self = .noitalic
            case "@{u": self = .underline
            case "@{uu": self = .nounderline
            case "@{amigaguide": self = .amigaguide
            case "@{cleartabs": self = .cleartabs
            case "@{code": self = .code
            case "@{jcenter": self = .jcenter
            case "@{jleft": self = .jleft
            case "@{jright": self = .jright
            case "@{line": self = .linebreak
            case "@{par": self = .par
            case "@{pard": self = .pard
            case "@{plain": self = .plain
            default:
                switch (tok.pre, tok.rest) {
                case ("@{bg",let pen?): self = .background(pen)
                case ("@{fg",let pen?): self = .foreground(pen)
                case ("@{lindent", let size?): self = .lindent(Int(size) ?? 0)
                case ("@{pari", let size?): self = .pari(Int(size) ?? 0)
                case ("@{settabs", let sizes?): let sizes = sizes.components(separatedBy: .whitespaces).compactMap(Int.init)
                self = .settabs(sizes)
                case ("@{", _?): // Sometimes links have a space after opening brace
                    fallthrough
                case ("@{\"", _?),
                     (_, _) where str.starts(with: "@{\""):
                    // FIXME: Links can point to other files: @{title link file/node}
                    let pattern = "^@\\{\\s*\\\"?((?<=\\\")(?:.*)(?=\\\")|(?<!\\\")(?:\\S+)(?!\\\"))\\\"?\\s+(\\w+)\\s+\\\"?((?<=\\\")(?:.*)(?=\\\")|(?<!\\\")(?:\\S+)(?!\\\"))\\\"?\\s*$"
                    guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
                        let match = regex.firstMatch(in: str, options: .anchored, range: NSRange(str.startIndex..., in: str)),
                        match.numberOfRanges == 4
                        else { return nil }
                    let label = String(str[Range(match.range(at: 1), in: str)!])
                    // FIXME: Handle System and REXX links by not handling them
                    let _ = String(str[Range(match.range(at: 2), in: str)!]) // Type of link
                    let node = String(str[Range(match.range(at: 3), in: str)!])
                    self = .link(label: label, node: node, line: nil)
                default:
                    print(tok.pre)
                    assertionFailure("\(tok.pre), \(tok.rest ?? "nil")")
                    return nil
                }
            }
        }
    }
}

class Parser {

    private(set) var parseResult:[AmigaGuide.Tokens] = []
    
    init(file:String) {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() + file)
        // Brute-forcing because this init is only used for debug purposes
        let fileContents = try! String(contentsOf: fileURL, encoding: .isoLatin1)
        parseFile(fileContents)
    }
    
    init(file url:URL) throws {
        let fileContents = try String(contentsOf: url, encoding: .isoLatin1)
        parseFile(fileContents)
    }
    
    private func parseFile(_ contents:String) {
        var start = contents.startIndex
        while start < contents.endIndex {
            let (t, pos):(AmigaGuide.Tokens?, String.Index) = getTokens(contents, from: start)
            if let token = t {
                parseResult.append(token)
            }
            start = pos
        }
    }
    private func getTokens(_ contents:String, from:String.Index) -> (AmigaGuide.Tokens?, String.Index) {
        let contents_copy = contents
        let contents = contents[from...]
        //print(#function, from, String(contents))
        guard from < contents.endIndex else { return (nil, from) }
        guard let mark = contents.firstIndex(of: "@") else {
            let text = String(contents[from...])
            let token = AmigaGuide.Tokens.plaintext(text)
            return (token, contents.endIndex) /* return rest of contents */
        }
        guard mark == from else {
            // FIXME: Should ignore outside of nodes
            let text = String(contents[from ..< mark])
            let token = AmigaGuide.Tokens.plaintext(text)
            return (token, mark) // return token and mark as new starting position
        }
        //print(#function, from, String(contents))
        switch contents[contents.index(after: mark)] {
        case "{":
            guard let endmark = contents.firstIndex(of: "}") else { fatalError() }
            let text = contents[mark ..< endmark]
            if let token = AmigaGuide.TextTokens(String(text)) {
                let token = AmigaGuide.Tokens.normal(token)
                let next = contents.index(after: endmark)
                return (token,next)
            }
            return (nil, endmark)
        default:
            guard let endofline = contents.firstIndex(of: "\n") else {
                return (nil,contents.endIndex)
            }
            let start = contents.index(after: mark)
            let text = contents[start ..< endofline]
            let from = contents.index(after: endofline)
            if text.lowercased().starts(with: "node"), let node = AmigaGuide.ToplevelTokens(str: String(text)), case let AmigaGuide.ToplevelTokens.node(name, title) = node {
                //print("Text starts with 'node' and is node \(node)")
                var pos = from
                //var (_,p) = getTokens(contents_copy, from: from)
                var arr = [AmigaGuide.Tokens]()
                repeat {
                    let (t,p) = getTokens(contents_copy, from: pos)
                    pos = p
                    if let t = t {
                        arr.append(t)
                        // TODO: Scan for @TITLE tag and insert into node
                        if case AmigaGuide.Tokens.global(.endnode) = t {
                            // End of node found, return node token with contents
                            let n = AmigaGuide.Tokens.node(name: name, title: title, contents: arr)
                            return (n,p)
                        }
                    }
                } while true //p > from
            }
            if let token = AmigaGuide.ToplevelTokens(str: String(text)) {
                let token = AmigaGuide.Tokens.global(token)
                return (token, from)
            }
            return (nil, from)
        }
    }
    private func unescape(_ line:String) -> String {
        if let backslash = line.firstIndex(of: "\\") {
            let escaped = line.index(after: backslash)
            return line + unescape(String(line[escaped...]))
        }
        return line
    }
}

