//
//  AppAsset.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/12/26.
//

// MARK: - AppAsset naming convention
//
// Rule: Asset name must start with a type prefix, then follow with a clear, descriptive snake_case name.
// Example: "ic_home", "img_empty_portfolio"
//
// Prefix mapping:
// - ic_   = icon
// - img_  = image / photo / illustration
// - bg_   = background
// - logo_ = logo
// - tab_  = tab bar icon
//
// Notes:
// - Keep names stable (renaming affects runtime loading).
// - Avoid duplicates across catalogs/bundles.
// - Prefer grouping new assets in the matching section below.
public enum AppAsset {
    // MARK: Icons (ic_)
    public enum Icon {
        // Add ic_ assets here
    }

    // MARK: Images (img_)
    public enum Image {
        // Add img_ assets here
    }

    // MARK: Backgrounds (bg_)
    public enum Background {
        // Add bg_ assets here
    }

    // MARK: Logos (logo_)
    public enum Logo {
        // Add logo_ assets here
    }

    // MARK: Tab bar icons (tab_)
    public enum Tab {
        // Add tab_ assets here
    }
}
