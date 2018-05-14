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
        print(type(of: self), #function, window?.contentView?.subviews, window?.contentViewController is ViewController)
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        //self.window?.becomeFirstResponder()
        //window?.toolbar?.validateVisibleItems()
        navigationController = self.window?.contentViewController as? NavigationController
        
    }
    @IBAction func didPressPrevious(_ sender: Any) {
        print(#function)
    }
    override func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        print(#function, item, item.itemIdentifier)
        if item.itemIdentifier.rawValue == "left" {
            //item.isEnabled = false
            //return false
            item.isEnabled = navigationController?.canGoBack ?? false
        }
        return item.isEnabled
    }
}

class Toolbar: NSToolbar {
    override func validateVisibleItems() {
        print(#function)
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
