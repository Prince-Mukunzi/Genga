import WidgetKit
import SwiftUI

// MARK: - Palette

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum GengaPalette {
    static let background = Color(hex: 0x0C0C0E)
    static let surface = Color(hex: 0x161619)
    static let surfaceElevated = Color(hex: 0x1E1E22)
    static let offWhite = Color(hex: 0xEDEAE4)
    static let onOffWhite = Color(hex: 0x17171A)
    static let textPrimary = Color(hex: 0xE8E6E3)
    static let textSecondary = Color(hex: 0xA1A1A6)
    static let textTertiary = Color(hex: 0x86868B)
    static let expense = Color(hex: 0xFF453A)
    static let income = Color(hex: 0x30D158)
    static let transfer = Color(hex: 0x5AC8FA)
    static let pocketTop = Color(hex: 0x2B2B2F)
    static let pocketBottom = Color(hex: 0x18181B)
}

// MARK: - Data

struct GengaWidgetData {
    let primaryName: String
    let primaryBalance: String
    let primarySpent: String
    let brandColors: [Color]
    let recentTransactions: [RecentTransaction]

    struct RecentTransaction: Identifiable {
        let id = UUID()
        let amount: String
        let type: String
        let category: String
        let note: String

        var icon: String {
            switch type {
            case "expense": return "arrow.up.right"
            case "income": return "arrow.down.left"
            case "transfer": return "arrow.left.arrow.right"
            default: return "circle.fill"
            }
        }

        var color: Color {
            switch type {
            case "expense": return GengaPalette.expense
            case "income": return GengaPalette.income
            case "transfer": return GengaPalette.transfer
            default: return GengaPalette.textTertiary
            }
        }

        var displayName: String {
            if !category.isEmpty { return category }
            if !note.isEmpty { return note }
            return type.capitalized
        }

        var signedAmount: String {
            type == "income" ? "+\(amount)" : type == "expense" ? "-\(amount)" : amount
        }
    }

    static let placeholder = GengaWidgetData(
        primaryName: "Genga",
        primaryBalance: "R₣0",
        primarySpent: "0",
        brandColors: [Color(hex: 0x3A3A42), Color(hex: 0x16161B)],
        recentTransactions: []
    )
}

private let appGroupId = "group.com.example.genga"

func loadWidgetData() -> GengaWidgetData {
    let defaults = UserDefaults(suiteName: appGroupId)

    var colors: [Color] = GengaWidgetData.placeholder.brandColors
    if let json = defaults?.string(forKey: "primary_brand_colors"),
       let data = json.data(using: .utf8),
       let list = try? JSONSerialization.jsonObject(with: data) as? [Int],
       list.count >= 2 {
        colors = list.map { Color(hex: UInt32(truncatingIfNeeded: $0)) }
    }

    var transactions: [GengaWidgetData.RecentTransaction] = []
    if let jsonString = defaults?.string(forKey: "recent_transactions"),
       let data = jsonString.data(using: .utf8),
       let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
        transactions = list.map { item in
            GengaWidgetData.RecentTransaction(
                amount: item["amountFormatted"] as? String ?? "",
                type: item["type"] as? String ?? "",
                category: item["category"] as? String ?? "",
                note: item["note"] as? String ?? ""
            )
        }
    }

    return GengaWidgetData(
        primaryName: defaults?.string(forKey: "primary_account_name") ?? "Genga",
        primaryBalance: defaults?.string(forKey: "primary_balance_formatted") ?? "R₣0",
        primarySpent: defaults?.string(forKey: "primary_spent_formatted") ?? "0",
        brandColors: colors,
        recentTransactions: transactions
    )
}

// MARK: - Timeline

struct GengaWidgetEntry: TimelineEntry {
    let date: Date
    let data: GengaWidgetData
}

struct GengaTimelineProvider: TimelineProvider {
    typealias Entry = GengaWidgetEntry

