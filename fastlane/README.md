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

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Push fastlane/metadata to App Store Connect. Previews first; pass force:true to skip.

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Push fastlane/screenshots to App Store Connect. Leaves metadata alone.

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build the app and upload it to TestFlight. Does not submit anything.

### ios submit

```sh
[bundle exec] fastlane ios submit
```

Submit the current version for review. The one lane that is not a dry run.

### ios whoami

```sh
[bundle exec] fastlane ios whoami
```

Check the key actually works, without changing anything.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
