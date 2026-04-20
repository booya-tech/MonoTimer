fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test

```sh
[bundle exec] fastlane ios test
```

Run all unit and UI tests

### ios build_only

```sh
[bundle exec] fastlane ios build_only
```

Build app archive without uploading

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Submit to App Store for review

### ios bump_patch

```sh
[bundle exec] fastlane ios bump_patch
```

Increment patch version number (app + widget)

### ios bump_minor

```sh
[bundle exec] fastlane ios bump_minor
```

Increment minor version number (app + widget)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
