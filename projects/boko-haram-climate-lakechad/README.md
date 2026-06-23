# Boko Haram Violence and Climate Change in the Lake Chad Region

**A district- and grid-cell-level econometric analysis (2009–2022) of whether climate anomalies predict Boko Haram conflict intensity across Cameroon, Chad, Niger, and Nigeria.**

📄 [Full paper](./paper/Boko_Haram_Climate_Lake_Chad.pdf)

---

## The question

Does climate change — measured through temperature, rainfall, vegetation (NDVI), and drought (SPEI) anomalies — have a causal link to the intensity and incidence of Boko Haram violence in the Lake Chad basin?

## Key finding

**Yes, with a clear directional pattern.** At the district level:
- A one-unit increase in temperature anomaly is associated with a **+1.468** increase in conflict intensity (p<0.01)
- Higher rainfall is associated with **lower** conflict intensity (coefficient -4.229, p<0.1)
- Higher NDVI (greenness) is associated with **more** conflict, not less — counterintuitive, and discussed in the paper (cropland/resource-presence effect)
- The drought index (SPEI) shows a strong negative association (-24.67, p<0.01): drier conditions, more conflict
- Conflict has a strong spatial spillover effect — violence in neighboring districts predicts violence locally (spatial lag coefficient ~1.4, p<0.01)

These results hold at both district level (92 units) and grid-cell level (166–2158 observations), using fixed-effects models to control for time-invariant confounders.

## Method

- **Spatial unit:** 92 second-level administrative districts + 10km×10km grid cells across the Lake Chad basin (Niger, Chad, Nigeria, Cameroon)
- **Conflict data:** ACLED (battles, explosions, violence against civilians, strategic developments), 2009–2022
- **Climate data:** MODIS (NDVI, temperature), CHIRPS (precipitation), aggregated from raster to district/cell level
- **Controls:** population (WorldPop), travel time to nearest city (Malaria Atlas Project), night-time lights, cropland share
- **Model:** Fixed-effects panel regression with climate anomalies (annual z-scores) as predictors, plus a spatially lagged conflict term to capture spillovers

```
Conflict_it = β1·Climate_it + β2·(W × Conflict_it) + ν_it
```

### Identification strategy — addressing key threats
| Threat | Approach |
|---|---|
| Reverse causality | Fixed effects + lagged climate variables for temporal precedence |
| Omitted variable bias | Controls for population density, infrastructure, economic activity (night lights) |
| Selection bias | Sub-national panel across 92 districts, long time coverage (2009–2022) |
| Spatial autocorrelation | Spatial fixed effects + spatially lagged dependent variable |

## Repo contents

```
data/        ACLED conflict data, MODIS/CHIRPS climate rasters (or download scripts), WorldPop, Malaria Atlas Project
scripts/     Data merging (raster-to-district aggregation), panel regression models, spatial lag construction
outputs/     Reproduced tables (conflict summary stats, regression results) and figures (conflict maps, climate anomaly maps)
paper/       Final paper (PDF)
```

## Notes on data sources
All data is from public sources: ACLED (conflict events), MODIS Terra (NDVI/temperature), CHIRPS (precipitation), WorldPop (population), Malaria Atlas Project (travel time).

---
*Author: Jesugnon David Janvier Koumagnon*
