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

257 country flags from [flag-icons](https://github.com/lipis/flag-icons) (MIT).
Four regions the set doesn't cover — Sark, Ceuta & Melilla, Tristan da Cunha,
Ascension Island — fall back to emoji derived from the ISO code, so every
country has a flag either way.

They ship as PNG, not SVG, and that matters. Xcode's asset catalogues accept
SVG but implement only a subset of it: 71 of these flags use `clipPath` and 60
use `<use>`. Those compiled without complaint and rendered **wrong** — Burundi
came out a black square, Cameroon yellow smears. A quarter of the set was
broken and nothing but looking at the screen would have caught it.

[`Tools/rasterise.swift`](Tools/rasterise.swift) renders each file through
WebKit, which is a complete SVG engine and already on the machine, so this
needs no dependency. Output is opaque and 384px square: the alpha channel is
waste on flags that are opaque squares, and 384 covers the largest real use —
an iOS `systemSmall` widget at 3x — while the watch never asks for more than
about 110px.

    catalogue   3.4MB      watch app  8.5MB      iOS app  16MB

The catalogue is duplicated into all four targets, so every byte is paid four
times. The iOS app still comes in under the old SVG build because Xcode was
rasterising each SVG at three scales where one PNG now serves.

[`Tools/fetch-flags.sh`](Tools/fetch-flags.sh) does the whole pipeline —
download, pin the version, rasterise — so none of this is a one-off.

## Building

```sh
swift test --package-path Packages/FlagKit
xcodebuild build -project Flags.xcodeproj -scheme Flags -destination 'generic/platform=iOS'
```

## Complication artwork: what's verified

**Full colour works.** Brazil rendered in a real complication on a real
Meridian sub-dial, all three hues present. That is the premise of the app,
confirmed end to end rather than inferred.

**The asset path had a bug**, found the same way. SwiftUI's
`Image(_:bundle:)` renders nothing for these assets inside a widget
extension, so the complication was blank. The catalogue is not the problem:
`assetutil` shows the app's and the extension's `Assets.car` both carrying all
514 entries, `Bundle.module` resolves, and the identical call works in the app.

It was isolated by putting a colour behind the image. Both a
`StaticConfiguration` and an `AppIntentConfiguration` complication showed the
colour at 0.92-0.96 saturation, unredacted, with nothing drawn over it.
Swapping that one branch to emoji rendered the flag. So the view, the
timeline and the configuration type were all fine - only the asset lookup
was broken.

`FlagView` now resolves through `UIImage(named:)` against `Bundle.main`, and
falls back to the country code when lookup fails so a complication can never
be blank again.

The catalogue itself moved out of the package: it lives in `Assets/` and is a
member of all four targets, so it resolves the ordinary way every widget does
rather than through an SPM resource bundle. Verified in the built products -
no package bundle remains, and each of the four bundles carries the flags in
its own `Assets.car`. Total app size is unchanged at 20MB.

**Still unverified at runtime.** The simulator's widget caching blocked every
attempt: it served stale extension binaries to freshly added complications
through reinstalls and reboots, and after the move it would not surface the
widget in the complication gallery at all despite the log showing its kind
registered. Confirm on a device.

## Layout note

`Assets/Flags.xcassets` is deliberately outside the per-target synchronized
folders, referenced by all four targets. Keep it that way — putting it back in
a package resource bundle reintroduces the bug above.

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
