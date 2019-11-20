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
    
    @IBAction func didPressSpace(_ sender:NSMenuItem) {
        self.contentViewController?.pageDown(sender)
    }
    
    @IBAction func didPressBackspace(_ sender:NSMenuItem) {
        self.contentViewController?.pageUp(sender)
    }
    
    override func keyUp(with event: NSEvent) {
        //print(#function, event, event.characters?.count, event.characters?.utf16)
        switch event.characters {
        case "<"?: self.didPressPrevious(event)
        case ">"?: self.didPressNext(event)
        default: return
        }
    }
}

extension WindowController: NSUserInterfaceValidations {
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if let item = item as? NSToolbarItem {
            return validateToolbarItem(item)
        }
        if let item = item as? NSMenuItem {
            return validateMenuItem(item)
        }
        return false
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        //print(#function, menuItem, menuItem.identifier, menuItem.identifier?.rawValue)
        let paths = ["left": \NavigationController.canGoBack,
                     "right": \NavigationController.canGoForward,
                     "retrace": \NavigationController.canRetrace,
                     "index": \NavigationController.hasIndex]
        guard
            let navigationController = navigationController,
            let identifier = menuItem.identifier?.rawValue,
            let path = paths[identifier] else { return true }
        return navigationController[keyPath: path]
    }
    
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
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
        return navigationController[keyPath: path]
    }
}

class Toolbar: NSToolbar {
    override func validateVisibleItems() {
        super.validateVisibleItems()
        for item in items {
            if item.target?.responds(to: #selector(NSUserInterfaceValidations.validateUserInterfaceItem)) == true {
                item.isEnabled = item.target?.validateUserInterfaceItem(item) ?? true
            }
        }
    }
}
