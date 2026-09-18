###############################################################################
# Main Analysis Script: Causal Impact of Training Program
# Author: Jesugnon David Janvier Koumagnon
# Email : dkoumagnon@africanschoolofeconomics.com
# Date: 2025-10-04
#
# Purpose:
#   - Import firm-level datasets
#   - Clean and standardize variables
#   - Merge into a balanced panel (firm x month)
#   - DiD with two-way fixed effects
#   - Event study analysis
#   - Regression discontinuity design
#   - Robustness checks
###############################################################################

# ==========================
# 00. Setup and Packages
# ==========================

rm(list = ls(all = TRUE)); graphics.off()

listofpackages <- c("readxl", "tidyverse", "dplyr", "prettyR",
                    "stargazer", "sandwich", "tinytex",
                    "plm","lmtest", "kableExtra", "ggplot2", 
                    "broom", "tidyr", "fs", "zoo", 
                    "janitor", "rdrobust")

for (j in listofpackages) {  
  if (sum(installed.packages()[, 1] == j) == 0) { 
    install.packages(j) 
  }
  library(j, character.only = TRUE)
}


# Working directory
setwd("C:/Users/Admiral/Desktop/Coding_Task_Jesugnon/Data_Task_2025")

# ==========================
# 00. Create folders
# ==========================
dir.create("Tables", showWarnings = FALSE)
dir.create("Figures", showWarnings = FALSE)
dir.create("Final Datasets", showWarnings = FALSE)

# ==========================
# 1. Import Firm info Data
# ==========================
firm_info <- read_csv("firm_information.csv") %>%
  clean_names() %>%
  distinct(firm_id, .keep_all = TRUE)


# ======================
# 2. Import Sales Data
# ======================
agg_sales <- read_csv("aggregate_firm_sales.csv", show_col_types = FALSE) %>%
  clean_names() %>%
  mutate(
    firm_id = str_trim(firm_id),
    sales_t = as.numeric(sales_t)
    )

# =========================================
# 3. Import Monthly Panel Data (2010–2019)
# =========================================

monthly_files <- dir_ls("monthly_data", glob = "*.csv")

monthly <- map_dfr(monthly_files, ~ {
  read_csv(.x, show_col_types = FALSE) %>%
    clean_names() %>%
    mutate(
      firm_id     = str_to_upper(str_trim(firm_id)),
      employment_t = as.numeric(employment_t),
      wage_bill_t  = as.numeric(wage_bill_t),
      revenue_t    = as.numeric(revenue_t),
      adopt_t      = as.integer(adopt_t)
    )
}, .id = "source") %>%
  select(date, firm_id, employment_t, wage_bill_t, revenue_t, adopt_t)

# =========================================
# 4. Proccessing and cleaning
# =========================================
# We notice that some obs in the aggreagate sales data contain additionnal 
# 0 for the firm ID and also there are some with more digits in the two dataset.

# 4. Standardize Firm IDs (Remove Whitespace and Extra Zeros)
# The action performed is 
clean_firm_id <- function(x) {
  x %>%
    str_trim() %>%                        # remove leading/trailing spaces
    str_replace_all("\\s+", "") %>%       # remove internal spaces
    toupper() %>%                         # ensure uppercase
    str_extract("[A-Z]+-\\d+") %>%        # keep only prefix-number pattern
    { 
      # split into prefix and number
      parts <- str_split_fixed(., "-", 2)
      prefix <- parts[,1]
      num    <- substr(parts[,2], 1, 2)   # keep only first 2 digits
      paste0(prefix, "-", num)
    }
}

# Clean IDs in sales
agg_sales <- agg_sales %>%
  mutate(firm_id = clean_firm_id(firm_id))

# Clean IDs in monthly
monthly <- monthly %>%
  mutate(firm_id = clean_firm_id(firm_id))

