# Transport Request Notes — ZSO_REPORT_ALV

## Objects to Transport

When moving this program from Development to Quality / Production, the following objects must be included in the transport request:

| Object Type | Object Name | Description |
|-------------|-------------|-------------|
| `PROG` | `ZSO_REPORT_ALV` | Main ABAP program |
| `DYNP` | `ZSO_REPORT_ALV 0100` | Dynpro Screen 100 |
| `CUAD` | `ZSO_REPORT_ALV` | GUI Status `ZAM_STATUS` and Title Bar `ZAM_TITLE` |
| `MESS` | `ZMSG_SALES` | Message class (if created) |

## Steps to Create a Transport Request (SE09 / SE10)

1. Open **Transaction SE09** (Workbench Organiser)
2. Click **Create** to create a new Workbench request
3. Enter a short description: `ZSO_REPORT_ALV - Sales Order Dashboard`
4. Add all objects listed above to the request
5. Release the request tasks first, then release the request itself
6. Import the request into QA/Production using **Transaction STMS**

## Local Development (No Transport)

If developing in a sandbox with no transport system, assign all objects to package `$TMP`.
Objects in `$TMP` are local and cannot be transported — suitable for learning and testing only.
