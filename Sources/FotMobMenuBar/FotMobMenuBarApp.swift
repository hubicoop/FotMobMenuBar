import SwiftUI

@main
struct FotMobMenuBarApp: App {
    @StateObject private var store = MatchStore()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(store: store)
                .task { store.start() }
        } label: {
            if store.menuTitle.isEmpty {
                Image(nsImage: FotMobLogoImage.menuBar)
                    .renderingMode(.template)
                    .frame(width: 18, height: 18)
            } else {
                HStack(spacing: 4) {
                    Image(nsImage: FotMobLogoImage.menuBar)
                        .renderingMode(.template)
                        .frame(width: 18, height: 18)
                    Text(store.menuTitle)
                }
            }
        }
        .menuBarExtraStyle(.window)

        Window("Favorite Teams", id: "teams") {
            TeamPickerView(store: store)
        }
        .defaultSize(width: 460, height: 520)
        .windowResizability(.contentSize)
    }
}
