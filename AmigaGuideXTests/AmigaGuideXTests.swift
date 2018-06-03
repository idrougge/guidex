//
//  AmigaGuideXTests.swift
//  AmigaGuideXTests
//
//  Created by Iggy Drougge on 2017-10-10.
//  Copyright © 2017 Iggy Drougge. All rights reserved.
//

import XCTest
@testable import AmigaGuideX

class AmigaGuideXTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    func testNodeTokeniser() {
        
        guard case AmigaGuide.ToplevelTokens.node(let name, let title) = AmigaGuide.ToplevelTokens.init(str: "@{\"Hej\" link MAIN")! else {
            return XCTFail()
        }
 
        XCTAssert(name == "MAIN")
        XCTAssert(title == "Hej")
    }
    func testLinkTokeniser() {
        
        let linkExamples:[String] = """
        @{ " Amiga E " link amiga-e 
        @{ " Aztec C " link manx-c
        @{ " DICE C " link dice-c
        @{ " GNU C/C++ " link gnu-cpp
        @{ " SAS C 6.3 " link sas-c
        @{ " Maxon C++ V1.2.1 " link maxon-cpp
        @{ " Assemblers " link assemblers
        @{ " Other systems... " link other
        @{" Assignment and Copying " Link "Assignment and Copying"
        @{" Pointers and Memory Allocation " Link "Pointers and Memory Allocation"
        @{" String and List Misuse " Link "String and List Misuse"
        @{" Initialising Data " Link "Initialising Data"
        @{" Freeing Resources " Link "Freeing Resources"
        @{" Pointers and Dereferencing " Link "Pointers and Dereferencing"
        @{" Mathematics Functions " Link "Mathematics Functions"
        @{" Signed and Unsigned Values " Link "Signed and Unsigned Values"
        @{" A4 register " Link "MoreExpressions.guide/Things to watch out for"
        @{" A4 register " Link "MoreExpressions.guide/Things to watch out for" 11
        """.components(separatedBy: .newlines)
        let labels:[(String,String)] = [
        (" Amiga E ", "amiga-e"),
        (" Aztec C ", "manx-c"),
        (" DICE C ", "dice-c"),
        (" GNU C/C++ ", "gnu-cpp"),
        (" SAS C 6.3 ", "sas-c"),
        (" Maxon C++ V1.2.1 ", "maxon-cpp"),
        (" Assemblers ", "assemblers"),
        (" Other systems... ", "other"),
        (" Assignment and Copying ", "Assignment and Copying"),
        (" Pointers and Memory Allocation ", "Pointers and Memory Allocation"),
        (" String and List Misuse ", "String and List Misuse"),
        (" Initialising Data ", "Initialising Data"),
        (" Freeing Resources ", "Freeing Resources"),
        (" Pointers and Dereferencing ", "Pointers and Dereferencing"),
        (" Mathematics Functions ", "Mathematics Functions"),
        (" Signed and Unsigned Values ", "Signed and Unsigned Values"),
        (" A4 register ", "MoreExpressions.guide/Things to watch out for"),
        (" A4 register ", "MoreExpressions.guide/Things to watch out for"),
        ]
        for (nr,(line,(label,nodename))) in zip(linkExamples,labels).enumerated() {
            print(nr, line)
            guard let token = AmigaGuide.TextTokens.init(line) else { return XCTFail(line) }
            guard case let AmigaGuide.TextTokens.link(title, node: node, line: _) = token else {return XCTFail() }
            XCTAssert(node == nodename, "'\(node)' <> '\(nodename)'")
            XCTAssert(title == label)
        }
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
