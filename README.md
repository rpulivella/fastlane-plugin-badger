# fastlane-plugin-badger

A fastlane plugin that composites version/build text badges and diagonal corner
ribbon banners onto your app icons at build time — using ImageMagick locally.

**No shields.io. No network calls. No static PNGs committed to the repo.**

Works identically on developer machines and CI. All rendering is done by the
`magick` binary via [mini_magick](https://github.com/minimagick/minimagick).

---

## Why badger?

The conventional approach (`fastlane-plugin-badge`) fetches raster PNGs from
shields.io at build time. This breaks on poor connections, fails entirely when
shields.io is unreachable, and produces low-resolution results on 1024 px icons.

Badger generates everything locally:

| Feature | shields.io approach | badger |
|---|---|---|
| Network required | Yes | No |
| Offline / CI-safe | No | Yes |
| Resolution-independent | No | Yes |
| Custom fonts | No | Yes (bundled OFL) |
| Corner ribbon banners | No | Yes |

---

## Prerequisites

- **ImageMagick 7+** — the `magick` binary must be in `PATH`.
  ```sh
  brew install imagemagick   # macOS
  ```
- **Ruby 2.6+**
- **mini_magick** gem (declared as a dependency, installed automatically)

---

## Installation

Add to your `Pluginfile`:

```ruby
# Pluginfile
gem "fastlane-plugin-badger", git: "https://github.com/rpulivella/fastlane-plugin-badger"
```

Then run:

```sh
bundle exec fastlane install_plugins
```

### Font setup

Badger ships with placeholder slots for two fonts. Copy them into
`assets/fonts/` inside the gem directory (or fork and commit them — both are
OFL-licensed so they are freely bundleable):

| File | Used for |
|---|---|
| `JetBrainsMonoNL-Bold.ttf` | Version/build/ticket text badges |
| `Figtree-Black.otf` | Corner ribbon banners |

**JetBrains Mono NL Bold** — [jetbrains.com/lp/mono](https://www.jetbrains.com/lp/mono/)
SIL Open Font License 1.1.

**Figtree Black** — [fonts.google.com/specimen/Figtree](https://fonts.google.com/specimen/Figtree)
SIL Open Font License 1.1.

Both fonts can be committed to your repo without attribution requirements
(check the individual license files to confirm for your use case).

---

## Actions

### `stamp_version_badge`

Stamps a two-tone text badge showing the version and build number at the top
of every matched icon.

The badge is gray on the left (version) and orange on the right (build):

```
 1.5.2 | 1234
```

```ruby
stamp_version_badge(
  version:   "1.5.2",   # required if xcodeproj not provided
  build:     "1234",    # required if xcodeproj not provided
  xcodeproj: "Slyyd/Slyyd.xcodeproj",  # optional — auto-reads version/build
  icon_glob: "**/AppIcon.appiconset/*.png"  # default
)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `version` | String | — | App version, e.g. `"1.5.2"`. Overrides xcodeproj. |
| `build` | String | — | Build number, e.g. `"1234"`. Overrides xcodeproj. |
| `xcodeproj` | String | — | Path to `.xcodeproj` for auto-reading version/build. |
| `icon_glob` | String | `**/AppIcon.appiconset/*.png` | Glob to discover icons. |

---

### `stamp_label_badge`

Stamps a single full-orange badge showing a JIRA ticket or label at
the center of every matched icon.

```ruby
stamp_label_badge(
  ticket:    "LIG-2969",
  icon_glob: "**/AppIcon.appiconset/*.png"  # default
)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `ticket` | String | — | JIRA ticket or label, e.g. `"LIG-2969"`. |
| `icon_glob` | String | `**/AppIcon.appiconset/*.png` | Glob to discover icons. |

To combine a version badge with a ticket badge in a single lane:

```ruby
stamp_version_badge(version: "1.5.2", build: "1234")
stamp_label_badge(ticket: "LIG-2969")
```

---

### `stamp_corner_banner`

Stamps a diagonal corner ribbon (e.g. "ALPHA", "BETA", "NDA") over every
matched icon. The ribbon runs edge-to-edge — the canvas clips it naturally,
giving a clean built-in look without any pill shape.

```ruby
stamp_corner_banner(
  label:     "ALPHA",
  corner:    "bottom_right",  # default
  style:     "dark",          # default
  size:      "normal",        # default
  icon_glob: "**/AppIcon.appiconset/*.png"
)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `label` | String | — | Ribbon text. Automatically uppercased. |
| `corner` | String | `"bottom_right"` | `bottom_right`, `bottom_left`, `top_right`, `top_left` |
| `style` | String | `"dark"` | `dark` — `#1c1c1e` bg, white 72% text. `light` — `#efefef` bg, dark 72% text. |
| `size` | String | `"normal"` | `normal` — ribbon = 14% of icon. `large` — ribbon = 17% of icon. |
| `icon_glob` | String | `**/AppIcon.appiconset/*.png` | Glob to discover icons. |

#### Corner positions

```
top_left      top_right
  ╲               ╱
   ───────────────
  |               |
   ───────────────
  ╱               ╲
bottom_left   bottom_right   ← default
```

#### Size guide

Use `:normal` for labels with 4+ characters (ALPHA, BETA, PREVIEW).
Use `:large` for short labels (NDA, QA) — the extra ribbon thickness fills
the visual weight left by fewer letters.

#### Style guide

Use `:dark` on colorful icons where you need the banner to "pop" against the
background. Use `:light` when the icon is predominantly dark and you want a
subtler treatment.

---

## Typical Fastfile usage

### Alpha Firebase build

```ruby
lane :deploy_alpha do
  stamp_version_badge(
    xcodeproj: "Slyyd/Slyyd.xcodeproj"
  )
  stamp_corner_banner(
    label:  "ALPHA",
    corner: "bottom_right",
    style:  "dark",
    size:   "normal"
  )
  # ... build and distribute
end
```

### NDA Beta build

```ruby
lane :deploy_nda_beta do
  stamp_version_badge(
    xcodeproj: "Slyyd/Slyyd.xcodeproj"
  )
  stamp_corner_banner(
    label:  "NDA",
    corner: "bottom_right",
    style:  "dark",
    size:   "large"   # :large because NDA is a short label
  )
  # ... build and distribute
end
```

### Branch / PR build

```ruby
lane :deploy_pr_build do
  ticket = ENV["CIRCLE_BRANCH"]&.match(/LIG-\d+/)&.[](0) || "DEV"
  stamp_version_badge(xcodeproj: "Slyyd/Slyyd.xcodeproj")
  stamp_label_badge(ticket: ticket)
  stamp_corner_banner(label: "PREVIEW", style: "dark")
  # ... build and distribute
end
```

---

## Corner banner design notes

The ribbon is generated in three passes:

1. **Solid rectangle** — fills the ribbon area with the background color.
2. **CopyOpacity mask** — renders white-bg / black-text, then uses
   `CopyOpacity` composite to punch transparent holes in the shape of each
   letter. White areas remain opaque ribbon; black areas become fully
   transparent.
3. **Re-annotate at 72% opacity** — fills the transparent holes with the text
   color at 72% opacity, letting a sliver of the background bleed through.
   This produces a subtle "knockout" feel that reads as softer than a flat
   fill.

The ribbon rectangle is 165% of the icon width so it always extends past both
canvas edges regardless of label length. ImageMagick clips at the canvas
boundary automatically.

A drop shadow (`60x10+0+5`) is applied to the rotated ribbon before it is
composited onto the icon canvas.

---

## Running tests

```sh
bundle exec rake spec
```

---

## License

MIT — see [LICENSE](LICENSE).

Font licenses:
- JetBrains Mono: SIL Open Font License 1.1
- Figtree: SIL Open Font License 1.1