# =========================================
# 5. Merging of Sales, firm info and Monthly data
# =========================================
# The action performed is splitting the date column then collect month, 
# day and year make corrections and then display the clean date
fix_date <- function(date_col) {
  parts  <- str_split_fixed(date_col, "[^0-9]", 3)   # split on non-digits
  year   <- as.integer(parts[,1])
  part2  <- as.integer(parts[,2])
  part3  <- as.integer(parts[,3])
  
  # If part2 > 12, then it's actually the day and part3 is the month
  month  <- ifelse(part2 > 12, part3, part2)
  day    <- ifelse(part2 > 12, part2, part3)
  
  # Rebuild a proper Date
  date_clean <- as.Date(paste(year, month, day, sep = "-"))
  
  return(date_clean)
}

monthly <- monthly %>%
  mutate(date_clean = fix_date(date))

agg_sales <- agg_sales %>%
  mutate(date_clean = fix_date(date))

daily_sales <- monthly %>%
  left_join(
    agg_sales %>% select(firm_id, date_clean, sales_t),
    by = c("firm_id", "date_clean")
  ) %>%
  left_join(
    firm_info %>% select(firm_id, firm_name, firm_sector),
    by = "firm_id"
  )


# =========================================
# 6. Aggregating
# =========================================
# Add year and month columns before aggregation
daily_sales <- daily_sales %>%
  mutate(
    year  = as.integer(format(date_clean, "%Y")),
    month = as.integer(format(date_clean, "%m"))
  )

panel_monthly <- daily_sales %>%
  group_by(firm_id, firm_name, firm_sector, year, month) %>%
  summarize(
    employment_t = mean(employment_t, na.rm = TRUE),
    wage_bill_t  = mean(wage_bill_t, na.rm = TRUE),
    revenue_t    = mean(revenue_t, na.rm = TRUE),
    adopt_t      = max(adopt_t, na.rm = TRUE),   # adoption if any in month
    sales_t      = mean(sales_t, na.rm = TRUE),  # from agg_sales
    n_obs        = n(),                          # number of daily obs collapsed
    .groups = "drop"
  )

# Replace the NaN by NA
panel_monthly <- panel_monthly %>%
  mutate(
    employment_t = na_if(employment_t, NaN),
    wage_bill_t  = na_if(wage_bill_t, NaN),
    revenue_t    = na_if(revenue_t, NaN),
    sales_t      = na_if(sales_t, NaN)
  )

# =========================================
# 7. Treatment variables
# =========================================
# Identify firms that ever participated in the program (post-2013)
treated_firms <- panel_monthly %>%
  filter(year >= 2013, adopt_t == 1) %>%
  distinct(firm_id) %>%
  pull(firm_id)

panel_monthly <- panel_monthly %>%
  mutate(
    treated = as.integer(firm_id %in% treated_firms),
    post_treatment = as.integer(year >= 2013),
    months_since_2013 = (year - 2013) * 12 + (month - 1),
    treated_post = treated * post_treatment
  )


# =========================================
# 8. Baseline Variables (Pre-Treatment Period: 2010-2012)
# =========================================
# Use average employment across full pre-treatment period (2010-2012)
baseline_vars <- panel_monthly %>%
  filter(year < 2013) %>%
  group_by(firm_id) %>%
  summarise(
    employment_baseline = mean(employment_t, na.rm = TRUE),
    revenue_baseline = mean(revenue_t, na.rm = TRUE),
    sales_baseline = mean(sales_t, na.rm = TRUE),
    wage_bill_baseline = mean(wage_bill_t, na.rm = TRUE),
    n_baseline_obs = sum(!is.na(employment_t)),
    .groups = "drop"
  )

panel_monthly <- panel_monthly %>%
  left_join(baseline_vars, by = "firm_id") %>%
  mutate(
    eligible = case_when(
      is.na(employment_baseline) ~ NA_integer_,
      employment_baseline <= 100 ~ 1L,
      TRUE ~ 0L
    ),
    distance_from_threshold = employment_baseline - 100,
    above_threshold = as.integer(!is.na(employment_baseline) & employment_baseline > 100)
  )

