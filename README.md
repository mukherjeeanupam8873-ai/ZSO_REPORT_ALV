# ZSO_REPORT_ALV — SAP ABAP Sales Order ALV Dashboard

> **Author:** Anupam Mukherjee &nbsp;|&nbsp; **Roll No:** 2305197 &nbsp;|&nbsp; **Batch:** SAP ABAP Developer &nbsp;|&nbsp; **Institute:** KIIT University

---

## Overview

`ZSO_REPORT_ALV` is a custom SAP ABAP report that displays Sales Order data in a fully interactive ALV (ABAP List Viewer) Grid. It joins three standard SAP tables — `VBAK`, `VBAP`, and `KNA1` — in a single SQL statement to present order headers, line items, and customer details together in one consolidated dashboard.

The program is built using the **Object-Oriented ALV approach** (`CL_GUI_ALV_GRID`) with a `CL_GUI_DOCKING_CONTAINER`, and includes selection screen filters, row-level colour coding by order status, hotspot drill-down navigation to VA03, and layout variant persistence.

---

## Features

| Feature | Details |
|---|---|
| **Three-Table JOIN** | `VBAK` (header) + `VBAP` (items) + `KNA1` (customer) in one `SELECT` |
| **Selection Screen** | Filter by Sales Org, Customer, Material, Status, and Date Range |
| **Row Colour Coding** | Green = Open, Yellow = In Progress, Blue = Completed, Red = Blocked |
| **Hotspot Navigation** | Click any Order Number to open `VA03` (Display Sales Order) |
| **Layout Variants** | Users can save and restore personal column layouts via `DISVARIANT` |
| **Dual Output Mode** | Interactive ALV Grid or printable list via `REUSE_ALV_GRID_DISPLAY_LVC` |
| **Input Validation** | Date range and row-limit validation in `AT SELECTION-SCREEN` |
| **Authority Check** | Checks `V_VBAK_VKO` authorisation object before reading data |
| **OO Event Handler** | `lcl_alv_handler` class handles toolbar commands and cell clicks |
| **Object Cleanup** | Container and grid objects freed cleanly on screen exit |

---

## Technical Stack

| Component | Object / Transaction |
|---|---|
| Language | SAP ABAP 7.40+ |
| ALV Framework | `CL_GUI_ALV_GRID` (OO ALV) |
| Container | `CL_GUI_DOCKING_CONTAINER` |
| DB Tables | `VBAK`, `VBAP`, `KNA1` |
| Screen | Dynpro Screen 100 (SE51) |
| GUI Status | `ZAM_STATUS` (SE41) |
| Title Bar | `ZAM_TITLE` (SE41) |
| Program Editor | SE38 |
| Authorisation Object | `V_VBAK_VKO` |

---

## Project Structure

```
ZSO_REPORT_ALV/
│
├── src/
│   └── ZSO_REPORT_ALV.abap       ← Main ABAP program source
│
├── docs/
│   ├── SETUP.md                  ← SAP system setup instructions
│   ├── FIELD_CATALOGUE.md        ← All 16 output columns documented
│   └── COLOUR_CODES.md           ← ALV colour code reference
│
├── config/
│   └── transport_notes.md        ← Transport request guidance
│
├── .gitignore
├── LICENSE
└── README.md
```

---

## SAP Setup Instructions

### Step 1 — Create the Program (SE38)
1. Open Transaction `SE38`
2. Enter program name `ZSO_REPORT_ALV`, click **Create**
3. Set type as **Executable Program**, enter a short description
4. Copy-paste the contents of `src/ZSO_REPORT_ALV.abap`
5. Activate with `Ctrl+F3`

### Step 2 — Create Screen 100 (SE51)
1. Open Transaction `SE51`, select program `ZSO_REPORT_ALV`, screen `0100`
2. Create a **Normal** screen with the short description `ALV Dashboard`
3. The program uses `CL_GUI_DOCKING_CONTAINER` which does **not** require a Custom Control element — the screen can be left empty
4. Add PBO module `INIT_SCREEN_100` and PAI module `PROCESS_USER_CMD` to the Flow Logic
5. Activate the screen

### Step 3 — Create GUI Status (SE41)
1. Open Transaction `SE41`, select program `ZSO_REPORT_ALV`
2. Create a GUI Status named `ZAM_STATUS`
3. Add the following function codes to the toolbar:

| Function Code | Icon / Button | Description |
|---|---|---|
| `BACK` | Back arrow | Navigate back |
| `EXIT` | Exit door | Exit program |
| `CANCEL` | X button | Cancel / close |
| `ZAM_REFRESH` | Refresh icon | Re-fetch data |

4. Create a Title Bar named `ZAM_TITLE` with text `Sales Order Dashboard`
5. Activate both objects

### Step 4 — Run the Report (SA38)
1. Open Transaction `SA38`, enter `ZSO_REPORT_ALV`
2. Press **F8** to execute
3. Enter selection criteria and click **Execute**

---

## Output Columns

| Column | Source | Description |
|---|---|---|
| Order No. | VBAK-VBELN | Sales document number (hotspot — click to open VA03) |
| Order Date | VBAK-AUDAT | Date the order was created |
| Sales Org | VBAK-VKORG | Sales organisation key |
| Customer | VBAK-KUNNR | Sold-to customer number |
| Customer Name | KNA1-NAME1 | Full customer name from master data |
| City | KNA1-ORT01 | Customer city |
| Country | KNA1-LAND1 | Customer country |
| Item | VBAP-POSNR | Line item number within the order |
| Material | VBAP-MATNR | Material number |
| Description | VBAP-ARKTX | Item short text |
| Quantity | VBAP-KWMENG | Confirmed order quantity |
| UoM | VBAP-VRKME | Unit of measure |
| Unit Price | VBAP-NETPR | Net price per unit |
| Order Value | VBAK-NETWR | Total net value of the order |
| Currency | VBAK-WAERK | Document currency |
| Status | Computed | Human-readable order status |

---

## Row Colour Legend

| Colour | GBSTK Value | Meaning |
|---|---|---|
| 🟢 Green | ` ` or `A` | Open — not yet processed |
| 🟡 Yellow | `B` | In Progress — partial delivery |
| 🔵 Blue | `C` | Completed — fully processed |
| 🔴 Red | `D` | Blocked |
| ⬜ White | Other | Unknown status |

---

## Notes

- The program uses a `CL_GUI_DOCKING_CONTAINER` instead of a `CL_GUI_CUSTOM_CONTAINER`. This means Screen 100 does **not** need a Custom Control element drawn in SE51 — the docking container attaches itself to the screen edge automatically.
- Layout variants are saved per user under the variant name entered in the selection screen (default: `/STANDARD`).
- The authority check validates `V_VBAK_VKO` with activity `03` (Display). Ensure your test user has this authorisation or comment out the check in a sandbox environment.
- Text elements (`TEXT-s01`, `TEXT-s02`) must be created in SE38 under **Goto → Text Elements → Text Symbols**.

---

## License

This project is submitted as academic coursework at KIIT University. See `LICENSE` for terms.
