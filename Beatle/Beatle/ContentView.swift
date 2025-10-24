//
//  ContentView.swift
//  Beatle
//
//  Created by Sam Missing on 23/10/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()
            MPCPad(size: 156, accent: Color(hex: "#EC2F3B")) // crimson halo; try T.teal later
            Spacer()
        }
        .padding(24)
        .beatleRootBackground()
        .useBeatleTheme()
    }
}

#Preview("Light") { ContentView().preferredColorScheme(.light) }
#Preview("Dark")  { ContentView().preferredColorScheme(.dark) }