# =========================================
# 9. Checking (Baseline data, Attrition)
# =========================================
# Checking how many firms have baseline data
panel_monthly %>%
  group_by(firm_id) %>%
  summarise(has_baseline = any(year < 2013)) %>%
  count(has_baseline)

# Attrition Pattern by Year
panel_monthly %>%
  group_by(year) %>%
  summarise(n_firms = n_distinct(firm_id)) %>%
  arrange(year)

# Attrition related to treatment
panel_monthly %>%
  group_by(firm_id, treated) %>%
  summarise(n_months = n(), .groups = "drop") %>%
  group_by(treated) %>%
  summarise(
    n_firms = n(),
    mean_months = mean(n_months),
    median_months = median(n_months),
    min_months = min(n_months),
    max_months = max(n_months)
  )

# =========================================
# 10. Descriptives statistics
# =========================================
# 1. Descriptive Stats by Treatment (Wide)

desc_treatment_wide <- panel_monthly %>%
  filter(year < 2013) %>%
  group_by(treated) %>%
  summarise(
    n_firms = n_distinct(firm_id),
    n_obs = n(),
    mean_employment = mean(employment_t, na.rm=TRUE),
    sd_employment = sd(employment_t, na.rm=TRUE),
    mean_revenue = mean(revenue_t, na.rm=TRUE),
    sd_revenue = sd(revenue_t, na.rm=TRUE),
    mean_sales = mean(sales_t, na.rm=TRUE),
    sd_sales = sd(sales_t, na.rm=TRUE),
    mean_wage_bill = mean(wage_bill_t, na.rm=TRUE),
    sd_wage_bill = sd(wage_bill_t, na.rm=TRUE),
    .groups="drop"
  ) %>%
  mutate(Group = if_else(treated==1, "Treated", "Control")) %>%
  select(-treated) %>%
  pivot_longer(-Group, names_to="Variable", values_to="Value") %>%
  pivot_wider(names_from=Group, values_from=Value) %>%
  mutate(across(where(is.numeric), ~round(.x,3)))

# Export LaTeX
kable(desc_treatment_wide, format="latex", booktabs=TRUE,
      caption="Descriptive Statistics by Treatment Status (2010-2012)") %>%
  kable_styling(latex_options=c("hold_position")) %>%
  writeLines("Tables/descriptive_treatment_wide.tex")


# 2. Descriptive Stats by Eligibility (Wide)
desc_eligible_wide <- panel_monthly %>%
  filter(year < 2013, !is.na(eligible)) %>%
  group_by(eligible) %>%
  summarise(
    n_firms = n_distinct(firm_id),
    n_obs = n(),
    mean_employment = mean(employment_t, na.rm=TRUE),
    sd_employment = sd(employment_t, na.rm=TRUE),
    mean_revenue = mean(revenue_t, na.rm=TRUE),
    sd_revenue = sd(revenue_t, na.rm=TRUE),
    mean_sales = mean(sales_t, na.rm=TRUE),
    sd_sales = sd(sales_t, na.rm=TRUE),
    mean_wage_bill = mean(wage_bill_t, na.rm=TRUE),
    sd_wage_bill = sd(wage_bill_t, na.rm=TRUE),
    .groups="drop"
  ) %>%
  mutate(Group = if_else(eligible==1, "Eligible (≤100)", "Ineligible (>100)")) %>%
  select(-eligible) %>%
  pivot_longer(-Group, names_to="Variable", values_to="Value") %>%
  pivot_wider(names_from=Group, values_from=Value) %>%
  mutate(across(where(is.numeric), ~round(.x,3)))

# Export LaTeX
kable(desc_eligible_wide, format="latex", booktabs=TRUE,
      caption="Descriptive Statistics by Eligibility Status (2010-2012)") %>%
  kable_styling(latex_options=c("hold_position")) %>%
  writeLines("Tables/descriptive_eligibility_wide.tex")


# 4. T-Tests Treated vs Control

baseline_wide <- panel_monthly %>%
  filter(year < 2013) %>%
  select(firm_id, treated, employment_t, revenue_t, sales_t, wage_bill_t)

