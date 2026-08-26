import SwiftUI
import WidgetKit

private struct ScripturePalette {
    let background: [Color]
    let text: Color
    let soft: Color
    let accent: Color

    static func palette(_ theme: String) -> Self {
        switch theme {
        case "Midnight": return .init(background: [Color(red: 0.035, green: 0.065, blue: 0.075), Color(red: 0.08, green: 0.13, blue: 0.14)], text: .white, soft: .white.opacity(0.66), accent: Color(red: 0.91, green: 0.74, blue: 0.44))
        case "Dawn": return .init(background: [Color(red: 0.97, green: 0.72, blue: 0.48), Color(red: 0.56, green: 0.29, blue: 0.30)], text: .white, soft: .white.opacity(0.76), accent: Color(red: 1, green: 0.89, blue: 0.66))
        case "Sage": return .init(background: [Color(red: 0.76, green: 0.82, blue: 0.72), Color(red: 0.30, green: 0.42, blue: 0.36)], text: .white, soft: .white.opacity(0.72), accent: Color(red: 0.96, green: 0.86, blue: 0.61))
        case "Ocean": return .init(background: [Color(red: 0.16, green: 0.38, blue: 0.47), Color(red: 0.035, green: 0.13, blue: 0.18)], text: .white, soft: .white.opacity(0.7), accent: Color(red: 0.59, green: 0.85, blue: 0.86))
        default: return .init(background: [Color(red: 0.98, green: 0.96, blue: 0.91), Color(red: 0.88, green: 0.83, blue: 0.72)], text: Color(red: 0.08, green: 0.10, blue: 0.10), soft: Color(red: 0.08, green: 0.10, blue: 0.10).opacity(0.6), accent: Color(red: 0.66, green: 0.47, blue: 0.20))
        }
    }
}

struct ScriptureWidgetBackground: View {
    let theme: String
    var body: some View {
        let p = ScripturePalette.palette(theme)
        ZStack {
            LinearGradient(colors: p.background, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(p.accent.opacity(0.17)).frame(width: 190).offset(x: 80, y: -75)
            Image(systemName: "sun.max.fill").font(.system(size: 72)).foregroundStyle(p.accent.opacity(0.075)).offset(x: 72, y: -62)
        }
    }
}

struct ScriptureWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ScriptureEntry
    private var p: ScripturePalette { .palette(entry.settings.theme) }
    private var verseFont: Font.Design { entry.settings.font == "Rounded" ? .rounded : .serif }

    var body: some View {
        switch family {
        case .systemSmall: small
        case .systemMedium: medium
        case .systemLarge: large
        case .accessoryRectangular: rectangular
        case .accessoryCircular: circular
        default: Text("\(entry.verse.reference) · \(entry.verse.text)")
        }
    }

    private var brand: some View {
        HStack(spacing: 6) {
            Image(systemName: entry.settings.icon).font(.system(size: 9, weight: .bold))
            Text(entry.settings.showTopic ? entry.verse.topic.uppercased() : "WAYFARER'S WORD")
                .font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1.2).lineLimit(1)
        }.foregroundStyle(p.accent)
    }

    private var small: some View {
        VStack(alignment: entry.settings.alignment == "Center" ? .center : .leading, spacing: 8) {
            brand
            Spacer(minLength: 0)
            Text("“\(entry.verse.text)”")
                .font(.system(size: 16, weight: .semibold, design: verseFont))
                .foregroundStyle(p.text).lineLimit(5).minimumScaleFactor(0.72)
                .multilineTextAlignment(entry.settings.alignment == "Center" ? .center : .leading)
            if entry.settings.showReference {
                Text(entry.verse.reference).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(p.accent)
            }
        }
    }

    private var medium: some View {
        HStack(spacing: 18) {
            VStack(alignment: entry.settings.alignment == "Center" ? .center : .leading, spacing: 8) {
                brand
                Text("“\(entry.verse.text)”")
                    .font(.system(size: 17, weight: .semibold, design: verseFont))
                    .foregroundStyle(p.text).lineLimit(4).minimumScaleFactor(0.74)
                    .multilineTextAlignment(entry.settings.alignment == "Center" ? .center : .leading)
                if entry.settings.showReference { Text(entry.verse.reference).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(p.accent) }
            }
            Spacer(minLength: 0)
            ZStack {
                Circle().fill(p.accent.opacity(0.16))
                Image(systemName: "book.pages.fill").font(.system(size: 31, weight: .light)).foregroundStyle(p.accent)
            }.frame(width: 72, height: 72)
        }
    }

    private var large: some View {
        VStack(alignment: entry.settings.alignment == "Center" ? .center : .leading, spacing: 15) {
            HStack { brand; Spacer(); Image(systemName: "bookmark").foregroundStyle(p.accent) }
            Spacer(minLength: 2)
            Image(systemName: "quote.opening").font(.system(size: 28, weight: .light)).foregroundStyle(p.accent)
            Text(entry.verse.text)
                .font(.system(size: 25, weight: .semibold, design: verseFont))
                .foregroundStyle(p.text).lineSpacing(4).minimumScaleFactor(0.72)
                .multilineTextAlignment(entry.settings.alignment == "Center" ? .center : .leading)
            if entry.settings.showReference { Text(entry.verse.reference).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(p.accent) }
            Spacer(minLength: 2)
            Divider().overlay(p.accent.opacity(0.4))
            Label("Tap to read the full chapter", systemImage: "book.pages")
                .font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(p.soft)
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(entry.verse.text).font(.system(size: 13, weight: .semibold, design: verseFont)).lineLimit(2)
            if entry.settings.showReference { Text(entry.verse.reference).font(.system(size: 10, weight: .bold, design: .rounded)).opacity(0.72) }
        }
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "book.pages.fill").font(.system(size: 13))
                Text(entry.verse.book.prefix(3).uppercased()).font(.system(size: 9, weight: .bold, design: .rounded))
                Text("\(entry.verse.chapter):\(entry.verse.verse)").font(.system(size: 9, weight: .semibold, design: .rounded))
            }
        }
    }
}
