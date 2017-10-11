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
        case newline // Motsvaras även av Texttokens.linebreak
        // Här borde finnas ett case node([Tokens])
        case bla(Tokens)
    }
    enum ToplevelTokens {
        case database(String)   // name of DATABASE
        case node(String,String?) // NODE has nodename and optional headline
        case endnode
        case prev(String) // PREV has pointer to next nodename
        case next(String) // NEXT has pointer to next nodename
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
            case "node": // Node borde peka på ett abstrakt node-case
                guard let split = str.rest?.splitFirstWord() else { return nil }
                self = .node(split.pre, split.rest)
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
                guard let title = str.rest else { return nil }
                self = .title(title)
            case "rem":
                self = .remark(str.rest ?? "")
            case "help":
                guard let node = str.rest else { return nil }
                self = .help(node)
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
            case "b": self = .bold
            case "ub": self = .nobold
            case "i": self = .italic
            case "ui": self = .noitalic
            case "u": self = .underline
            case "uu": self = .nounderline
            case "amigaguide": self = .amigaguide
            case "cleartabs": self = .cleartabs
            case "code": self = .code
            case "jcenter": self = .jcenter
            case "jleft": self = .jleft
            case "jright": self = .jright
            case "line": self = .linebreak
            case "par": self = .par
            case "pard": self = .pard
            case "plain": self = .plain
            default:
                switch (tok.pre, tok.rest) {
                case ("bg",let pen?): self = .background(pen)
                case ("fg",let pen?): self = .foreground(pen)
                case ("lindent", let size?): self = .lindent(Int(size) ?? 0)
                case ("pari", let size?): self = .pari(Int(size) ?? 0)
                case ("settabs", let sizes?): let sizes = sizes.components(separatedBy: .whitespaces).flatMap(Int.init)
                self = .settabs(sizes)
                case ("\"", _?):
                    guard let regex = try? NSRegularExpression(pattern: "^\"(.+)\"\\s(.+)\\s\\\"(.+)\\\"", options: []),
                        let match = regex.firstMatch(in: str, options: .anchored, range: NSRange(str.startIndex..., in: str)),
                        match.numberOfRanges == 4
                        else { return nil }
                    let label = String(str[Range(match.range(at: 1), in: str)!])
                    let _ = String(str[Range(match.range(at: 2), in: str)!]) // Type of link
                    let node = String(str[Range(match.range(at: 3), in: str)!])
                    self = .link(label: label, node: node, line: nil)
                default:
                    print(tok.pre)
                    fatalError("\(tok.pre), \(tok.rest ?? "nil")")
                    return nil
                }
            }
        }
    }
}

class Parser {

    var parseResult:[AmigaGuide.Tokens] = []
    
    init(file:String) {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() + file)
        print("NSHomeDirectory()",NSHomeDirectory())
        
        let fileString = try! String(contentsOf: fileURL, encoding: .isoLatin1)
        let lines = fileString.components(separatedBy: .newlines)
        for line in lines {
            parseAppend(line)
        }
    }
    
    func parseAppend(_ line:String) {
        if let backslash = line.index(of: "\\") {
            parseAppend(String(line[..<backslash]))
            let escaped = line.index(after: backslash)
            parseResult.append(.escaped(String(line[escaped])))
            parseAppend(String(line[line.index(after: escaped)...]))
            //fatalError("Hittade escapetecken: "+line)
            return
        }
        guard let at = line.index(of: "@") else {
            parseResult.append( .plaintext(line) )
            parseResult.append( .newline )
            return
        }
        if at > line.startIndex {
            parseResult.append(.plaintext(String(line[..<at])))
        }
        if at == line.index(before: line.endIndex) {
            fatalError(line)
        }
        let opening = line.index(after: at)
        guard line[opening] == "{", let closing = line[opening...].index(of: "}") else {
            if let token = AmigaGuide.ToplevelTokens(str: String(line[opening...])) {
                parseResult.append( AmigaGuide.Tokens.global(token) )
            } else {
                parseResult.append( AmigaGuide.Tokens.plaintext(line) )
            }
            return
        }
        let tokstr = line[line.index(after: opening) ..< closing]
        if let token = AmigaGuide.TextTokens(String(tokstr)) {
            print(token)
            parseResult.append(.normal(token))
        }
        let theRest = line[line.index(after: closing)...]
        print(theRest)
        parseAppend(String(theRest))
    }
}

