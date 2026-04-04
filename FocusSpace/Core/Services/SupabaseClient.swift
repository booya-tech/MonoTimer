//
//  SupabaseClient.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/24/25.
//
//  Supabase configuration and client setup
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    /// Supabase client - nil if configuration is missing
    let client: SupabaseClient?
    
    /// Whether Supabase is properly configured
    var isConfigured: Bool { client != nil }

    private init() {
        guard let supabaseURLString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !supabaseURLString.isEmpty,
              let supabaseURL = URL(string: supabaseURLString) else {
            print("⚠️ SUPABASE_URL is missing or invalid in Info.plist")
            self.client = nil
            return
        }

        guard let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !supabaseKey.isEmpty else {
            print("⚠️ SUPABASE_ANON_KEY is missing or invalid in Info.plist")
            self.client = nil
            return
        }

        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )

        #if DEBUG
        print("✅ Supabase configured: \(supabaseURL.host ?? "unknown")")
        #endif
    }
}
