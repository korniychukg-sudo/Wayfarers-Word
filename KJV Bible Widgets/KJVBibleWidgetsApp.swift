import SwiftUI

@main
struct KJVBibleWidgetsApp: App {
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
    @State private var tab: Int = {
#if DEBUG
        if let marker = ProcessInfo.processInfo.arguments.firstIndex(of: "-initialTab"),
           ProcessInfo.processInfo.arguments.indices.contains(marker + 1),
           let requested = Int(ProcessInfo.processInfo.arguments[marker + 1]) {
            return min(max(requested, 0), 4)
        }
#endif
        return 0
    }()
    @State private var biblePath: [BibleRoute] = []
    @Namespace private var tabMotion

    private let tabs: [(String, String)] = [
        ("sun.max.fill", "Today"),
        ("text.book.closed.fill", "Bible"),
        ("square.grid.2x2.fill", "Widgets"),
        ("map.fill", "Atlas"),
        ("book.closed.fill", "Journal")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case 0: NavigationStack { WalkView() }
                case 1: NavigationStack(path: $biblePath) {
                    BibleLibraryView()
                        .navigationDestination(for: BibleRoute.self) { route in
                            if let book = BibleLibrary.shared.book(named: route.book),
                               let chapter = book.chapters.first(where: { $0.chapter == route.chapter }) {
                                BibleChapterReader(book: book, chapter: chapter)
                            } else {
                                BibleLibraryView()
                            }
                        }
                }
                case 2: NavigationStack { WidgetStudioView() }
                case 3: NavigationStack { AtlasView() }
                default: NavigationStack { LogbookView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity.combined(with: .scale(scale: 0.985)))

            HStack(spacing: 4) {
                ForEach(tabs.indices, id: \.self) { index in
                    tabButton(index, tabs[index].1, tabs[index].0)
                }
            }
            .padding(6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.white.opacity(0.35), lineWidth: 1))
            .shadow(color: Parch.night.opacity(0.24), radius: 24, y: 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: 720)
            .padding(.bottom, 7)
        }
        .tint(Parch.gold)
        .onOpenURL { url in
            guard url.scheme == "kjvbiblewidgets", url.host == "bible",
                  let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let book = parts.queryItems?.first(where: { $0.name == "book" })?.value,
                  let chapterText = parts.queryItems?.first(where: { $0.name == "chapter" })?.value,
                  let chapter = Int(chapterText) else { return }
            tab = 1
            biblePath = [BibleRoute(book: book, chapter: chapter)]
        }
    }

    private func tabButton(_ index: Int, _ label: String, _ symbol: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { tab = index }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolEffect(.bounce, value: tab == index)
                Text(label)
                    .font(.waySans(10, weight: .semibold))
            }
            .foregroundStyle(tab == index ? Color.white : Parch.inkSoft)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if tab == index {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Parch.night)
                        .matchedGeometryEffect(id: "selectedTab", in: tabMotion)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct BibleRoute: Hashable {
    let book: String
    let chapter: Int
}
