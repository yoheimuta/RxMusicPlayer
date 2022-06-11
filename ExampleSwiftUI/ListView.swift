//
//  ListView.swift
//  ExampleSwiftUI
//
//  Created by Yoheimuta on 2022/06/11.
//  Copyright © 2022 YOSHIMUTA YOHEI. All rights reserved.
//
// swiftlint:disable multiple_closures_with_trailing_closure no_space_in_method_call

import SwiftUI

struct LineView: View {
    let title: String

    var body: some View {
        Text("\(title)")
    }
}

struct ListView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    PlayerView()
                } label: {
                    LineView(title: "PlayerView1")
                }

                NavigationLink {
                    PlayerView()
                } label: {
                    LineView(title: "PlayerView2")
                }

                NavigationLink {
                    PlayerView()
                } label: {
                    LineView(title: "PlayerView3")
                }
            }
            .navigationTitle("PlayerList")
        }
        // This parameter is required
        // because the default NavigationView doesn't call the deinit of the PlayerModel right after popping the view.
        // See https://stackoverflow.com/questions/60129552/swiftui-navigationlink-memory-leak
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView()
    }
}
