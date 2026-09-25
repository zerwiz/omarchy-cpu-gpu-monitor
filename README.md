# CPU/GPU Monitor

An Omarchy bar widget that shows live CPU and GPU load, with a details panel
for per-core-adjacent CPU breakdown, GPU temperature/power/memory, and one-click
switching between power profiles.

## Install

```sh
omarchy plugin add https://github.com/zerwiz/omarchy-cpu-gpu-monitor.git --enable
```

## Usage

- **Left-click** the bar icon to open the details panel; click again to close.
- **Arrow keys** move the profile selection; **Enter** applies the selected
  power profile.
- **Escape** closes the panel.

The bar glyph shows GPU utilisation when GPU reporting is on, otherwise CPU
utilisation.

## Configure

Settings are exposed through the shell's plugin settings panel. You can also
move the widget between bar sections:

```sh
omarchy bar move io.github.zerwiz.cpu-gpu-monitor --section right
```

| Setting | Default | Meaning |
| --- | --- | --- |
| `refreshIntervalSec` | `3` | Poll interval, 1–30 seconds |
| `showCpu` | `true` | Show CPU load |
| `showGpu` | `true` | Show GPU load |
| `showPowerProfiles` | `true` | Show power profile controls |

## Requirements

- Omarchy Quattro (schema version 1 shell plugins).
- `nvidia-smi` on `PATH` for GPU figures (the widget degrades to CPU-only if absent).
- `omarchy-powerprofiles-list` / `omarchy-powerprofiles-set` for the profile controls.

## Remove

```sh
omarchy plugin remove io.github.zerwiz.cpu-gpu-monitor
```

## Contributors

See [CONTRIBUTORS.md](CONTRIBUTORS.md) — **zerwiz (Josef Lindbom)**, author and
maintainer.

## License

MIT — see [LICENSE](LICENSE).
