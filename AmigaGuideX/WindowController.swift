//
//  WindowController.swift
//  AmigaGuideX
//
//  Created by Iggy Drougge on 2018-04-22.
//  Copyright © 2018 Iggy Drougge. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    var navigationController: NavigationController?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        //self.window?.becomeFirstResponder()
        //window?.toolbar?.validateVisibleItems()
        navigationController = self.window?.contentViewController as? NavigationController
        
    }
    @IBAction func didPressPrevious(_ sender: Any) {
        print(#function)
        if navigationController?.canGoBack == true {
            navigationController?.goBack()
        }
    }
    
    @IBAction func didPressNext(_ sender: Any) {
        print(#function)
        navigationController?.goForward()
    }
    
    @IBAction func didPressRetrace(_ sender: Any) {
        print(#function)
        navigationController?.retrace()
    }
    
    @IBAction func didPressContents(_ sender: Any) {
        print(#function)
        navigationController?.goToMain()
    }
    
    @IBAction func didPressIndex(_ sender: Any) {
        print(#function)
        navigationController?.goToIndex()
    }
    override func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        //print(#function, item, item.itemIdentifier)
        let paths = ["left": \NavigationController.canGoBack,
                     "right": \NavigationController.canGoForward,
                     "retrace": \NavigationController.canRetrace,
                     "index": \NavigationController.hasIndex]
        guard
            let navigationController = navigationController,
            let path = paths[item.itemIdentifier.rawValue]
            else {
                return item.isEnabled
        }
        item.isEnabled = navigationController[keyPath: path]
        return item.isEnabled
    }
}

class Toolbar: NSToolbar {
    override func validateVisibleItems() {
        //print(#function)
        for item in items {
            var responder = item.view?.nextResponder
            while responder != nil {
                responder = responder?.nextResponder
                if responder?.responds(to: #selector(validateToolbarItem(_:))) ?? false {
                    //print("RESPONDS")
                    responder?.validateToolbarItem(item)
                }
            }
            //item.view?.nextResponder?.validateToolbarItem(item)
            //self.validateToolbarItem(item)
        }
    }
}
