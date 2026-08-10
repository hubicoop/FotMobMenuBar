import SwiftUI

struct TeamPickerView: View {
    @ObservedObject var store: MatchStore
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Takımlarım").font(.title2.bold())
                Spacer()
                Button("Bitti") { dismiss() }
            }
            .padding()

            TextField("Takım ara: Galatasaray, Liverpool...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.bottom, 10)

            List {
                if !store.favoriteTeams.isEmpty {
                    Section("Favoriler") {
                        ForEach(store.favoriteTeams) { team in
                            HStack {
                                teamDetails(team.name, league: team.leagueName)
                                Spacer()
                                Button {
                                    store.remove(team)
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }

                Section("Takım ara") {
                    if store.isSearching {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                    if let error = store.errorMessage, !store.isSearching {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    } else if searchText.count >= 2 && store.searchResults.isEmpty && !store.isSearching {
                        Text("Takım bulunamadı").foregroundStyle(.secondary)
                    }
                    ForEach(store.searchResults) { suggestion in
                        HStack {
                            teamDetails(suggestion.name, league: suggestion.leagueName)
                            Spacer()
                            Button {
                                store.add(suggestion)
                            } label: {
                                Image(systemName: store.favoriteTeams.contains(where: { $0.id == suggestion.numericID }) ? "checkmark.circle.fill" : "plus.circle.fill")
                            }
                            .buttonStyle(.borderless)
                            .disabled(store.favoriteTeams.contains(where: { $0.id == suggestion.numericID }))
                        }
                    }
                }
            }
            .onChange(of: searchText) { store.search($0) }
        }
        .frame(width: 460, height: 520)
    }

    private func teamDetails(_ name: String, league: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
            if let league { Text(league).font(.caption).foregroundStyle(.secondary) }
        }
    }
}
