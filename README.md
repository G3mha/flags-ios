# Flags

Put a flag on your Apple Watch face, your Lock Screen, or your Home Screen.

I'm Brazilian and I'm studying abroad. I wanted my flag in the corner of my
watch face, so I'd see home every time I checked the time. That's the whole
idea.

Countries first. The model is built so other kinds of flags — clubs, games,
whatever — can be added later without touching the widgets.

## Does full colour actually work?

Yes. This mattered enough to test before writing the app, and then again after.

Complications render in one of three modes. In `fullColor` you get what you
drew. In `accented` and `vibrant` the system flattens your view, and which one
you get depends on the watch face — Apple's docs don't spell it out per face.

[`Spike/`](Spike) measured it first: on watchOS 26.5 the **Meridian** face's
circular sub-dials give third-party complications `fullColor`, at 0.90–0.96
mean saturation carrying all three of the Brazilian flag's hues.

Two caveats on that spike, because it was narrower than it looked. It measured
**SwiftUI shapes and emoji** — the asset-image variant never landed in a slot,
so the path the real app uses went untested for a long time afterwards. And
only Meridian was measured; other faces are untested.

`FlagView` draws the flag in **every** mode. It used to swap in the country
code whenever the mode was not `fullColor`, on the assumption that a flattened
flag would be an unreadable blob. That was wrong, and because iOS Lock Screen
accessories are always vibrant it meant they showed "BR" and nothing else.
Vibrant rendering maps luminance rather than discarding structure: the flag
comes through with its diamond, its disc and its stars. The country code
survives only as the fallback for artwork that fails to load.

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

One other thing trims the list, on unrelated grounds. Five ISO regions have no
permanent population and fly their parent's flag: Bouvet Island, Clipperton
Island, Diego Garcia, Heard & McDonald Islands, and the U.S. Outlying Islands.
Bouvet showing Norway's flag is correct, and it still reads as a bug to anyone
scrolling past it. `Countries.uninhabited` drops them.

That is a judgement about repeated artwork, not about who counts as a country,
which is why it is a separate set with its own test rather than entries in
`excluded`. Inhabited dependencies stay even when they share a flag — Réunion,
Mayotte and Svalbard among them — because someone lives there and may want to
pick where they are from. Ten entries still show the French tricolour.

Club crests and game logos are trademarked in a way country flags aren't.
That's a licensing problem for those packs, not a coding one.

## Artwork

