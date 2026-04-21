# ALV Colour Code Reference — ZSO_REPORT_ALV

## Row Colour Mapping

| Constant | Code | Colour | GBSTK Value | Business Meaning |
|----------|------|--------|-------------|-----------------|
| `gc_clr_open` | `C310` | 🟢 Green | ` ` or `A` | Order is open, not yet processed |
| `gc_clr_part` | `C510` | 🟡 Yellow | `B` | Partially processed (e.g. partial delivery created) |
| `gc_clr_done` | `C110` | 🔵 Blue | `C` | Fully processed / completed |
| `gc_clr_blck` | `C610` | 🔴 Red | `D` | Blocked for further processing |
| `gc_clr_dflt` | `C010` | ⬜ White | Other | Unknown or unrecognised status |

## SAP ALV Colour Code Format

```
C [colour number] [intensity] [0]
 ─────┬──────── ──────┬────── ─┬─
      │               │        └── Always 0 (no special symbol)
      │               └─────────── 1 = Normal  |  2 = Intensified (bold)
      └─────────────────────────── Colour: 1=Blue 2=Grey 3=Green
                                           4=Brown/Orange 5=Yellow 6=Red
                                           7=Orange  8=Cyan  9=Purple
```

## Full SAP Colour Code Table

| Code | Normal (x10) | Intensified (x20) |
|------|-------------|-------------------|
| C1xx | Light Blue | Bold Blue |
| C2xx | Grey | Bold Grey |
| C3xx | Light Green | Bold Green |
| C4xx | Light Brown | Bold Brown |
| C5xx | Light Yellow | Bold Yellow |
| C6xx | Light Red / Pink | Bold Red |
| C7xx | Light Orange | Bold Orange |
| C0xx | White (default) | — |

## How Row Colours Work in the Program

The field `ROW_CLR` in the internal table `gt_orders` holds the colour code string (e.g., `C310`).
The layout setting `gst_layout-info_fname = 'ROW_CLR'` tells the ALV grid which field to read
for row-level colour control. The ALV then applies the colour automatically at render time.

The `FORM apply_row_colours` loops through `gt_orders` and sets both `ROW_CLR` (the technical
colour code) and `STAT_LBL` (the human-readable label shown in the Status column).
