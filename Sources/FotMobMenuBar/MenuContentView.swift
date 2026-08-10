import SwiftUI

struct MenuContentView: View {
    @ObservedObject var store: MatchStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if !store.favoriteSummaries.isEmpty {
                        Text("Favori Takımlar")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        ForEach(store.favoriteSummaries) { summary in
                            FavoriteSummaryCard(summary: summary, openFixture: store.openFixtureInFotMob)
                        }
                    }
                    if store.topLeagueMatches.isEmpty && store.liveMatches.isEmpty {
                        noMatchesState
                    } else {
                        matchSection("Canlı Maçlar", matches: store.liveMatches)
                        matchSection("Top 5 Lig - Bugün", matches: store.topLeagueMatches)
                    }
                }
                .padding(12)
            }
            Divider()
            footer
        }
        .frame(width: 390, height: 460)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Bugünün Maçları")
                    .font(.headline)
                Text(store.isRefreshing ? "Skorlar yenileniyor" : "Canlı skor ve gol bildirimleri")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(store.isRefreshing)
        }
        .padding(14)
    }

    private var noMatchesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text("Bugün maç yok").font(.headline)
            Text("Top 5 ligde veya canlı olarak oynanan bir maç bulunmuyor.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 300)
    }

    @ViewBuilder
    private func matchSection(_ title: String, matches: [Match]) -> some View {
        if !matches.isEmpty {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            ForEach(matches) { match in
                MatchRow(match: match, leagueName: store.leagueNames[match.leagueId]) {
                    store.openInFotMob(match)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Takımlar", action: openTeamPicker)
            Toggle("Gol bildirimleri", isOn: $store.notificationsEnabled)
                .toggleStyle(.checkbox)
            Spacer()
            Button("Çıkış") { NSApplication.shared.terminate(nil) }
        }
        .font(.caption)
        .padding(12)
    }

    private func openTeamPicker() {
        openWindow(id: "teams")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

private struct FavoriteSummaryCard: View {
    let summary: FavoriteTeamSummary
    let openFixture: (TeamFixture) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(summary.team.name).font(.headline)
            if let last = summary.lastMatch {
                Button { openFixture(last) } label: {
                    summaryLine(
                        title: "Son maç",
                        detail: "\(last.home.name) \(last.score) \(last.away.name)"
                    )
                }
                .buttonStyle(.plain)
            }
            if let next = summary.nextMatch {
                Button { openFixture(next) } label: {
                    summaryLine(
                        title: "Sıradaki",
                        detail: "\(next.kickoffText) · \(next.home.name) - \(next.away.name)"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.blue.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
    }

    private func summaryLine(title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
            Text(detail).font(.caption).lineLimit(1)
        }
    }
}

private struct MatchRow: View {
    let match: Match
    let leagueName: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    if let leagueName {
                        Text(leagueName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    teamLine(name: match.home.name, score: match.home.score)
                    teamLine(name: match.away.name, score: match.away.score)
                }
                Spacer()
                VStack(spacing: 5) {
                    Text(match.minuteText)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(match.isLive ? .red : .secondary)
                    if match.isLive {
                        Circle().fill(.red).frame(width: 6, height: 6)
                    }
                }
                .frame(width: 48)
            }
            .padding(12)
            .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func teamLine(name: String, score: Int?) -> some View {
        HStack {
            Text(name).lineLimit(1)
            Spacer()
            Text(score.map(String.init) ?? "-")
                .font(.system(.body, design: .rounded, weight: .bold))
        }
    }
}