t_emp <- t.test(employment_t ~ treated, data=baseline_wide)
t_rev <- t.test(revenue_t ~ treated, data=baseline_wide)
t_sales <- t.test(sales_t ~ treated, data=baseline_wide)
t_wage <- t.test(wage_bill_t ~ treated, data=baseline_wide)

t_tests_summary <- tibble(
  Variable = c("Employment","Revenue","Sales","Wage Bill"),
  t_stat = round(c(t_emp$statistic, t_rev$statistic, t_sales$statistic, t_wage$statistic),3),
  p_value = round(c(t_emp$p.value, t_rev$p.value, t_sales$p.value, t_wage$p.value),3)
)

# T-test table
kable(t_tests_summary, format="latex", booktabs=TRUE,
      caption="T-Tests Comparing Treated vs Control Firms (2010-2012)",
      col.names=c("Variable","t-statistic","p-value")) %>%
  kable_styling(latex_options=c("hold_position")) %>%
  writeLines("Tables/t_tests_baseline.tex")


# =========================================
# 11. DIFFERENCE-IN-DIFFERENCES
# =========================================
# Create log transformations
panel_monthly <- panel_monthly %>%
  mutate(
    log_employment = log(employment_t + 1),
    log_revenue = log(revenue_t + 1),
    log_sales = log(sales_t + 1),
    log_wage_bill = log(wage_bill_t + 1),
    revenue_per_worker = revenue_t / employment_t,
    log_productivity = log(revenue_per_worker + 1)
  )

# Create panel data structure
panel_data <- pdata.frame(
  panel_monthly %>% filter(!is.na(employment_baseline)),
  index = c("firm_id", "year", "month"),
  drop.index = FALSE
)

# Main DiD specifications with two-way fixed effects
did_employment <- plm(log_employment ~ treated_post,
                      data = panel_data,
                      effect = "twoways",
                      model = "within")

did_revenue <- plm(log_revenue ~ treated_post,
                   data = panel_data,
                   effect = "twoways",
                   model = "within")

did_sales <- plm(log_sales ~ treated_post,
                 data = panel_data,
                 effect = "twoways",
                 model = "within")

did_productivity <- plm(log_productivity ~ treated_post,
                        data = panel_data,
                        effect = "twoways",
                        model = "within")

# Get clustered standard errors
se_employment <- sqrt(diag(vcovHC(did_employment, cluster = "group")))
se_revenue <- sqrt(diag(vcovHC(did_revenue, cluster = "group")))
se_sales <- sqrt(diag(vcovHC(did_sales, cluster = "group")))
se_productivity <- sqrt(diag(vcovHC(did_productivity, cluster = "group")))

# View results with robust SEs
coeftest(did_employment, vcov = vcovHC(did_employment, cluster = "group"))
coeftest(did_revenue, vcov = vcovHC(did_revenue, cluster = "group"))

# Export results table
stargazer(did_employment, did_revenue, did_sales, did_productivity,
          type = "latex",
          out = "Tables/main_did_results.tex",
          title = "Difference-in-Differences Results: Training Program Effects",
          column.labels = c("Log Employment", "Log Revenue", "Log Sales", "Log Productivity"),
          dep.var.labels.include = FALSE,
          se = list(se_employment, se_revenue, se_sales, se_productivity),
          covariate.labels = "Treated × Post",
          add.lines = list(c("Firm FE", "Yes", "Yes", "Yes", "Yes"),
                           c("Time FE", "Yes", "Yes", "Yes", "Yes")),
          notes = "Robust standard errors clustered at firm level in parentheses.")


# =========================================
# 13. EVENT STUDY (Test Parallel Trends)
# =========================================

