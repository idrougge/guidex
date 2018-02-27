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
        guard case AmigaGuide.TextTokens.link(let title, node: let node, line: _) = AmigaGuide.TextTokens.init("""
@{" Assignment and Copying " Link "Assignment and Copying"
""")! else {
    return XCTFail()
        }
        XCTAssert(node == "Assignment and Copying")
        XCTAssert(title == " Assignment and Copying ")
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
