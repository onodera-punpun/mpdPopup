//
//  PopoverView.swift
//  mpdPopup
//
//  Created by Camille Scholtz on 10/01/2021.
//

import SwiftUI
import VisualEffects

// https://fivestars.blog/swiftui/swiftui-share-layout-information.html
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

struct PopoverView: View {
    @State private var height = CGFloat.infinity

    var body: some View {
        ZStack {
            Cover()
            Toggle()
        }
        .mask(
            RadialGradient(
                gradient: Gradient(colors: [.clear, .white]),
                center: .top,
                startRadius: 5,
                endRadius: 50
            )
            .scaleEffect(x: 1.5)
        )
        .frame(
            maxWidth: 250,
            maxHeight: height
        )
        .onPreferenceChange(HeightPreferenceKey.self) { v in
            height = v
        }
    }
}

struct Cover: View {
    @EnvironmentObject var song: Song

    @AppStorage(Setting.directory) var directory = FileManager.default.homeDirectoryForCurrentUser.path
    
    var body: some View {
        Image(nsImage: getCover(uri: song.location))
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 250)
            .background(
                GeometryReader { v in
                    Color.clear
                        .preference(key: HeightPreferenceKey.self, value: v.size.height)
                }
            )
    }

    // TODO: This will always, even when the popover is closed, load an image.
    func getCover(uri: String) -> NSImage {
        let basename = URL(fileURLWithPath: directory)
            .appendingPathComponent(uri)
            .deletingLastPathComponent()

        for location in [
            basename.appendingPathComponent("cover.jpg"),
            basename.appendingPathComponent("cover.png")
        ] {
            if FileManager().fileExists(atPath: location.path) {
                return NSImage(byReferencing: location)
            }
        }

        // TODO: Fallback image
        return NSImage(byReferencing: basename.appendingPathComponent("cover.jpg"))
    }
}

struct Toggle: View {
    @EnvironmentObject var status: Status

    @State private var visible = false

    var body: some View {
        Image(systemName: status.state + ".circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 35)
            .foregroundColor(.white)
            .background(
                VisualEffectBlur(
                    material: .hudWindow,
                    blendingMode: .withinWindow,
                    state: .active
                )
                .frame(width: 85, height: 85)
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 40
                )
                .cornerRadius(10)
            )
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.9)
            .animation(.easeInOut)
            .onReceive(status.$state, perform: { v in
                if v == "pause" {
                    visible = true
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if status.state == "pause" {
                        return
                    }
                    visible = false
                }
            })
    }
}

