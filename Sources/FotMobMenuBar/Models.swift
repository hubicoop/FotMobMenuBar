import Foundation

struct FavoriteTeam: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let leagueName: String?
}

struct TeamSuggestion: Decodable, Identifiable, Sendable {
    let type: String
    let id: String
    let name: String
    let leagueName: String?

    var numericID: Int? { Int(id) }

    private enum CodingKeys: String, CodingKey {
        case type, id, name, leagueName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        if let stringID = try? container.decode(String.self, forKey: .id) {
            id = stringID
        } else {
            id = String(try container.decode(Int.self, forKey: .id))
        }
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        leagueName = try container.decodeIfPresent(String.self, forKey: .leagueName)
    }
}

struct SearchSection: Decodable, Sendable {
    let suggestions: [TeamSuggestion]
}

struct MatchesResponse: Decodable, Sendable {
    let leagues: [League]
}

struct League: Decodable, Sendable {
    let id: Int
    let primaryId: Int?
    let name: String
    let matches: [Match]
}

struct MatchFeed: Sendable {
    let matches: [Match]
    let topLeagueMatches: [Match]
    let leagueNames: [Int: String]
}

struct TeamResponse: Decodable, Sendable {
    let fixtures: TeamFixtures
    let overview: TeamOverview?
}

struct TeamOverview: Decodable, Sendable {
    let teamColors: TeamColors?
}

struct TeamColors: Decodable, Sendable {
    let darkMode: String
    let lightMode: String
    let fontDarkMode: String
    let fontLightMode: String
}

struct TeamFixtures: Decodable, Sendable {
    let allFixtures: AllTeamFixtures
}

struct AllTeamFixtures: Decodable, Sendable {
    let fixtures: [TeamFixture]
    let lastMatch: TeamFixture?
    let nextMatch: TeamFixture?
}

struct TeamFixture: Decodable, Identifiable, Sendable {
    let id: Int
    let pageUrl: String
    let home: MatchTeam
    let away: MatchTeam
    let status: MatchStatus
    let tournament: FixtureTournament
}

struct FixtureTournament: Decodable, Sendable {
    let name: String
    let leagueId: Int
}

struct FavoriteTeamSummary: Identifiable, Sendable {
    let team: FavoriteTeam
    let lastMatch: TeamFixture?
    let nextMatch: TeamFixture?
    let colors: TeamColors?

    var id: Int { team.id }
}

struct Match: Decodable, Identifiable, Sendable {
    let id: Int
    let leagueId: Int
    let home: MatchTeam
    let away: MatchTeam
    let status: MatchStatus

    var isLive: Bool {
        status.started && !status.finished && !status.cancelled
    }

    var score: String { "\(home.score ?? 0) - \(away.score ?? 0)" }
    var totalGoals: Int { (home.score ?? 0) + (away.score ?? 0) }
}

struct MatchTeam: Decodable, Sendable {
    let id: Int
    let score: Int?
    let name: String
}

struct MatchStatus: Decodable, Sendable {
    let utcTime: String
    let started: Bool
    let finished: Bool
    let cancelled: Bool
    let ongoing: Bool?
    let liveTime: LiveTime?
    let reason: MatchReason?
}

struct LiveTime: Decodable, Sendable {
    let short: String?
}

struct MatchReason: Decodable, Sendable {
    let short: String?
}

extension Match {
    var minuteText: String {
        if let short = status.liveTime?.short {
            return short.replacingOccurrences(of: "‎", with: "")
        }
        if status.finished { return status.reason?.short ?? "FT" }
        if status.cancelled { return "Cancelled" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: status.utcTime) else { return "-" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

extension TeamFixture {
    var score: String { "\(home.score ?? 0) - \(away.score ?? 0)" }

    var kickoffDateText: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: status.utcTime) else { return "-" }
        let displayFormatter = DateFormatter()
        displayFormatter.calendar = Calendar(identifier: .gregorian)
        displayFormatter.locale = Locale(identifier: "en_US_POSIX")
        displayFormatter.timeZone = .current
        displayFormatter.dateFormat = "dd.MM.yyyy"
        return displayFormatter.string(from: date)
    }

    func opponentLabel(for teamID: Int) -> String {
        home.id == teamID ? "vs \(away.name)" : "@ \(home.name)"
    }

    func teamScore(for teamID: Int) -> String {
        if home.id == teamID {
            return "\(home.score ?? 0)-\(away.score ?? 0)"
        }
        return "\(away.score ?? 0)-\(home.score ?? 0)"
    }
}
