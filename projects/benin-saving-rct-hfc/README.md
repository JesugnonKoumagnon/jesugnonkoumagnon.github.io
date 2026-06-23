# High-Frequency Data Quality Checks — Saving Treatment RCT, Benin (2024)

**Stata scripts for real-time field data quality monitoring during a randomized controlled trial on savings behavior, conducted as part of a Research Assistant role at the African School of Economics.**

---

## Context

As part of an RCT studying savings behavior and financial inclusion in rural Benin (2024), field data was collected via KoboCollect and needed to be checked for quality issues *during* data collection — not after — so enumeration problems could be caught and corrected while teams were still in the field.

## What these scripts do

### `HFC_Saving_Treatment.do` — High Frequency Checks
A comprehensive data quality pipeline run against each new batch of incoming survey data:
- **Duplicate detection** — flags duplicate participant IDs, broken down by enumerator/controller, exported to per-enumerator Excel sheets for follow-up
- **ID integrity** — checks for missing or non-unique participant IDs
- **Skip-pattern / logic validation** — cross-checks dependent questions (e.g., willingness-to-save follow-ups should only be answered if the respondent said "yes" to the initial willingness question) and flags inconsistent responses
- **Range and validity checks** — visit counts, deposit amounts, and other numeric fields checked against expected ranges
- **"Other" response audits** — flags cases where a respondent selected "other" but the open-text follow-up is missing
- Automated export of every flagged issue to a structured Excel workbook (one sheet per check), ready for enumerator follow-up

### `Funnel_Attrition_Analysis.do` — Respondent Funnel Tracking
Tracks the sample through each stage of contact and eligibility:
```
Total sample → reachable → not already connected → not already paying fees → net savers
```
This produces a running count at each stage (e.g., 277 → 254 → 235 → 225) so the research team always knows the effective sample size for analysis as fieldwork progresses.

## Notes on this code

- File paths have been anonymized and one real respondent name appearing in a data-correction line has been redacted before publishing — the underlying survey microdata itself is not included or shared here.
- Written for Stata 16, using `kobo2stata` to merge raw KoboCollect exports with the survey questionnaire/choice labels, and `tabout` for formatted tabulations.

---
*Author: Jesugnon David Janvier Koumagnon — African School of Economics*
