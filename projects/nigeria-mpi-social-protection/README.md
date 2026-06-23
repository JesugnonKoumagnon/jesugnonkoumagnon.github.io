# Multidimensional Poverty and Social Protection Assistance in Nigeria

**A policy brief examining the gap between poverty incidence and social protection coverage across Nigeria's 37 states.**

📄 [Full report](./report/Nigeria_MPI_Social_Protection_Report.pdf) · Data: NBS (2022) Nigeria Multidimensional Poverty Index

---

## The question

Nigeria runs three major social assistance programs — P-CGS, VGF, and CCT — intended to reach its poorest households. Does program coverage actually align with where poverty is highest?

## Key finding

**No — and the mismatch is severe.** States with MPI above 80% (Sokoto, Bayelsa, Gombe, Jigawa, Plateau) consistently receive the *lowest* social protection coverage, while some moderate-poverty states show National Social Register (NSR) enrolment exceeding 100% of their poor population — a sign of probable misclassification or data error.

- **62.9%** of Nigeria's population is multidimensionally poor (4+ deprivations)
- **47.4%** of the poor are not registered in the National Social Register
- P-CGS — the largest cash transfer — reaches only **0.48%** of poor Nigerians nationally
- Regional split: North West/North East carry the highest poverty (MPI > 77%) but the weakest program penetration; Southern states have lower poverty but comparatively better coverage

## Method

1. Merged NBS state-level MPI estimates with National Social Register and program beneficiary data (P-CGS, VGF, CCT)
2. Built a choropleth map of poverty incidence by state (shapefile via Kaggle)
3. Computed coverage gaps (poor population vs. NSR-registered population) by state and region
4. Cross-tabulated program reach against poverty severity to identify targeting mismatches
5. Aggregated to 6 geopolitical zones for regional comparison

## Repo contents

```
data/        NBS MPI data, state shapefile reference, program beneficiary figures
scripts/     R scripts for cleaning, merging, and map/chart generation
outputs/     Generated maps and charts (choropleth, coverage gap charts, regional comparisons)
report/      Final policy brief (PDF)
```

## Policy takeaways (full detail in report)

1. Close the NSR registration gap — mobile registration in high-poverty LGAs, link enrolment to program eligibility
2. Scale up P-CGS/VGF allocations in extreme-poverty states
3. Address regional disparities with zone-specific strategies (food security in the North, job creation in the South)
4. Improve targeting accuracy — household-level scorecards, annual cross-matching against poverty maps

---
*Author: Jesugnon David Janvier Koumagnon*
