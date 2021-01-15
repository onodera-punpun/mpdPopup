//
//  Song.swift
//  mpdPopup
//
//  Created by Camille Scholtz on 13/01/2021.
//

import libmpdclient
import SwiftUI

// TODO: Make a menubar parent view which includes menubar stuff.
//
// Menubar depends on Song
// Menubar depends on App
// Popover depends on Song
//
// Now: App -> [Statusbar, Popover -> [Song]]
//
//

class Song: ObservableObject {
    @Published var location: String = "."
    @Published var status:   String = "?"
    @Published var artist:   String = "?"
    @Published var title:    String = "?"
    @Published var elapsed:  UInt32 = 0
    @Published var duration: UInt32 = 0

    @AppStorage(Setting.host) var host = "localhost"
    @AppStorage(Setting.port) var port = 6600

    var statusItem: NSStatusItem
    var popover:    NSPopover
    
    private var conn: OpaquePointer?

    init(statusItem: NSStatusItem, popover: NSPopover) {
        self.statusItem = statusItem
        self.popover    = popover

        // Set up connection to mpd using the host and port defined in the settings.
        self.conn = mpd_connection_new(host, UInt32(port), 10000)
        
        DispatchQueue(label: "MPD").async {
            repeat {
                // Make sure we are still connected, if not, reconnect.
                if mpd_connection_get_error(self.conn) != MPD_ERROR_SUCCESS {
                    self.conn = mpd_connection_new(self.host, UInt32(self.port), 10000)
                    
                    // Sleep for a few seconds to prevent a super fast loop on sustained disconnection.
                    if mpd_connection_get_error(self.conn) != MPD_ERROR_SUCCESS {
                        sleep(5)
                        continue;
                    }
                }
                
                DispatchQueue.main.sync {
                    self.set()
                    
                    // TODO: Kind of a hacky solution, but there seems to be no better possible way.
                    self.statusItem.button?.title = "\(self.artist) - \(self.title)"
                }
            } while mpd_run_idle_mask(self.conn, MPD_IDLE_PLAYER) == MPD_IDLE_PLAYER
        }
    }
    
    func set() {
        mpd_command_list_begin(conn, true)
        mpd_send_status(conn)
        mpd_send_current_song(conn)
        mpd_command_list_end(conn)
        
        let recvStatus = mpd_recv_status(conn)
        if recvStatus != nil {
            status  = mpd_status_get_state(recvStatus) == MPD_STATE_PLAY ? "play" : "pause"
            elapsed = mpd_status_get_elapsed_time(recvStatus)
        }
        mpd_status_free(recvStatus)

        mpd_response_next(conn)

        let recvSong = mpd_recv_song(conn)
        if recvSong != nil {
            location = String(cString: mpd_song_get_uri(recvSong))
            artist   = String(cString: mpd_song_get_tag(recvSong, MPD_TAG_ARTIST, 0)) // TODO: This can be nil.
            title    = String(cString: mpd_song_get_tag(recvSong, MPD_TAG_TITLE, 0))  // TODO: This can be nil.
            duration = mpd_song_get_duration(recvSong)
        }
        mpd_song_free(recvSong)

        mpd_response_finish(conn)
    }
}