# Create relative time dummies
panel_data <- panel_data %>%
  mutate(
    rel_time = case_when(
      months_since_2013 < -18 ~ -6,
      dplyr::between(months_since_2013, -18, -15) ~ -5,
      dplyr::between(months_since_2013, -15, -12) ~ -4,
      dplyr::between(months_since_2013, -12, -9) ~ -3,
      dplyr::between(months_since_2013, -9, -6) ~ -2,
      dplyr::between(months_since_2013, -6, -3) ~ -1,  # reference
      dplyr::between(months_since_2013, 0, 2) ~ 0,
      dplyr::between(months_since_2013, 3, 5) ~ 1,
      dplyr::between(months_since_2013, 6, 8) ~ 2,
      dplyr::between(months_since_2013, 9, 11) ~ 3,
      dplyr::between(months_since_2013, 12, 14) ~ 4,
      months_since_2013 >= 15 ~ 5
    ),
    treated_m6 = (rel_time == -6) * treated,
    treated_m5 = (rel_time == -5) * treated,
    treated_m4 = (rel_time == -4) * treated,
    treated_m3 = (rel_time == -3) * treated,
    treated_m2 = (rel_time == -2) * treated,
    treated_0 = (rel_time == 0) * treated,
    treated_1 = (rel_time == 1) * treated,
    treated_2 = (rel_time == 2) * treated,
    treated_3 = (rel_time == 3) * treated,
    treated_4 = (rel_time == 4) * treated,
    treated_5 = (rel_time == 5) * treated
  )

# Create log variables safely
panel_data <- panel_data %>%
  mutate(
    log_revenue = log1p(revenue_t),
    log_employment = log1p(employment_t)
  )