    func placeholder(in context: Context) -> GengaWidgetEntry {
        GengaWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (GengaWidgetEntry) -> Void) {
        completion(GengaWidgetEntry(date: Date(), data: loadWidgetData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GengaWidgetEntry>) -> Void) {
        let entry = GengaWidgetEntry(date: Date(), data: loadWidgetData())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Wallet pocket

struct PocketShape: Shape {
    var radius: CGFloat = 26
    var scoop: CGFloat = 14
    var half: CGFloat = 46

    func path(in r: CGRect) -> Path {
        var p = Path()
        let l = r.minX, t = r.minY, rt = r.maxX, b = r.maxY, cx = r.midX
        p.move(to: CGPoint(x: l, y: t + radius))
        p.addQuadCurve(to: CGPoint(x: l + radius, y: t), control: CGPoint(x: l, y: t))
        p.addLine(to: CGPoint(x: cx - half, y: t))
        p.addCurve(
            to: CGPoint(x: cx, y: t + scoop),
            control1: CGPoint(x: cx - half * 0.45, y: t),
            control2: CGPoint(x: cx - half * 0.55, y: t + scoop)
        )
        p.addCurve(
            to: CGPoint(x: cx + half, y: t),
            control1: CGPoint(x: cx + half * 0.55, y: t + scoop),
            control2: CGPoint(x: cx + half * 0.45, y: t)
        )
        p.addLine(to: CGPoint(x: rt - radius, y: t))
        p.addQuadCurve(to: CGPoint(x: rt, y: t + radius), control: CGPoint(x: rt, y: t))
        p.addLine(to: CGPoint(x: rt, y: b - radius))
        p.addQuadCurve(to: CGPoint(x: rt - radius, y: b), control: CGPoint(x: rt, y: b))
        p.addLine(to: CGPoint(x: l + radius, y: b))
        p.addQuadCurve(to: CGPoint(x: l, y: b - radius), control: CGPoint(x: l, y: b))
        p.closeSubpath()
        return p
    }
}

private struct StitchShape: Shape {
    func path(in r: CGRect) -> Path {
        PocketShape(radius: 20, scoop: 12, half: 40).path(in: r.insetBy(dx: 7, dy: 7))
    }
}

struct WalletView: View {
    let data: GengaWidgetData
    var balanceSize: CGFloat = 22

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pocketTop = h * 0.34

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: data.brandColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topLeading) {
                        Text(data.primaryName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.leading, 12)
                            .padding(.top, 9)
                    }
                    .frame(width: w - 20, height: h * 0.5)
                    .offset(x: 10, y: 0)

                ZStack(alignment: .bottomLeading) {
                    PocketShape()
                        .fill(
                            LinearGradient(
                                colors: [GengaPalette.pocketTop, GengaPalette.pocketBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    PocketShape()
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                    StitchShape()
                        .stroke(
                            GengaPalette.offWhite.opacity(0.28),
                            style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 4])
                        )

                    Circle()
                        .fill(Color(hex: 0x4A4A50))
                        .frame(width: 5, height: 5)
                        .position(x: 17, y: 17)
                    Circle()
                        .fill(Color(hex: 0x4A4A50))
                        .frame(width: 5, height: 5)
                        .position(x: w - 17, y: 17)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(data.primaryBalance)
                            .font(.system(size: balanceSize, weight: .semibold))
                            .foregroundColor(GengaPalette.offWhite)
                            .minimumScaleFactor(0.55)
                            .lineLimit(1)
                        Text("Spent \(data.primarySpent) this month")
                            .font(.system(size: 9.5))
                            .foregroundColor(GengaPalette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 12)
                    .padding(.bottom, 15)
                }
                .frame(width: w, height: h - pocketTop)
                .offset(y: pocketTop)
            }
        }
    }
}

// MARK: - Recent rows

private struct TransactionRow: View {
    let transaction: GengaWidgetData.RecentTransaction

    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                Circle().fill(transaction.color.opacity(0.16))
                Image(systemName: transaction.icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(transaction.color)
            }
            .frame(width: 22, height: 22)

            Text(transaction.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(GengaPalette.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(transaction.signedAmount)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(transaction.color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct RecentList: View {
    let transactions: [GengaWidgetData.RecentTransaction]
    let limit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Recent")
                .font(.system(size: 10.5))
                .foregroundColor(GengaPalette.textTertiary)
            if transactions.isEmpty {
                Spacer(minLength: 0)
                Text("Nothing yet")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(GengaPalette.textPrimary)
                Text("Tap + in Genga to add your first one")
                    .font(.system(size: 10.5))
                    .foregroundColor(GengaPalette.textTertiary)
                Spacer(minLength: 0)
            } else {
                ForEach(transactions.prefix(limit)) { TransactionRow(transaction: $0) }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Sizes

struct GengaSmallView: View {
    let entry: GengaWidgetEntry

    var body: some View {
        WalletView(data: entry.data, balanceSize: 21)
    }
}

struct GengaMediumView: View {
    let entry: GengaWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            WalletView(data: entry.data, balanceSize: 19)
                .frame(maxWidth: .infinity)
            RecentList(transactions: entry.data.recentTransactions, limit: 3)
                .frame(maxWidth: .infinity)
        }
    }
}

struct GengaLargeView: View {
    let entry: GengaWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WalletView(data: entry.data, balanceSize: 30)
                .frame(height: 170)
            RecentList(transactions: entry.data.recentTransactions, limit: 5)
        }
    }
}

struct GengaSummaryEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: GengaWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium: GengaMediumView(entry: entry)
            case .systemLarge: GengaLargeView(entry: entry)
            default: GengaSmallView(entry: entry)
            }
        }
        .widgetURL(URL(string: "genga://home"))
    }
}

// MARK: - Quick actions

struct GengaQuickActionsView: View {
    var body: some View {
        HStack(spacing: 10) {
            Link(destination: URL(string: "genga://add?type=expense")!) {
                QuickActionButton(icon: "arrow.up.right", label: "Expense", primary: true)
            }
            Link(destination: URL(string: "genga://add?type=income")!) {
                QuickActionButton(icon: "arrow.down.left", label: "Income", primary: false)
            }
            Link(destination: URL(string: "genga://add?type=transfer")!) {
                QuickActionButton(icon: "arrow.left.arrow.right", label: "Transfer", primary: false)
            }
        }
    }
}

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let primary: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(primary ? GengaPalette.onOffWhite : GengaPalette.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(primary ? GengaPalette.offWhite : GengaPalette.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(primary ? Color.clear : Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - Widgets

struct GengaSummaryWidget: Widget {
    let kind: String = "GengaSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GengaTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                GengaSummaryEntryView(entry: entry)
                    .containerBackground(for: .widget) { GengaPalette.background }
            } else {
                GengaSummaryEntryView(entry: entry)
                    .padding()
                    .background(GengaPalette.background)
            }
        }
        .configurationDisplayName("Genga wallet")
        .description("Your primary account and recent activity.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct GengaQuickActionsWidget: Widget {
    let kind: String = "GengaQuickActionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GengaTimelineProvider()) { _ in
            if #available(iOS 17.0, *) {
                GengaQuickActionsView()
                    .containerBackground(for: .widget) { GengaPalette.background }
            } else {
                GengaQuickActionsView()
                    .padding()
                    .background(GengaPalette.background)
            }
        }
        .configurationDisplayName("Quick actions")
        .description("Add an expense, income, or transfer in one tap.")
        .supportedFamilies([.systemMedium])
    }
}
