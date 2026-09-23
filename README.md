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

So [`Spike/`](Spike) measured it. On watchOS 26.5, Infograph's circular
sub-dials give third-party complications `fullColor`: the flag rendered at
0.90–0.96 mean saturation carrying all three of its hues. A flattened
complication would have shown one.

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

Note that club crests are trademarked in a way country flags aren't. That's a
licensing problem, not a coding one.

## Artwork

Country artwork is emoji derived from the ISO 3166-1 code, so every country
has a flag with nothing bundled and nothing to license.

The trade-off is that emoji are drawn by the system font: Apple's design
rather than ours, no control over detail at complication size, and nothing for
regions the font omits. [`Tools/fetch-flags.sh`](Tools/fetch-flags.sh) swaps in
the [flag-icons](https://github.com/lipis/flag-icons) SVG set (MIT) when you
want that control.

## Building

```sh
swift test --package-path Packages/FlagKit
xcodebuild build -project Flags.xcodeproj -scheme Flags -destination 'generic/platform=iOS'
```

## Before shipping

- `Countries.excluded` is empty. Flags are political and Apple has pulled apps
  over specific ones. Audit that list deliberately rather than shipping
  whatever `Locale` happens to return.
- The country list comes from `Locale`, so it shifts with the OS version.

## Licence

MIT. See [LICENSE](LICENSE).