# Helper function for Event Study regression and plotting
event_study_fun <- function(dep_var, y_label, title_text, file_prefix) {
  
  # Estimate TWFE event study
  form <- as.formula(paste0(
    dep_var, " ~ treated_m6 + treated_m5 + treated_m4 + treated_m3 + treated_m2 + ",
    "treated_0 + treated_1 + treated_2 + treated_3 + treated_4 + treated_5"
  ))
  
  model <- plm(
    form,
    data = panel_data,
    effect = "twoways",
    model = "within",
    index = c("firm_id", "year", "month")
  )
  
  # Robust clustered SE
  coef_mat <- coeftest(model, vcov = vcovHC(model, cluster = "group"))
  
  # Build results tibble
  es_results <- tibble(
    period = c(-6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5),
    estimate = c(coef_mat[1:6, 1], 0, coef_mat[7:11, 1]),
    se = c(coef_mat[1:6, 2], 0, coef_mat[7:11, 2])
  ) %>%
    mutate(
      ci_lower = estimate - 1.96 * se,
      ci_upper = estimate + 1.96 * se
    )
  
  # Save table
  write_csv(es_results, paste0("Tables/", file_prefix, "_event_study_results.csv"))
  
  # Plot
  p <- ggplot(es_results, aes(x = period, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
    geom_point(size = 2, color = "#2C3E50") +
    geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                  width = 0.2, color = "#2C3E50") +
    scale_x_continuous(
      breaks = seq(-6, 5, 1),
      labels = c("≤-18m", "-15m", "-12m", "-9m", "-6m",
                 "Ref", "0–2m", "3–5m", "6–8m", "9–11m", "12–14m", "≥15m")
    ) +
    labs(
      x = "Months relative to program start",
      y = y_label,
      title = title_text,
      subtitle = "Reference period = -6 to -3 months before 2013"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.minor = element_blank(),
      axis.line = element_line(color = "black"),
      plot.title = element_text(face = "bold")
    )
  
  # Save figure
  ggsave(
    paste0("Figures/", file_prefix, "_event_study_plot.png"),
    p, width = 7, height = 5, dpi = 300
  )
  
  return(p)
}

# 3. Run for each dependent variable
plot_revenue <- event_study_fun(
  dep_var = "log_revenue",
  y_label = "Effect on Log(Revenue)",
  title_text = "Event Study: Program Impact on Firm Revenue",
  file_prefix = "revenue"
)

plot_sales <- event_study_fun(
  dep_var = "log_sales",
  y_label = "Effect on Log(Sales)",
  title_text = "Event Study: Program Impact on Sales",
  file_prefix = "sales"
)

plot_employment <- event_study_fun(
  dep_var = "log_employment",
  y_label = "Effect on Log(Employment)",
  title_text = "Event Study: Program Impact on Employment",
  file_prefix = "employment"
)

# Show plots
plot_revenue
plot_sales
plot_employment


# =========================================
# 14. ROBUSTNESS CHECKS with Placebo
# =========================================
# Placebo test (fake treatment in 2011)
# Aggregate at firm–month level to avoid duplicates

# Create a single monthly period variable
panel_monthly <- panel_monthly %>%
  mutate(period = as.Date(paste(year, month, "01", sep = "-")))

# Placebo test (fake treatment in 2011)
panel_placebo <- pdata.frame(
  panel_monthly %>% 
    filter(year <= 2012, !is.na(employment_baseline)) %>%
    mutate(fake_treated_post = treated * as.integer(year >= 2011)),
  index = c("firm_id", "period")
)

placebo_test <- plm(log_revenue ~ fake_treated_post,
                    data = panel_placebo,
                    effect = "twoways",
                    model = "within")

# Balanced panel
balanced_firms <- panel_monthly %>%
  group_by(firm_id) %>%
  filter(n() == 120) %>%   # 10 years × 12 months
  pull(firm_id) %>%
  unique()

panel_balanced <- pdata.frame(
  panel_monthly %>% filter(firm_id %in% balanced_firms),
  index = c("firm_id", "period")
)
did_balanced <- plm(log_revenue ~ treated_post,
                    data = panel_balanced,
                    effect = "twoways",
                    model = "within")



# Export robustness table
stargazer(did_revenue, did_balanced, placebo_test,
          type = "latex",
          out = "Tables/robustness_checks.tex",
          title = "Robustness Checks",
          column.labels = c("Main", "Balanced Panel", "Placebo (2011)"),
          se = list(se_revenue, 
                    sqrt(diag(vcovHC(did_balanced, cluster = "group"))),
                    sqrt(diag(vcovHC(placebo_test, cluster = "group")))))

# =========================================
# 14. Regression discontinuity
# =========================================
panel_rdd <- panel_monthly %>%
  filter(year >= 2013, !is.na(distance_from_threshold),
         abs(distance_from_threshold) <= 50)

rdd_revenue <- rdrobust(
  y = panel_rdd$log_revenue,
  x = panel_rdd$distance_from_threshold,
  c = 0,
  cluster = panel_rdd$firm_id,
  masspoints = "adjust"
)

# Extract key results
rdd_table <- data.frame(
  Estimate = round(rdd_revenue$coef[1], 3),
  StdError = round(rdd_revenue$se[1], 3),
  z_value  = round(rdd_revenue$z[1], 3),
  p_value  = round(rdd_revenue$p[1], 3),
  N        = rdd_revenue$N_h[1] + rdd_revenue$N_h[2],   # total obs used
  Bandwidth = round(rdd_revenue$bws[1], 3)              # main bandwidth
)

# Export LaTeX table
latex_code <- kable(
  rdd_table,
  format = "latex",
  booktabs = TRUE,
  caption = "RDD Estimate for Revenue"
) %>%
  kable_styling(latex_options = "hold_position")

writeLines(latex_code, "Tables/rdd_revenue.tex")

png("Figures/rdd_revenue.png", width = 800, height = 600)
rdplot(
  y = panel_rdd$log_revenue,
  x = panel_rdd$distance_from_threshold,
  c = 0,
  binselect = "esmv",
  title = "RDD: Log Revenue around Threshold",
  x.label = "Distance from Threshold",
  y.label = "Log Revenue"
)
dev.off()

# Save all the datasets generated
# List all objects in the environment
all_objs <- ls()

# Loop through them and export only data frames / tibbles
for(obj in all_objs){
  x <- get(obj)
  if(is.data.frame(x)){
    write.csv(x,
              file = file.path("Final Datasets", paste0(obj, ".csv")),
              row.names = FALSE)
  }
}
