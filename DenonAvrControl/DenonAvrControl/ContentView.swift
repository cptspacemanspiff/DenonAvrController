//
//  ContentView.swift
//  DenonAvrControl
//
//  Created by Nicholas Long on 6/14/25.
//

import SwiftUI

struct ContentView: View {
    @State private var ipAddress: String = "192.168.1.100"
    var body: some View {
        VolumeView(ipAddress: $ipAddress)
    }
}

#Preview {
    ContentView()
}

