//
//  ScrollableNavBarView.swift
//  PagerTabStripView
//
//  Created by Cecilia Pirotto on 23/8/21.
//

import Foundation
import SwiftUI

internal struct ScrollableNavBarView: View {
    @Binding private var selection: Int

    @EnvironmentObject private var dataStore: DataStore

    public init(selection: Binding<Int>) {
        self._selection = selection
    }

    var body: some View {
        ScrollViewReader { value in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack {
                    IndicatorScrollableBarView(selection: $selection)
                    HStack(spacing: style.tabItemSpacing) {
                        if dataStore.itemsCount > 0 {
                            ForEach(0..<dataStore.itemsCount, id: \.self) { idx in
                                NavBarItem(id: idx, selection: $selection)
                            }
                        }
                    }
                }
                .frame(height: self.style.tabItemHeight)
                .padding(.leading, 8)
                .padding(.trailing, 8)
            }
            .padding(self.style.padding)
            .onChange(of: self.selection) { newSelection in
                withAnimation {
                    value.scrollTo(newSelection, anchor: .center)
                }
            }
        }
        .background(self.style.navBarBackground)
    }

    @Environment(\.pagerStyle) var style: PagerStyle
    @EnvironmentObject private var settings: PagerSettings
}

internal struct IndicatorScrollableBarView: View {
    @EnvironmentObject private var dataStore: DataStore
    @Binding private var selection: Int
    @State private var position: Double = 0
    @State private var selectedItemWidth: Double = 0
    @State private var appeared: Bool = false

    public init(selection: Binding<Int>) {
        self._selection = selection
    }

    var body: some View {
        Capsule()
            .fill(style.indicatorBarColor)
            .animation(.default, value: appeared)
            .frame(width: selectedItemWidth + 16, height: style.indicatorBarHeight)
            .position(x: position, y: style.tabItemHeight / 2)
            .onAppear {
                appeared = true
            }
            .onChange(of: dataStore.widthUpdated) { updated in
                if updated {
                    let items = dataStore.items.filter { index, _ in
                        index < selection
                    }
                    selectedItemWidth = dataStore.items[selection]?.itemWidth ?? 0
                    var newPosition = items.map({return $0.value.itemWidth ?? 0}).reduce(0, +)
                    newPosition += (style.tabItemSpacing * CGFloat(selection)) + selectedItemWidth/2
                    position = newPosition
                }
            }
            .onChange(of: settings.contentOffset) { newValue in
                let offset = newValue + (settings.width * CGFloat(selection))
                let percentage = offset / settings.width
                let items = dataStore.items.filter { index, _ in
                    index < selection
                }

                let spaces = style.tabItemSpacing * CGFloat(selection-1)
                let actualWidth = dataStore.items[selection]?.itemWidth ?? 0
                var lastPosition = items.map({return $0.value.itemWidth ?? 0}).reduce(0, +)
                lastPosition += spaces + actualWidth/2
                var nextPosition = items.map({return $0.value.itemWidth ?? 0}).reduce(0, +)
                if percentage == 0 {
                    selectedItemWidth = dataStore.items[selection]?.itemWidth ?? 0
                    var newPosition = items.map({return $0.value.itemWidth ?? 0}).reduce(0, +)
                    newPosition += style.tabItemSpacing * CGFloat(selection) + selectedItemWidth/2
                    position = newPosition
                } else {
                    if percentage < 0 {
                        nextPosition += actualWidth + style.tabItemSpacing * CGFloat(selection+1)
                        nextPosition += ((dataStore.items[selection + 1])?.itemWidth ?? 0)/2
                    } else {
                        nextPosition += style.tabItemSpacing * CGFloat(selection-1)
                        nextPosition -= ((dataStore.items[selection - 1])?.itemWidth ?? 0)/2
                    }
                    position = lastPosition + (nextPosition - lastPosition)*abs(percentage)

                    if let selectedWidth = dataStore.items[selection]?.itemWidth,
                        let nextWidth = percentage > 0 ? dataStore.items[selection-1]?.itemWidth : dataStore.items[selection+1]?.itemWidth,
                        abs(percentage)>0 {
                        selectedItemWidth = selectedWidth - (selectedWidth-nextWidth)*abs(percentage)
                    }
                }

            }
            .onChange(of: selection) { newValue in
                let items = dataStore.items.filter { index, _ in
                    index < newValue
                }
                selectedItemWidth = dataStore.items[newValue]?.itemWidth ?? 0
                var newPosition = items.map({return $0.value.itemWidth ?? 0}).reduce(0, +)
                newPosition += (style.tabItemSpacing * CGFloat(newValue)) + selectedItemWidth/2
                position = newPosition
            }
        }

    @Environment(\.pagerStyle) var style: PagerStyle
    @EnvironmentObject private var settings: PagerSettings
}
