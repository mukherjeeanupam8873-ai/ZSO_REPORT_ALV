# Setup Guide — ZSO_REPORT_ALV

This document walks through every SAP transaction needed to set up and run `ZSO_REPORT_ALV` from scratch in any SAP ECC or S/4HANA system.

---

## Prerequisites

- SAP GUI installed and connected to your SAP system
- Developer access (S_DEVELOP authorisation object)
- A development package or `$TMP` for local (non-transportable) objects
- At least one Sales Order in the system (use VA01 to create test data if needed)

---

## Step 1 — Create the Program in SE38

1. Open **Transaction SE38**
2. Type `ZSO_REPORT_ALV` in the Program field and click **Create**
3. Fill in the attributes:
   - **Title:** Sales Order ALV Dashboard
   - **Type:** Executable Program
   - **Status:** Test Program (or Production if transporting)
   - **Application:** SD (Sales and Distribution)
4. Assign to package `$TMP` (local) or a transportable Z-package
5. Paste the full source code from `src/ZSO_REPORT_ALV.abap`
6. Click **Check** (`Ctrl+F2`) — resolve any syntax errors
7. Click **Activate** (`Ctrl+F3`)

---

## Step 2 — Create Text Elements (SE38)

Text elements are used for the selection screen block titles.

1. In SE38 with `ZSO_REPORT_ALV` open, go to **Goto → Text Elements → Text Symbols**
2. Add the following symbols:

| Symbol | Text |
|--------|------|
| S01 | Order Selection Criteria |
| S02 | Display Options |

3. Save and activate

---

## Step 3 — Create Screen 100 (SE51)

Screen 100 hosts the ALV docking container.

1. Open **Transaction SE51**
2. Enter Program: `ZSO_REPORT_ALV`, Screen Number: `0100`
3. Click **Create** and set:
   - **Short Description:** ALV Dashboard Screen
   - **Screen Type:** Normal
4. Go to the **Layout** tab — the screen can remain blank (no Custom Control needed because the program uses `CL_GUI_DOCKING_CONTAINER`)
5. Go to the **Flow Logic** tab and add:

```abap
PROCESS BEFORE OUTPUT.
  MODULE init_screen_100.

PROCESS AFTER INPUT.
  MODULE process_user_cmd.
```

6. Save and **Activate** the screen

---

## Step 4 — Create GUI Status and Title Bar (SE41)

### GUI Status: ZAM_STATUS

1. Open **Transaction SE41**
2. Enter Program: `ZSO_REPORT_ALV`
3. Under **GUI Status**, type `ZAM_STATUS` and click **Create**
4. Choose type **Normal Screen**
5. In the **Function Keys** section, assign:
   - **F3** → `BACK`
   - **F12** → `CANCEL`
   - **Shift+F3** → `EXIT`
6. In the **Application Toolbar**, add buttons:
   - `ZAM_REFRESH` — label: `Refresh` (use icon `ICON_REFRESH`)
7. Activate the status

### Title Bar: ZAM_TITLE

1. Still in SE41, under **Title**, type `ZAM_TITLE` and click **Create**
2. Enter title text: `Sales Order Dashboard`
3. Activate

---

## Step 5 — Verify Test Data (SE16)

Before running the report, confirm that the VBAK, VBAP, and KNA1 tables have data.

1. Open **Transaction SE16**
2. Enter table `VBAK` and press **F8** — check that Sales Orders exist
3. Repeat for `VBAP` and `KNA1`
4. If no data exists, create test Sales Orders using **Transaction VA01**

---

## Step 6 — Run the Report (SA38)

1. Open **Transaction SA38**
2. Enter `ZSO_REPORT_ALV` and press **F8**
3. Enter selection criteria:
   - Leave all filters blank to fetch all accessible orders
   - Or enter a Sales Organisation, Customer, or Date Range to narrow results
4. Set **Max Rows** (default 5000)
5. Keep **ALV Grid** checkbox ticked for the interactive grid view
6. Click **Execute (F8)**

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `CX_SY_CREATE_OBJECT_ERROR` on container creation | Screen 100 not active or flow logic incorrect | Re-check SE51 Screen 100 flow logic and activation status |
| `Authority check failed` error | User lacks `V_VBAK_VKO` authorisation | Assign the authorisation or comment out the `AUTHORITY-CHECK` block in sandbox |
| ALV grid shows but no data | Selection criteria too restrictive | Widen the date range or clear all filters |
| GUI Status `ZAM_STATUS` not found | Status not created or not activated in SE41 | Create and activate as described in Step 4 |
| Column headers show field names | Text elements or DDIC labels missing | Ensure field catalogue `REF_TABLE` / `REF_FIELD` values are correctly set |
