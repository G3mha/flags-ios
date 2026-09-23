import AppIntents

/// Exports FlagKit's App Intents metadata to the targets that link it.
///
/// Without this, an intent defined in a package is visible to the app (which
/// carries its own metadata) but not to a widget extension, which then cannot
/// decode its stored configuration and shows the redacted placeholder forever.
///
/// Each extension declares its own `AppIntentsPackage` naming this one.
public struct FlagKitAppIntents: AppIntentsPackage {}
