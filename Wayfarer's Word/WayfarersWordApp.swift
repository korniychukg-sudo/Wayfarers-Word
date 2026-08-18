import SwiftUI

@main
struct WayfarersWordApp: App {
    @StateObject private var store = WayStore.shared
    @StateObject private var shop = WayShop.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if store.onboarded {
                    WayRootView()
                } else {
                    WayOnboardingView()
                }
            }
            .environmentObject(store)
            .environmentObject(shop)
            .preferredColorScheme(.light)
            .task {
                await shop.refreshEntitlement()
                store.drainWidgetQueue()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    store.drainWidgetQueue()
                } else if phase == .background {
                    store.publishSnapshot()
                }
            }
        }
    }
}

struct WayRootView: View {
    @EnvironmentObject var store: WayStore
    @State private var tab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case 0: NavigationView { WalkView() }.navigationViewStyle(StackNavigationViewStyle())
                    case 1: NavigationView { AtlasView() }.navigationViewStyle(StackNavigationViewStyle())
                    case 2: NavigationView { LoreView() }.navigationViewStyle(StackNavigationViewStyle())
                    default: NavigationView { LogbookView() }.navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 0) {
                    tabButton(0, "Walk", "boot")
                    tabButton(1, "Atlas", "map")
                    tabButton(2, "Lore", "lamp")
                    tabButton(3, "Logbook", "book")
                }
                .padding(.top, 9)
                .padding(.bottom, 3)
                .background(
                    Parch.card
                        .overlay(Rectangle().fill(Parch.gold.opacity(0.5)).frame(height: 1), alignment: .top)
                        .edgesIgnoringSafeArea(.bottom)
                )
            }
        }
        .background(ParchBackground())
    }

    private func tabButton(_ index: Int, _ label: String, _ icon: String) -> some View {
        Button {
            tab = index
        } label: {
            VStack(spacing: 3) {
                WayIcon(kind: icon, size: 24, color: tab == index ? Parch.gold : Parch.inkFaint)
                Text(label)
                    .font(.parchSerif(10))
                    .foregroundColor(tab == index ? Parch.gold : Parch.inkFaint)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
