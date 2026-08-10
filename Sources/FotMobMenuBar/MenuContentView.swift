import SwiftUI

struct MenuContentView: View {
    @ObservedObject var store: MatchStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if !store.favoriteSummaries.isEmpty {
                        ForEach(store.favoriteSummaries) { summary in
                            FavoriteSummaryCard(
                                summary: summary,
                                openFixture: store.openFixtureInFotMob
                            )
                        }
                    }
                    if store.topLeagueMatches.isEmpty && store.liveMatches.isEmpty {
                        noMatchesState
                    } else {
                        matchSection("Live Matches", matches: store.liveMatches)
                        matchSection("Top 5 Leagues - Today", matches: store.topLeagueMatches)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
            footer
        }
        .frame(width: 420, height: 520)
        .background(Color(red: 0.075, green: 0.075, blue: 0.075))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "soccerball")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.blue, in: RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's Matches")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                Text(store.isRefreshing ? "Refreshing scores" : "Live scores & goal notifications")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.58))
            }
            Spacer()
            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 30, height: 30)
                    .background(.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(store.isRefreshing)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 6)
    }

    private var noMatchesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text("No matches today").font(.headline)
            Text("There are no live or Top 5 league matches right now.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }

    @ViewBuilder
    private func matchSection(_ title: String, matches: [Match]) -> some View {
        if !matches.isEmpty {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.58))
                .padding(.top, 4)
            ForEach(matches) { match in
                MatchRow(
                    match: match,
                    leagueName: store.leagueNames[match.leagueId],
                    isInWidget: store.widgetMatchID == match.id,
                    action: { store.openInFotMob(match) },
                    toggleWidget: { store.toggleWidget(for: match) }
                )
            }
        }
    }

    private var footer: some View {
        HStack {
            Button(action: openTeamPicker) {
                Label("Teams", systemImage: "person.2.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
            Toggle("Goal notifications", isOn: $store.notificationsEnabled)
                .toggleStyle(.checkbox)
                .font(.system(size: 12))
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 24)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                AsyncImage(url: logoURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Image(systemName: "shield.fill")
                }
                .frame(width: 24, height: 24)
                .padding(7)
                .background(.clear, in: Circle())
                .overlay { Circle().stroke(.white.opacity(0.9), lineWidth: 1.5) }

                Text(summary.team.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            if let last = summary.lastMatch {
                Button { openFixture(last) } label: {
                    summaryLine(
                        title: "Last match",
                        detail: "\(last.opponentLabel(for: summary.team.id)) · \(last.teamScore(for: summary.team.id))"
                    )
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
            }
            if let next = summary.nextMatch {
                Button { openFixture(next) } label: {
                    summaryLine(
                        title: "Next",
                        detail: "\(next.kickoffDateText) · \(next.opponentLabel(for: summary.team.id))"
                    )
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        }
    }

    private func summaryLine(title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.68))
                .frame(width: 72, alignment: .leading)
            Text(detail)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }

    private var logoURL: URL? {
        URL(string: "https://images.fotmob.com/image_resources/logo/teamlogo/\(summary.team.id).png")
    }
}

private struct MatchRow: View {
    let match: Match
    let leagueName: String?
    let isInWidget: Bool
    let action: () -> Void
    let toggleWidget: () -> Void

    var body: some View {
        HStack(spacing: 6) {
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if match.isLive {
                Button(action: toggleWidget) {
                    Image(systemName: isInWidget ? "rectangle.grid.1x2.fill" : "rectangle.grid.1x2")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isInWidget ? .blue : .white.opacity(0.45))
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(isInWidget ? 0.12 : 0.06), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help(isInWidget ? "Hide from menu bar widget" : "Show in menu bar widget")
            }
        }
        .padding(12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
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
