//
//  SettingsView.swift
//  mpdPopup
//
//  Created by Camille Scholtz on 10/01/2021.
//

import SwiftUI

enum Setting {
    static let host      = "host"
    static let port      = "port"
    static let directory = "directory"
}

struct SettingsView: View {
    @AppStorage(Setting.host)      var host      = "localhost"
    @AppStorage(Setting.port)      var port      = 6600
    @AppStorage(Setting.directory) var directory = FileManager.default.homeDirectoryForCurrentUser.path

    var body: some View {
        Form {
            HStack{
                TextField("MPD host", text: $host)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("MPD port", value: $port, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            HStack{
                TextField("Enter save path", text: $directory)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Music folder") {
                    let panel                  = NSOpenPanel()
                    panel.title                = "Select music folder"
                    panel.canChooseDirectories = true
                    panel.canChooseFiles       = false
                    
                    if panel.runModal() == .OK {
                        let result = panel.url
                        if (result != nil) {
                            directory = result!.path
                        }
                    }
                }
            }
        }
            .padding(80)
            .frame(width: 400, height: 125)
    }
}
