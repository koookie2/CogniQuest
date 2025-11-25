import Foundation

struct StateLookup {
    static func info(for rawValue: String) -> StateInfo? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let upper = trimmed.uppercased()
        if let full = abbreviationToName[upper] {
            return StateInfo(fullName: full, abbreviation: upper)
        }
        let lower = trimmed.lowercased()
        if let abbr = nameToAbbreviation[lower], let full = abbreviationToName[abbr] {
            return StateInfo(fullName: full, abbreviation: abbr)
        }
        return nil
    }

    private static let abbreviationToName: [String: String] = [
        "AL": "Alabama",
        "AK": "Alaska",
        "AZ": "Arizona",
        "AR": "Arkansas",
        "CA": "California",
        "CO": "Colorado",
        "CT": "Connecticut",
        "DE": "Delaware",
        "FL": "Florida",
        "GA": "Georgia",
        "HI": "Hawaii",
        "ID": "Idaho",
        "IL": "Illinois",
        "IN": "Indiana",
        "IA": "Iowa",
        "KS": "Kansas",
        "KY": "Kentucky",
        "LA": "Louisiana",
        "ME": "Maine",
        "MD": "Maryland",
        "MA": "Massachusetts",
        "MI": "Michigan",
        "MN": "Minnesota",
        "MS": "Mississippi",
        "MO": "Missouri",
        "MT": "Montana",
        "NE": "Nebraska",
        "NV": "Nevada",
        "NH": "New Hampshire",
        "NJ": "New Jersey",
        "NM": "New Mexico",
        "NY": "New York",
        "NC": "North Carolina",
        "ND": "North Dakota",
        "OH": "Ohio",
        "OK": "Oklahoma",
        "OR": "Oregon",
        "PA": "Pennsylvania",
        "RI": "Rhode Island",
        "SC": "South Carolina",
        "SD": "South Dakota",
        "TN": "Tennessee",
        "TX": "Texas",
        "UT": "Utah",
        "VT": "Vermont",
        "VA": "Virginia",
        "WA": "Washington",
        "WV": "West Virginia",
        "WI": "Wisconsin",
        "WY": "Wyoming",
        "DC": "District of Columbia"
    ]

    private static let nameToAbbreviation: [String: String] = {
        var mapping: [String: String] = [:]
        for (abbr, name) in abbreviationToName {
            mapping[name.lowercased()] = abbr
        }
        return mapping
    }()

    static var allStates: [StateInfo] {
        abbreviationToName.map { StateInfo(fullName: $0.value, abbreviation: $0.key) }
    }
}
