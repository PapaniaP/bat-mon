//
//  BatMonWidgetBundle.swift
//  BatMonWidget
//
//  Widget bundle containing all BatMon widgets
//

import WidgetKit
import SwiftUI

@main
struct BatMonWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Rich style widget (modern look with bars and gauges)
        RichBatteryWidget()

        // TUI style widget (terminal aesthetic with ASCII bars)
        TUIBatteryWidget()
    }
}