257 country flags from [flag-icons](https://github.com/lipis/flag-icons) (MIT),
of which 252 are listed; the five unlisted ones above keep their artwork
because nothing looks them up. Four regions the set doesn't cover — Sark,
Ceuta & Melilla, Tristan da Cunha, Ascension Island — fall back to emoji
derived from the ISO code, so every country has a flag either way.

One flag is ours. flag-icons ships `sh.svg` as a byte-for-byte copy of
`gb.svg`, so Saint Helena flew a plain Union Jack instead of its own blue
ensign. [`Assets/flag-overrides`](Assets/flag-overrides) holds the replacement
and the reasoning; `fetch-flags.sh` applies anything there over the downloaded
set, so an upgrade can't undo the correction.

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
xcodebuild build -project Flags.xcodeproj -scheme Flags -destination 'generic/platform=iOS' -allowProvisioningUpdates
```

`-allowProvisioningUpdates` is needed for anything signed for a device. The
iCloud capability cannot go on a wildcard profile, so the team's App IDs have
to be explicit ones with iCloud enabled. Xcode.app registers those silently
the first time it builds; `xcodebuild` refuses to unless given that flag, and
fails with "provisioning profile doesn't include the iCloud capability".
Simulator builds need none of this.

## Complication artwork

Working, verified on a Meridian sub-dial: Brazil in full colour, all three
hues. Getting there took three separate bugs, and the notes below exist
because each one looked like something it wasn't.

**Where the catalogue lives.** It used to be a Swift package resource, and
`Image(_:bundle: .module)` rendered nothing for it inside a widget extension.
It now lives in `Assets/` as a member of all four targets, resolving through
`Bundle.main` like any ordinary widget asset.

**Why the artwork is redrawn on watchOS.** A watchOS widget extension draws
nothing for an image that came from an asset catalogue. The image is there —
`UIImage(named:)` returns it — but SwiftUI renders empty, which is why the
complication stayed blank while the watch app showed the same flag correctly.
`FlagView` redraws it through a `CGContext` first. iOS needs no such thing.

That one looks like a size limit and is not. Downscaling to 96px makes it
render, which is a convincing wrong answer; redrawing at the **same 384px**
also makes it render. What matters is a concrete bitmap, not a small one.

**Two red herrings**, both kept in the codebase untouched because neither was
at fault:

- An AppIntents error, `FlagEntity is not a registered AppEntity identifier`,
  fires on every watch snapshot. The flag resolves regardless.
- `recommendations()` changes nothing when emptied.

## Layout note

`Assets/Flags.xcassets` is deliberately outside the per-target synchronized
folders, referenced by all four targets. Keep it that way — putting it back in
a package resource bundle reintroduces the bug above.

## Favourites sync

Favourites follow the person between their iPhone and their Apple Watch,
through iCloud's key-value store. Chosen over WatchConnectivity because it
reaches every device they own rather than just the paired watch, survives a
reinstall, and needs no session plumbing.

Both targets carry the **iCloud → Key-value storage** capability, and both
entitlements in [`Config/`](Config) name the *same* store:

    $(TeamIdentifierPrefix)dev.enriccogemha.flags

That matters. The usual `$(CFBundleIdentifier)` would give the watch app its
own store — everything would appear to work, and the two devices would never
see each other's favourites.

Each flag records whether it is starred and when that last changed, and a
merge takes the later record per flag. A plain list of starred ids gives no
way to tell "this device has not heard about Japan yet" from "this device
deliberately unstarred Japan", so additions or removals would quietly go
missing depending which way the merge leaned.

Local `UserDefaults` remains the source of truth and is what gets read at
launch, so the list is instant and still works with no iCloud account and no
network. iCloud is the channel between devices, not the store.

Key-value storage does not travel between simulators, so the syncing paths
cannot be tried there. The tests in `FlagKitTests` drive them through a fake
store instead, which covers adopting what iCloud already holds, writing a star
through, and pulling another device's change in. Whether real iCloud delivers
that change still needs two real devices.

If the capability is ever removed, set `Favourites.cloudStore` back to nil.
Reaching for `NSUbiquitousKeyValueStore.default` without the entitlement logs
a fault on every launch and syncs nothing.

Favourites live in the **app group** `group.dev.enriccogemha.flags`, not in
`UserDefaults.standard`. A widget extension gets its own data container, so
`.standard` inside one is a different store from the app's — a flag starred in
the app is simply not there when the complication gallery looks. All four
targets carry the group; only the two apps carry iCloud, since the extensions
read what the app has already written and nothing more.

The two are doing different jobs. The group shares within one device, between
an app and its extensions. iCloud shares between devices. Favourites need both.

## The complication gallery

On the watch this is not a shortlist among other ways in. **The complication
picker offers what `recommendations()` returns and nothing else** — there is no
browse behind it, and no search. A flag missing from that list cannot go on a
watch face at all. Everything below follows from that.

`recommendations()` leads with favourites, then flags opened recently, then the
device's region, then the default, dropping duplicates. Starring a flag on the
phone puts it in the watch's gallery, since favourites travel over iCloud.

Recents exist so that putting a flag on a face does not require committing it
to a permanent list. Opening a flag's page is a weaker signal than starring it
and a fair one: it is what someone is already doing just before they go looking
for the watch face. `Recents` is per-device and not synced — favourites say what
someone cares about and belong everywhere, recents say what they were looking at
on this device.

The cap is 25, which is larger than a shortlist would want. Anything cut is a
flag that cannot reach a watch face, and the gallery scrolls, so a longer list
is the cheaper mistake.

`Favourites.storedIDs` exists because `recommendations()` is nonisolated and
synchronous and cannot build a main-actor `Favourites`. It reads the same JSON
straight out of the shared container.

Starring a flag also calls `invalidateConfigurationRecommendations()`. Without
it the shortlist is cached and a newly starred flag never reaches the gallery —
verified in the simulator, where it stayed stale across a reinstall and a
reboot until that call was added.

None of this limits what can be chosen. The shortlist is a convenience; the
complication's own settings list every flag with a search field.

Note that the entitlements live in `Config/` rather than beside the sources:
`Flags/` and `FlagsWatch/` are synchronized folders, so a file dropped in one
becomes a bundled resource.

## Before shipping## Before shipping

- The region list comes from `Locale`, so it shifts with the OS version. It's
  close to ISO 3166-1 but not identical — `XK` for Kosovo is a user-assigned
  code the standard doesn't define. A test asserts the count stays between
  200 and 400 so an OS change can't quietly empty or explode it.
- App icons are placeholders. Confirmed in the log:
  `IconServices: Failed to find icon resources for bundle identifier
  dev.enriccogemha.flags.watchkitapp`.

## Licence

MIT. See [LICENSE](LICENSE).

The bundled artwork is flag-icons, also MIT; its notice ships beside the
catalogue as `flag-icons-LICENSE.txt`. The one flag we assembled ourselves
combines flag-icons' Union Jack with a public-domain coat of arms, both
recorded in [`Assets/flag-overrides/README.md`](Assets/flag-overrides/README.md).
