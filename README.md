# Flags

Put a flag on your Apple Watch face, your Lock Screen, or your Home Screen.

I'm Brazilian and I'm studying abroad. I wanted my flag in the corner of my
watch face, so I'd see home every time I checked the time. That's the whole
idea.

Countries first. The model is built so other kinds of flags — clubs, games,
whatever — can be added later without touching the widgets.

## Does full colour actually work?

Yes, on some watch faces. This mattered enough to test before writing the app.

Complications render in one of three modes. In `fullColor` you get what you
drew. In `accented` and `vibrant` the system flattens your view into flatly
coloured groups, and a flag's colours are gone. Which one you get depends on
the watch face, and Apple's docs don't spell it out per face.

So [`Spike/`](Spike) measured it. On watchOS 26.5, the **Meridian** face's
circular sub-dials give third-party complications `fullColor`: the flag
rendered at 0.90–0.96 mean saturation carrying all three of its hues. A
flattened complication would have shown one.

Only Meridian was measured. Infograph and the rest are untested.

Other faces use `accented`. So `FlagView` branches on `widgetRenderingMode`
and draws the country code when it can't draw the flag — a flattened flag is
an unreadable blob, but "BR" stays legible at 30 points.

## Layout

```
Packages/FlagKit/     model, registry, rendering, widget configuration
Flags/                iOS app
FlagsWidgets/         Home Screen and Lock Screen widgets
FlagsWatch/           watchOS app
FlagsWatchWidgets/    complications
Spike/                throwaway that answered the question above
Tools/                optional asset pipeline
```

`Flags.xcodeproj` uses file-system synchronized folders, so adding a source
file doesn't touch the project file.

## Adding a collection

Conform to `FlagCollection` and add it to `FlagRegistry.shared`. The picker,
the widget configuration and both extensions read from the registry, so
nothing else changes.

```swift
enum Clubs: FlagCollection {
    static let id = "clubs"
    static let displayName = "Clubs"
    static var flags: [Flag] { ... }
}
```

Flag IDs are `collection/code`, so `countries/br` and `clubs/palmeiras` coexist.

## Flag politics

Flags are political and Apple has pulled apps over specific ones, so this
needed a position rather than a default.

The position is that shipping the standard list is more defensible than
curating it. The basis is the system's own region list rather than our
judgement about who counts as a country, so `Countries.excluded` is empty and
stays that way. Palestine, Kosovo and Western Sahara all ship. Pulling a flag
worldwide to satisfy one storefront would cost every user while making that
neutral basis harder to defend, not easier.

The one exception is where the platform already restricts, and there we
restrict the same way. Apple removes the Taiwan flag from the system emoji
font on devices set to China mainland, and hides it from the emoji keyboard in
Hong Kong and Macau while still rendering it. While artwork was emoji we
inherited all of that for free; bundling SVGs took the responsibility on.
`Countries.restrictions` restores it, with the two tiers kept distinct — an
already-configured complication in Hong Kong keeps working.

`Countries.excluded` is where a takedown request should land. A test asserts
it's empty, so filling it is a deliberate act with a reason attached.

Club crests and game logos are trademarked in a way country flags aren't.
That's a licensing problem for those packs, not a coding one.

## Artwork

257 country flags from [flag-icons](https://github.com/lipis/flag-icons) (MIT),
bundled as SVG. Anything that set doesn't cover falls back to emoji derived
from the region code, so every country has a flag either way.

[`Tools/fetch-flags.sh`](Tools/fetch-flags.sh) regenerates the catalogue and
pins the flag-icons version. It caps each SVG's intrinsic size at 160pt:
without that Xcode rasterises up to 1536 and the catalogue is 7.8MB instead of
2.6MB. 160 x 3 = 480px, which is what the largest use — an iOS `systemSmall`
widget at 3x — actually needs.

Size is worth watching. Every target that links FlagKit carries its own 2.6MB
copy of the catalogue, so the watch app is 6.5MB and the iOS app 20MB
including the embedded watch app.

Making FlagKit a dynamic library does not fix this. Measured: the watch app
goes to 5.6MB, and that 0.9MB is deduplicated code — SPM still copies the
resource bundle into the extension. Not worth the launch cost in a
complication, so FlagKit stays static.

## Building

```sh
swift test --package-path Packages/FlagKit
xcodebuild build -project Flags.xcodeproj -scheme Flags -destination 'generic/platform=iOS'
```

## Known bug: the complication renders nothing

**The watch complication does not work yet.** Added to a face, it shows the
redacted placeholder forever and never displays a flag. The app itself renders
all 257 flags correctly, and everything builds and tests green — only a real
complication on a real face exposes this.

What the system log says on every timeline request:

```
FlagsWatchWidgets: (WidgetKit) [com.apple.chrono:timeline]
Request ended for dev.enriccogemha.flags.flag:accessoryCircular
- error: CHSErrorDomain Code=1101
  "Returned view collection was either nil or empty."
```

Ruled out by experiment, not reasoning:

- **Not the view code.** Replacing the whole widget body with
  `ZStack { Color.red; Text(...) }` reproduces it.
- **Not App Intents metadata.** Adding `AppIntentsPackage` put
  `extract.packagedata` in the extension bundle; behaviour unchanged.
- **Not a crash**, and not Always-On redaction — it persists on a woken screen.
- **Not a stale configuration.** Removing and re-adding the complication after
  the metadata fix changes nothing.

Leads worth pursuing:

- The spike worked using `StaticConfiguration`; this uses
  `AppIntentConfiguration`. That is the remaining structural difference.
  Swapping the widget to `StaticConfiguration` temporarily would isolate it,
  at the cost of orphaning any placed complication.
- Returning four entries with `.atEnd` instead of one with `.never` made the
  1101 error stop appearing in the log, but produced no visible change. Not
  committed, since it fixes nothing observable.

## Before shipping

- The region list comes from `Locale`, so it shifts with the OS version. It's
  close to ISO 3166-1 but not identical — `XK` for Kosovo is a user-assigned
  code the standard doesn't define. A test asserts the count stays between
  200 and 400 so an OS change can't quietly empty or explode it.
- App icons are placeholders. Confirmed in the log:
  `IconServices: Failed to find icon resources for bundle identifier
  dev.enriccogemha.flags.watchkitapp`.

## Licence

MIT. See [LICENSE](LICENSE).
