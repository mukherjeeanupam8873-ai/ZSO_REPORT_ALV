# Field Catalogue Reference — ZSO_REPORT_ALV

All 16 output columns defined in `FORM build_field_catalogue`.

| # | Field Name | Header Text | Width | Source Table | Source Field | Hotspot | Justify | Notes |
|---|------------|-------------|-------|--------------|--------------|---------|---------|-------|
| 1 | ORDER_NO | Order No. | 10 | VBAK | VBELN | ✅ Yes | Left | Click to open VA03 |
| 2 | ORDER_DATE | Order Date | 10 | VBAK | AUDAT | No | Centre | Creation date |
| 3 | SALES_ORG | Sales Org | 4 | VBAK | VKORG | No | Centre | Organisation key |
| 4 | CUST_NO | Customer | 10 | VBAK | KUNNR | No | Left | Sold-to number |
| 5 | CUST_NAME | Customer Name | 30 | KNA1 | NAME1 | No | Left | From customer master |
| 6 | CUST_CITY | City | 15 | KNA1 | ORT01 | No | Left | Customer city |
| 7 | CUST_CTRY | Country | 3 | KNA1 | LAND1 | No | Centre | ISO country code |
| 8 | ITEM_NO | Item | 6 | VBAP | POSNR | No | Right | Line item number |
| 9 | MATERIAL | Material | 18 | VBAP | MATNR | No | Left | Material number |
| 10 | ITEM_DESC | Description | 30 | VBAP | ARKTX | No | Left | Item short text |
| 11 | QTY | Quantity | 13 | VBAP | KWMENG | No | Right | Confirmed quantity |
| 12 | UOM | UoM | 3 | VBAP | VRKME | No | Centre | Unit of measure |
| 13 | UNIT_PRICE | Unit Price | 13 | VBAP | NETPR | No | Right | Net price per unit |
| 14 | HDR_VALUE | Order Value | 15 | VBAK | NETWR | No | Right | Total net value |
| 15 | CURRENCY | Currency | 5 | VBAK | WAERK | No | Centre | Document currency |
| 16 | STAT_LBL | Status | 15 | — | — | No | Centre | Computed from GBSTK |

## Hidden Fields (NO_OUT = X)

These fields exist in the internal table but are hidden from the ALV output:

| Field | Purpose |
|-------|---------|
| ROW_CLR | Drives row background colour via `gs_layout-info_fname` |
| PROC_STAT | Raw GBSTK value — replaced by readable STAT_LBL |
| DISTR_CH | Distribution channel — hidden by default, user can unhide |
| DIVISION | Division — hidden by default, user can unhide |
