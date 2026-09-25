# Rendering-mode spike

Throwaway. Answers one question: does a watch face hand a third-party
complication `fullColor`, or does it flatten our flag to a single tint?

Four widget variants render the same Brazilian flag four ways — a PNG asset,
the same asset with `widgetAccentedRenderingMode(.fullColor)`, the `🇧🇷`
emoji, and SwiftUI shapes. The rectangular and inline families print the
rendering mode they were handed, so screenshots label themselves.

## Running it

```sh
xcodebuild -project FlagSpike.xcodeproj -scheme FlagSpike -configuration Debug \
  -destination 'platform=watchOS Simulator,name=Apple Watch Ultra 3 (49mm)' \
  -derivedDataPath build build
xcrun simctl install <udid> build/Build/Products/Debug-watchsimulator/FlagSpike.app
```

Then add the four complications to a watch face by hand, and:

```sh
xcrun simctl io <udid> screenshot face.png
python3 Tools/analyze.py face.png
```

## Result, watchOS 26.5, Meridian circular sub-dials

Full colour. SwiftUI shapes measured 0.90-0.96 mean saturation, the emoji
0.72-0.73, both carrying all three flag hues (~45 deg yellow, ~135 deg green,
~210 deg blue). A flattened complication would show one hue.

Only Meridian was tested. Other faces may use `accented`.

### What this spike did not establish

Only two of the four variants ever landed in a slot: **shapes and emoji**. The
plain asset and `.fullColor` variants did not, and at the time that was written
off as safe, because rendering mode is a property of the slot rather than of
what you draw into it.

The inference was right about the mode and wrong about everything else. A
watchOS widget extension draws nothing at all for an asset catalogue image,
which this spike could not have caught: neither variant it measured was a
bitmap. The real app needed a separate fix, described in the complication
notes in the top-level README.

Worth remembering when reading any spike. It proves what it measured, not what
it was aimed at.

`Tools/analyze.py` prints a top-level verdict that averages the whole screen,
including the black surround; trust the per-region numbers instead.
