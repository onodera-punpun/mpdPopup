//
//  mpdPopupApp.swift
//  mpdPopup
//
//  Created by Camille Scholtz on 10/01/2021.
//

import SwiftUI

@main
struct mpdPopupApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
    
class AppDelegate: NSObject, NSApplicationDelegate {
    private var mpd: MPD?

    private var statusItem: NSStatusItem?
    private var popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let bookmarks = UserDefaults.standard.object(forKey: "bookmark") as! Data
            var stale = false
            let url = try URL(
                resolvingBookmarkData: bookmarks as Data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )
            _ = url.startAccessingSecurityScopedResource()
        } catch {
            // TODO
            return
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.action = #selector(buttonAction(_:))
        statusItem?.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
        statusItem?.button?.title = "MPD: connection refused"
        // XXX: Image is not really aligned with the text.
        //statusItem?.button?.imagePosition = .imageLeading
        
        mpd = MPD(
            statusItem: statusItem!,
            popover: popover
        )
        
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(
            rootView: PopoverView()
                .environmentObject(mpd!.song)
                .environmentObject(mpd!.status)
        )
    }
    
    @objc func buttonAction(_ sender: NSStatusBarButton?) {
        guard let event = NSApp.currentEvent else {
            return
        }

        //TODO: `case .scrollWheel` doesn't work.
        switch event.type {
        case .rightMouseDown:
            mpd!.command("toggle")
        default:
            togglePopover(sender)
        }
    }


    func togglePopover(_ sender: NSStatusBarButton?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(
                relativeTo: sender!.bounds,
                of: sender!,
                preferredEdge: NSRectEdge.minY
            )
        }
    }
}
