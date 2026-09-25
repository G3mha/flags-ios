# Flag overrides

Artwork we supply ourselves, replacing what flag-icons ships. `fetch-flags.sh`
copies anything here over the downloaded set before rasterising, so upgrading
flag-icons cannot quietly undo a correction.

Keep this short. An override is a maintenance cost and a second licence to
track, so each one needs a reason that upstream has not already fixed.

## sh.svg — Saint Helena

flag-icons ships `sh.svg` as a byte-for-byte copy of `gb.svg`, in both the 4x3
and 1x1 sets. Without this file the app shows Saint Helena flying a plain
Union Jack. Checked against v7.5.0 and against `main` on 2026-09-25; v7.5.0 is
the latest release, so upgrading does not fix it.

The real flag is a blue ensign with the territory's coat of arms in the fly:
a shield showing the Saint Helena plover — the wirebird — above a three-masted
ship and the island's cliffs.

Assembled from two sources, both usable here:

- The Union Jack canton is flag-icons' own `gb.svg` from the 1x1 set, scaled
  by half into the upper-left quarter. MIT, and already shipped as `flag-gb`,
  so it adds no licence that was not already in the catalogue. Using their
  square Union Jack rather than squashing the 2x1 one keeps the canton
  matching every other ensign in the set.
- The coat of arms is the `coa` group lifted from [Flag of Saint Helena.svg]
  on Wikimedia Commons, by Patricia Fidi, released into the public domain.
  Scaled by 512/600 and centred in the fly half, which is where it sits on the
  real flag.

Commons tags the file "insignia": depicting an official emblem can be
regulated separately from copyright. That applies to every flag in this app
and is not a copyright restriction.

[Flag of Saint Helena.svg]: https://commons.wikimedia.org/wiki/File:Flag_of_Saint_Helena.svg

Drop this file and rerun `Tools/fetch-flags.sh` if flag-icons ever fixes it.
