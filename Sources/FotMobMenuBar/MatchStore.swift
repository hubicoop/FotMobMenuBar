import AppKit
import Foundation

@MainActor
final class MatchStore: ObservableObject {
    @Published private(set) var favoriteTeams: [FavoriteTeam] = []
    @Published private(set) var matches: [Match] = []
    @Published private(set) var topLeagueMatches: [Match] = []
    @Published private(set) var liveMatches: [Match] = []
    @Published private(set) var favoriteMatches: [Match] = []
    @Published private(set) var favoriteSummaries: [FavoriteTeamSummary] = []
    @Published private(set) var leagueNames: [Int: String] = [:]
    @Published private(set) var searchResults: [TeamSuggestion] = []
    @Published private(set) var widgetMatchID: Int?
    @Published private(set) var isSearching = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?
    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }
    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Keys.notifications)
            if notificationsEnabled {
                Task { await notifications.requestPermission() }
            }
        }
    }

    private let client: FotMobClient
    private let notifications = NotificationService()
    private let defaults: UserDefaults
    private var scoreBaseline: [Int: Int] = [:]
    private var refreshTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var lastSummaryRefresh = Date.distantPast
    private var matchPagePaths: [Int: String] = [:]

    init(client: FotMobClient = FotMobClient(), defaults: UserDefaults = .standard) {
        self.client = client
        self.defaults = defaults
        widgetMatchID = defaults.object(forKey: Keys.widgetMatchID) as? Int
        theme = AppTheme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .teamColors
        notificationsEnabled = defaults.object(forKey: Keys.notifications) as? Bool ?? true
        if let data = defaults.data(forKey: Keys.favorites),
           let teams = try? JSONDecoder().decode([FavoriteTeam].self, from: data) {
            favoriteTeams = teams
        }
    }

    deinit {
        refreshTask?.cancel()
        searchTask?.cancel()
    }

    var menuTitle: String {
        guard let widgetMatchID,
              let match = matches.first(where: { $0.id == widgetMatchID && $0.isLive }) else { return "" }
        return "\(abbreviation(match.home.name)) \(match.home.score ?? 0)-\(match.away.score ?? 0) \(abbreviation(match.away.name)) \(match.minuteText)"
    }

    func start() {
        guard refreshTask == nil else { return }
        if notificationsEnabled {
            Task { await notifications.requestPermission() }
        }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                let hasLiveMatch = self?.matches.contains(where: \.isLive) == true
                let delay = hasLiveMatch ? 30 : 120
                try? await Task.sleep(for: .seconds(delay))
            }
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let feed = try await client.matches()
            let allMatches = feed.matches
            let teamIDs = Set(favoriteTeams.map(\.id))
            let favorites = allMatches.filter {
                teamIDs.contains($0.home.id) || teamIDs.contains($0.away.id)
            }
            await processGoals(in: favorites)
            matches = allMatches
            liveMatches = sorted(allMatches.filter(\.isLive))
            if let widgetMatchID, !liveMatches.contains(where: { $0.id == widgetMatchID }) {
                self.widgetMatchID = nil
                defaults.removeObject(forKey: Keys.widgetMatchID)
            }
            let liveMatchIDs = Set(liveMatches.map(\.id))
            topLeagueMatches = sorted(feed.topLeagueMatches.filter { !liveMatchIDs.contains($0.id) })
            let topMatchIDs = Set(topLeagueMatches.map(\.id))
            let visibleIDs = topMatchIDs.union(liveMatches.map(\.id))
            favoriteMatches = sorted(favorites.filter { !visibleIDs.contains($0.id) })
            leagueNames = feed.leagueNames
            if Date.now.timeIntervalSince(lastSummaryRefresh) >= 900 {
                await refreshFavoriteSummaries()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sorted(_ matches: [Match]) -> [Match] {
        matches.sorted { lhs, rhs in
                if lhs.isLive != rhs.isLive { return lhs.isLive }
                return lhs.status.utcTime < rhs.status.utcTime
        }
    }

    func search(_ query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled, let self else { return }
            do {
                let results = try await client.searchTeams(query: trimmed)
                guard !Task.isCancelled else { return }
                searchResults = results
                errorMessage = nil
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }

    func add(_ suggestion: TeamSuggestion) {
        guard let id = suggestion.numericID,
              !favoriteTeams.contains(where: { $0.id == id }) else { return }
        favoriteTeams.append(FavoriteTeam(id: id, name: suggestion.name, leagueName: suggestion.leagueName))
        saveFavorites()
        Task {
            await refreshFavoriteSummaries()
            await refresh()
        }
    }

    func remove(_ team: FavoriteTeam) {
        favoriteTeams.removeAll { $0.id == team.id }
        favoriteMatches.removeAll { $0.home.id == team.id || $0.away.id == team.id }
        favoriteSummaries.removeAll { $0.id == team.id }
        saveFavorites()
    }

    func openInFotMob(_ match: Match) {
        Task {
            do {
                let path: String
                if let cachedPath = matchPagePaths[match.id] {
                    path = cachedPath
                } else {
                    path = try await client.matchPagePath(matchID: match.id, teamID: match.home.id)
                    matchPagePaths[match.id] = path
                }
                if let url = URL(string: path, relativeTo: URL(string: "https://www.fotmob.com"))?.absoluteURL {
                    NSWorkspace.shared.open(url)
                }
            } catch {
                errorMessage = "Could not load the match link from FotMob."
            }
        }
    }

    func toggleWidget(for match: Match) {
        if widgetMatchID == match.id {
            widgetMatchID = nil
            defaults.removeObject(forKey: Keys.widgetMatchID)
        } else {
            widgetMatchID = match.id
            defaults.set(match.id, forKey: Keys.widgetMatchID)
        }
    }

    func toggleTheme() {
        theme = theme == .teamColors ? .darkMinimal : .teamColors
    }

    func openFixtureInFotMob(_ fixture: TeamFixture) {
        guard let url = URL(string: fixture.pageUrl, relativeTo: URL(string: "https://www.fotmob.com"))?.absoluteURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func refreshFavoriteSummaries() async {
        let teams = favoriteTeams
        let client = client
        let summaries = await withTaskGroup(of: FavoriteTeamSummary?.self) { group in
            for team in teams {
                group.addTask { try? await client.teamSummary(for: team) }
            }
            var results: [FavoriteTeamSummary] = []
            for await summary in group {
                if let summary { results.append(summary) }
            }
            return results
        }
        favoriteSummaries = summaries.sorted { $0.team.name < $1.team.name }
        for summary in favoriteSummaries {
            if let fixture = summary.lastMatch { matchPagePaths[fixture.id] = fixture.pageUrl }
            if let fixture = summary.nextMatch { matchPagePaths[fixture.id] = fixture.pageUrl }
        }
        lastSummaryRefresh = .now
    }

    private func processGoals(in newMatches: [Match]) async {
        for match in newMatches where match.status.started {
            if let previous = scoreBaseline[match.id], match.totalGoals > previous, notificationsEnabled {
                await notifications.sendGoal(for: match)
            }
            scoreBaseline[match.id] = match.totalGoals
        }
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteTeams) {
            defaults.set(data, forKey: Keys.favorites)
        }
    }

    private func abbreviation(_ name: String) -> String {
        String(name.prefix(3)).uppercased(with: Locale(identifier: "en_US"))
    }

    private enum Keys {
        static let favorites = "favoriteTeams"
        static let notifications = "notificationsEnabled"
        static let widgetMatchID = "widgetMatchID"
        static let theme = "appTheme"
    }
}
