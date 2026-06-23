# Multidimensional Child Poverty Dashboard — UNICEF Côte d'Ivoire

**An interactive R Shiny dashboard monitoring 20+ social indicators derived from multidimensional child poverty analysis, built during a Social Policy internship at UNICEF.**

🔗 **Live dashboard:** https://kjjesugnon.shinyapps.io/Indicators/

---

## Context

During a Social Policy internship at UNICEF Côte d'Ivoire (2024–2025), I analyzed multidimensional child poverty data covering 5,000+ households and built tools to make the findings accessible to UNICEF teams and government partners.

## What this dashboard does

- Tracks 20+ social indicators related to child deprivation (health, water, sanitation, education, housing)
- Visualizes the geographic distribution of the Multidimensional Poverty Index (MPI) and changes in deprivation across districts
- Designed for non-technical stakeholders (government officials, program teams) to explore the data without needing R or GIS software

## Why no raw data here

The underlying household survey microdata is confidential UNICEF/government data and cannot be made public. This folder contains the dashboard's application code (sanitized of any real household-level data) along with screenshots, so the design and technical approach are visible without exposing protected data.

## Related work from this internship

- **Underlying analysis for Côte d'Ivoire's official N-MODA report (3rd edition).** I conducted the data analysis behind the National Multiple Overlapping Deprivation Analysis (N-MODA) on child poverty, published by the Ministry of Economy, Plan and Development (via the Office National de la Population) in collaboration with UNICEF, validated December 2024. *(Link to official published report: add once available on the ONP/UNICEF Côte d'Ivoire site.)*
- Comprehensive policy brief with 10+ recommendations for government social programs
- MPI distribution mapping across districts
- Survey tool development and testing for poverty data collection

> Note: the N-MODA report itself is a government/UNICEF publication, not republished here — household survey microdata (EDS 2021) underlying it is confidential. This repo links to the official version rather than hosting it.

## Repo contents

```
app/    R Shiny application code (UI + server logic)
```

---
*Author: Jesugnon David Janvier Koumagnon*
