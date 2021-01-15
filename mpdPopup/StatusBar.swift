//
//  StatusBar.swift
//  mpdPopup
//
//  Created by Camille Scholtz on 15/01/2021.
//

import SwiftUI

class StatusBar: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover = NSPopover.init()
    
    init() {
        statusItem                 = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.action = #selector(AppDelegate.togglePopover(_:))
        
        popover.behavior                    = .transient
        popover.contentViewController       = NSViewController()
        popover.contentViewController?.view = NSHostingView(
            rootView: PopoverView(
                song: Song(
                    statusItem: statusItem!,
                    popover:    popover
                )
            )
        )
    }
    
    @objc func showPopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            popover.show(
                relativeTo:    button.bounds,
                of:            button,
                preferredEdge: NSRectEdge.minY
            )
        }
    }
    
    @objc func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
}
