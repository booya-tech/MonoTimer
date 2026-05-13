//
//  AppUpdateService.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 5/13/26.
//
//  Checks the App Store for a newer version via the iTunes Search API.
//  Fail-open: if the check fails, users are never blocked.
//

import Foundation

@MainActor
final class AppUpdateService {
    static let shared = AppUpdateService()

    private(set) var appStoreURL: URL?

    /// Returns true if the App Store version is newer than the installed version.
    /// Fail-open: returns false on any network or decode error.
    func checkForUpdate() async -> Bool {
        let bundleId = AppInfo.bundleIdentifier
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            return false
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(iTunesResponse.self, from: data)
            guard let result = response.results.first else { return false }

            appStoreURL = URL(string: "https://apps.apple.com/app/id\(result.trackId)")
            return isOutdated(installed: AppInfo.version, store: result.version)
        } catch {
            Logger.log("App update check failed: \(error.localizedDescription)")
            return false
        }
    }

    private func isOutdated(installed: String, store: String) -> Bool {
        let v1 = installed.split(separator: ".").compactMap { Int($0) }
        let v2 = store.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(v1.count, v2.count) {
            let a = i < v1.count ? v1[i] : 0
            let b = i < v2.count ? v2[i] : 0
            if a != b { return a < b }
        }
        return false
    }
}

private struct iTunesResponse: Decodable {
    let results: [iTunesResult]
}

private struct iTunesResult: Decodable {
    let version: String
    let trackId: Int
}
