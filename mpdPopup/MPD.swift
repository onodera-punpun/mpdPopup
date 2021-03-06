//
//  Song.swift
//  mpdPopup
//
//  Created by Camille Scholtz on 13/01/2021.
//

import libmpdclient
import SwiftUI

class MPD {
    var song = Song()
    var status = Status()
    
    @AppStorage(Setting.host) var host = "localhost"
    @AppStorage(Setting.port) var port = 6600

    private var conn: OpaquePointer?
    
    init(statusItem: NSStatusItem, popover: NSPopover) {
        self.conn = mpd_connection_new(self.host, UInt32(self.port), 30000)
        
        self.song.conn = self.conn
        self.status.conn = self.conn
                
        DispatchQueue(label: "MPD").async {
            while true {
                // Make sure we are still connected, if not, reconnect.
                if mpd_connection_get_error(self.conn) != MPD_ERROR_SUCCESS {
                    self.conn = mpd_connection_new(self.host, UInt32(self.port), 30000)
                    
                    // Sleep in order to prevent a super fast loop on sustained disconnection.
                    if mpd_connection_get_error(self.conn) != MPD_ERROR_SUCCESS {
                        sleep(5)
                        continue
                    }
                }
                
                DispatchQueue.main.sync {
                    self.song.set()
                    self.status.set()
                    
                    // XXX: Image is not really aligned with the text.
                    //statusItem.button?.image = NSImage(systemSymbolName: self.status.state, accessibilityDescription: self.status.state)
                    statusItem.button?.title = "\(self.song.artist ?? "?") - \(self.song.title ?? "?")"
                }
                
                // This blocks the loop.
                if mpd_run_idle_mask(self.conn, MPD_IDLE_PLAYER) == mpd_idle(0) {
                    continue
                }
            }
        }
    }

    func command(_ name: String) {
        // XXX: Not sure why this is needed, but using the existing `conn` breaks the idle loop.
        let tmp = mpd_connection_new(host, UInt32(port), 1000)
        if mpd_connection_get_error(tmp) != MPD_ERROR_SUCCESS {
            return
        }
        
        switch name {
        case "toggle":
            mpd_run_pause(tmp, status.state == "play")
        case "previous":
            mpd_run_previous(conn)
        case "next":
            mpd_run_next(conn)
        default: break
        }
        
        mpd_connection_free(tmp)
    }
}

class Song: ObservableObject {
    var conn: OpaquePointer?

    @Published var location: String?
    @Published var artist: String?
    @Published var title: String?
    @Published var duration: UInt32?
    
    func set() {
        if let recvSong = mpd_run_current_song(conn) {
            // We first check if the new values differ from the old ones, if this is not the case we don't set them in order not to fire a published event.
            // XXX: I tried "smart ways" of assigning these values without taking up 4 lines, though these methods don't seem to work.
            
            let newLocation = String(cString: mpd_song_get_uri(recvSong))
            if location != newLocation {
                location = newLocation
            }
            
            let newArtist = mpd_song_get_tag(recvSong, MPD_TAG_ARTIST, 0)
            if newArtist != nil && artist != String(cString: newArtist!) {
                artist = String(cString: newArtist!)
            }
            
            let newTitle = mpd_song_get_tag(recvSong, MPD_TAG_TITLE, 0)
            if newTitle != nil && title != String(cString: newTitle!) {
                title = String(cString: newTitle!)
            }
            
            let newDuration = mpd_song_get_duration(recvSong)
            if duration != newDuration {
                duration = newDuration
            }
    
            mpd_song_free(recvSong)
        }
    }
}

class Status: ObservableObject {
    var conn: OpaquePointer?

    @Published var state: String?
    @Published var elapsed: UInt32?
    
    func set() {
        if let recvStatus = mpd_run_status(conn) {
            // We first check if the new values differ from the old ones, if this is not the case we don't set them in order not to fire a published event.
            // XXX: I tried "smart ways" of assigning these values without taking up 4 lines, though these methods don't seem to work.

            let newState = mpd_status_get_state(recvStatus) == MPD_STATE_PLAY ? "play" : "pause"
            if state != newState {
                state = newState
            }
            
            let newElapsed = mpd_status_get_elapsed_time(recvStatus)
            if elapsed != newElapsed {
                elapsed = newElapsed
            }
            
            mpd_status_free(recvStatus)
        }
    }
}

// XXX: This function does not work, because it seems like inout always modifies the value, still triggering published.
/*func assign<T: Comparable>(target: inout T, value: T) {
    if target != value {
        target = value
    }
}*/
