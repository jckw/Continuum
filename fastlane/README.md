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

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the app

### ios test

```sh
[bundle exec] fastlane ios test
```

Run tests

### ios build_dev

```sh
[bundle exec] fastlane ios build_dev
```

Build for development

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload to TestFlight (internal only)

### ios beta_external

```sh
[bundle exec] fastlane ios beta_external
```

Upload to TestFlight and distribute to external testers

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload metadata only (no build)

### ios release

```sh
[bundle exec] fastlane ios release
```

Upload to App Store with metadata

### ios submit

```sh
[bundle exec] fastlane ios submit
```

Submit for review (after release)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
