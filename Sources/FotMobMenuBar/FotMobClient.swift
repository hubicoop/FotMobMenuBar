import Foundation

enum FotMobError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "FotMob verisi alınamadı."
    }
}

struct FotMobClient: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchTeams(query: String) async throws -> [TeamSuggestion] {
        var components = URLComponents(string: "https://www.fotmob.com/api/data/search/suggest")!
        components.queryItems = [
            URLQueryItem(name: "hits", value: "30"),
            URLQueryItem(name: "lang", value: "tr"),
            URLQueryItem(name: "term", value: query)
        ]
        let sections: [SearchSection] = try await request(components.url!)
        var seen = Set<String>()
        return sections
            .flatMap(\.suggestions)
            .filter { $0.type == "team" && seen.insert($0.id).inserted }
    }

    func matches(on date: Date = .now) async throws -> MatchFeed {
        var components = URLComponents(string: "https://www.fotmob.com/api/data/matches")!
        components.queryItems = [
            URLQueryItem(name: "date", value: dateString(from: date)),
            URLQueryItem(name: "timezone", value: TimeZone.current.identifier),
            URLQueryItem(name: "ccode3", value: "TUR"),
            URLQueryItem(name: "includeNextDayLateNight", value: "true")
        ]
        let response: MatchesResponse = try await request(components.url!)
        let topLeagueIDs: Set<Int> = [47, 87, 54, 55, 53]
        return MatchFeed(
            matches: response.leagues.flatMap(\.matches),
            topLeagueMatches: response.leagues
                .filter { topLeagueIDs.contains($0.primaryId ?? $0.id) }
                .flatMap(\.matches),
            leagueNames: response.leagues.reduce(into: [:]) { names, league in
                names[league.id] = league.name
            }
        )
    }

    func teamSummary(for team: FavoriteTeam) async throws -> FavoriteTeamSummary {
        let response = try await teamResponse(teamID: team.id)
        return FavoriteTeamSummary(
            team: team,
            lastMatch: response.fixtures.allFixtures.lastMatch,
            nextMatch: response.fixtures.allFixtures.nextMatch,
            colors: response.overview?.teamColors
        )
    }

    func matchPagePath(matchID: Int, teamID: Int) async throws -> String {
        let response = try await teamResponse(teamID: teamID)
        guard let fixture = response.fixtures.allFixtures.fixtures.first(where: { $0.id == matchID }) else {
            throw FotMobError.invalidResponse
        }
        return fixture.pageUrl
    }

    private func teamResponse(teamID: Int) async throws -> TeamResponse {
        var components = URLComponents(string: "https://www.fotmob.com/api/data/teams")!
        components.queryItems = [
            URLQueryItem(name: "id", value: String(teamID)),
            URLQueryItem(name: "ccode3", value: "TUR")
        ]
        return try await request(components.url!)
    }

    private func request<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("FotMobMenuBar/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw FotMobError.invalidResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
}
