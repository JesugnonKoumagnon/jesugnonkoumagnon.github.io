# Jesugnon David Janvier Koumagnon
# Analyzing the Impact of Muslim Representation in Uttar Pradesh Elections
#dkoumagnon@africanschoolofeconomics.com

# Loading packages and installation
rm(list = ls(all = TRUE)); graphics.off()
set.seed(88)
listofpackages <- c("stargazer","kableExtra","ggplot2","dplyr",
                    "tidyverse", "sf", "survey", "rdrobust"
                    ,"haven", "srvyr","ggthemes", "survey", 
                    "broom", "jtools", "rdrobust", "knitr") 

for (j in listofpackages){
  if(sum(installed.packages()[, 1] == j) == 0) { install.packages(j) }
  library(j, character.only = T)
    }

# setting the working directory
setwd("C:/Users/Admiral/Files_Code")

#Loading the electoral database
election_data <- read_csv("electoral/up.csv")
str(election_data)

# Filter the data
filtered_data <- election_data %>%
  filter(Year %in% c(2012, 2017, 2022),
         Poll_No == 0,
         Party != "IND",
         Constituency_Type == "GEN")

#### Task 1 :   ####
# Calculate the percentage of Muslim candidates fielded by each party in each year

party_muslim_percentage <- filtered_data %>%
  group_by(Party, Year) %>%
  summarise(Muslim_Candidates = sum(Muslim1, na.rm = TRUE),
            Total_Candidates = n(),
            Percentage = (Muslim_Candidates / Total_Candidates) * 100) %>%
  ungroup()
party_muslim_percentage$Percentage <- round(party_muslim_percentage$Percentage,2)
winning_parties <- filtered_data %>%
  filter(Position == 1) %>%
  pull(Party) %>%
  unique()

party_muslim_percentage <- party_muslim_percentage %>%
  filter(Party %in% winning_parties)

# Sort the data frame by Year in descending order
party_muslim_percentage <- party_muslim_percentage %>%
  arrange(Year)
latex_table <- kable(party_muslim_percentage, format = "latex", booktabs = TRUE)
writeLines(latex_table)

#### Task 2 ####:
# share of Muslim candidates in each constituency for the three elections. 

# Load the shapefile
up_shapefile <- st_read("electoral/nz252rq2252.shp")

# Filter and summarize the election data
filtered_data <- election_data %>%
  filter(Year %in% c(2012, 2017, 2022), Poll_No == 0) %>% # Focus on 2012, 2017, and 2022 and exclude by-elections
  group_by(Constituency_No, Year) %>%
  summarise(
    Constituency_Type = first(Constituency_Type),
    total_candidates = n(),
    muslim_candidates = sum(Muslim1, na.rm = TRUE),
    share_muslim_candidates = (muslim_candidates / total_candidates) * 100
  ) %>%
  ungroup()

# Merge with shapefile data
map_data <- up_shapefile %>%
  left_join(filtered_data, by = c("ac_no" = "Constituency_No"))

# Convert to sf object if necessary
map_data <- st_as_sf(map_data)

# Plot the map
ggplot(map_data) +
  geom_sf(aes(fill = share_muslim_candidates, geometry = geometry), color = NA) +
  facet_wrap(~Year) +
  scale_fill_viridis_c(
    option = "plasma",
    na.value = "grey50",
    name = "Share of\nMuslim\nCandidates (%)"
  ) +
  geom_sf(data = map_data %>% filter(Constituency_Type %in% c("SC", "ST")), 
          aes(geometry = geometry), fill = "grey80", color = NA) +
  labs(
    title = "Share of Muslim Candidates in Uttar Pradesh Constituencies",
    subtitle = "Faceted by Election Year",
    fill = "Share of Muslim Candidates (%)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 8)
  ) +
  guides(fill = guide_colorbar(
    barwidth = 10, barheight = 0.5,
    title.position = "top"
  ))


#### Task3 ####
#Determine the share of winners that are Muslim, the share of party-nominated 
#candidates that are Muslim, and the share independent candidates that are Muslim
#(denoted by Party being “IND”) Create a line plot that shows how the shares 
#change over the three elections for each set. 

# Filter the data
filtered_data <- election_data %>%
  filter(Year %in% c(2012, 2017, 2022), # Focus on 2012, 2017, and 2022
         Poll_No == 0, # Exclude by-elections
         Constituency_Type == "GEN") # Only general constituencies

# Calculate the share of winners, party-nominated candidates, and independent candidates that are Muslim
muslim_share <- filtered_data %>%
  group_by(Year) %>%
  summarise(Winners = sum(Muslim1[Position == 1], na.rm = TRUE) / sum(Position == 1, na.rm = TRUE),
            Party_Nominated = sum(Muslim1[Party != "IND"], na.rm = TRUE) / sum(Party != "IND", na.rm = TRUE),
            Independent = sum(Muslim1[Party == "IND"], na.rm = TRUE) / sum(Party == "IND", na.rm = TRUE)) %>%
  ungroup() %>%
  gather(key = "Category", value = "Muslim_Share", -Year)

# Plot of the line graph
ggplot(muslim_share, aes(x = Year, y = Muslim_Share, color = Category)) +
  geom_line() +
  theme_minimal() +
  labs(title = "Share of Muslim Winners, Party-Nominated Candidates, and Independent Candidates in Uttar Pradesh General Constituencies ",
       x = "Year",
       y = "Muslim Share",
       color = "Category")

                                    ####Cleaning and Descriptives ####

#### Task 4 ####:
# Perceptions of discrimination through barplot with standard deviation error bar 
pew_data <- read_sav("pew/pew.sav")
head(pew_data)

data_4 <- pew_data
data_4 <- data_4 %>%
  mutate(across(everything(), ~replace(., . %in% c(96, 97, 98, 99), NA))) %>%
  drop_na(Q11ya, Q11yb, Q11yc, Q11yd, Q11ye, Q11yf, Q11yg, Q11yh, Q11yi, QRELSING, QCASTE, weight)

# Filter for Muslims and Hindus
data_4 <- data_4 %>%
  filter(QRELSING %in% c(1, 2))  # 1 for Hindu, 2 for Muslim

# Create a new variable combining religion and caste
data_4 <- data_4 %>%
  mutate(religion_caste = case_when(
    QRELSING == 1 & QCASTE == 1 ~ "Hindu General",
    QRELSING == 1 & QCASTE %in% c(2, 3) ~ "Hindu SC/ST",
    QRELSING == 1 & QCASTE %in% c(4,5) ~ "Hindu OBC/MBC",
    QRELSING == 2 & QCASTE == 1 ~ "Muslim General",
    QRELSING == 2 & QCASTE %in% c(2, 3) ~ "Muslim SC/ST",
    QRELSING == 2 & QCASTE %in% c(4,5) ~ "Muslim OBC/MBC"
  )) %>%
  filter(!is.na(religion_caste))  # Remove any NA values from the new variable

# Convert to survey design object for weighted analysis
survey_data <- data_4 %>%
  as_survey_design(weights = weight)

# Function to calculate weighted percentages with confidence intervals
calc_weighted_perc <- function(data, var) {
  data %>%
    group_by(religion_caste) %>%
    summarize(
      percent = survey_mean(get(var) == 1, vartype = "ci") * 100,
      .groups = 'drop'
    ) %>%
    mutate(discrimination_type = var)
}

# List of discrimination variables
discrimination_vars <- c("Q11ya", "Q11yb", "Q11yc", "Q11yd", "Q11ye", "Q11yf", "Q11yg", "Q11yh", "Q11yi")

# Calculate weighted percentages for all discrimination variables
results <- bind_rows(lapply(discrimination_vars, function(var) calc_weighted_perc(survey_data, var)))

# Plotting
ggplot(results, aes(x = religion_caste, y = percent, fill = religion_caste)) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_errorbar(aes(ymin = percent_low, ymax = percent_upp), width = 0.2, position = position_dodge(width = 0.9)) +
  facet_wrap(~ discrimination_type, scales = "free_y", ncol = 3) +
  labs(title = "Perceived Discrimination by Religion-Caste Combinations",
       y = "Percent of Respondents (%)",
       x = "Religion-Caste Combination") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_brewer(palette = "Set3")


#### Task5 ####:
#  Trends in the Percentage of Muslim CandidatesFielded by Political 
# Parties in Uttar Pradesh Elections (2012, 2017, 2022)

# Load the dataset
pew_data <- read_csv("pew/pew.csv")

# Create a survey design object
pew_survey <- svydesign(id = ~1, weights = ~weight, data = pew_data)

# Calculate the weighted share of individuals who did not know their sect or had no sect in particular
calculate_share <- function(data, religion, sect_var, region_var) {
  data %>%
    filter(QRELSING == religion) %>%
    mutate(Sect_Status = ifelse(.data[[sect_var]] %in% c("Don’t know", "No sect in particular"), 1, 0)) %>%
    group_by(.data[[region_var]]) %>%
    summarize(Share = survey::svymean(~Sect_Status, design = survey::svydesign(id = ~1, weights = ~weight, data = cur_data()), na.rm = TRUE)[1] * 100) %>%
    mutate(Religion = religion)
}

# Calculate shares for Hindus and Muslims
hindu_share <- calculate_share(pew_data, "Hindu", "QHINDU", "REGION")
muslim_share <- calculate_share(pew_data, "Muslim", "QSECTrec", "REGION")

# Combine the results
shares <- bind_rows(hindu_share, muslim_share) %>%
  select(REGION, Religion, Share)

# Plot the results
ggplot(shares, aes(x = REGION, y = Share, fill = Religion)) +
  geom_bar(stat = "identity", position = position_dodge()) +
  theme_minimal() +
  labs(
    title = "Share of Individuals Who Did Not Know Their Sect or Had No Sect in Particular",
    x = "Region",
    y = "Share (%)",
    fill = "Religion"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

#### Task 6####:
# Geographical Distribution of Muslim Candidates in Uttar Pradesh 
# Constituencies Across 2012, 2017,and 2022 Election

# data
pew_data <- read_sav("pew/pew.sav")
# Data Cleaning
# Recode "Refuse to answer", "Don't know", and specific NA values (998, 999, 97)
data_6 <- pew_data
data_6 <- data_6 %>%
  mutate(across(everything(), ~replace(., . %in% c(97, 98, 99, 998, 999), NA)))

# Drop rows with NA values in relevant columns
data_6 <- data_6 %>%
  filter(!is.na(Q10), !is.na(QRELSING), !is.na(QCASTE), !is.na(QAGErec), !is.na(REGION), !is.na(QGEN), !is.na(Urban), !is.na(ISCED))

# Set base categories and recode variables
data_6 <- data_6 %>%
  mutate(
    QRELSING = factor(QRELSING, levels = c(1, 2, 3, 4, 5, 6, 7, 8), labels = c("Hindu", "Muslim", "Christian", "Sikh", "Buddhist", "Jain", "Other", "Unaffiliated")),
    QCASTE = factor(QCASTE, levels = c(1, 2, 3, 4, 5), labels = c("General", "Scheduled Caste", "Scheduled Tribe", "Other Backward Class", "Other")),
    QAGErec = factor(QAGErec, levels = c(1, 2, 3, 4, 5), labels = c("18-25", "26-34", "35-44", "45-59", "60+")),
    REGION = factor(REGION, levels = c(1, 2, 3, 4, 5, 6), labels = c("Northeast", "North", "Central", "East", "West", "South")),
    QGEN = factor(QGEN, levels = c(1, 2), labels = c("Male", "Female")),
    Urban = factor(Urban, levels = c(1, 2), labels = c("Urban", "Rural")),
    ISCED = factor(ISCED, levels = c(0, 1, 2, 3, 4, 5), labels = c("Early Childhood", "Primary", "Lower Secondary", "Upper Secondary", "Post-secondary", "Tertiary"))
  )

# Set base levels for the factors
data_6 <- data_6 %>%
  mutate(
    QRELSING = relevel(QRELSING, ref = "Hindu"),
    QCASTE = relevel(QCASTE, ref = "General"),
    QAGErec = relevel(QAGErec, ref = "18-25"),
    REGION = relevel(REGION, ref = "North"),
    QGEN = relevel(QGEN, ref = "Male"),
    Urban = relevel(Urban, ref = "Urban"),
    ISCED = relevel(ISCED, ref = "Early Childhood")
  )

# Run OLS model
model <- lm(I(Q10 == 2) ~ QRELSING + QCASTE + QAGErec + REGION + QGEN + Urban + ISCED, data = data_6)

# Create coefficient plot
tidy_model <- tidy(model, conf.int = TRUE)

# Plotting
coef_plot <- tidy_model %>%
  filter(term != "(Intercept)") %>%
  ggplot(aes(x = reorder(term, estimate), y = estimate)) +
  geom_point() +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2) +
  coord_flip() +
  labs(title = "Coefficient Plot with Confidence Intervals",
       x = "Demographic Variables",
       y = "Estimate")

# Print plot
print(coef_plot)


#### Task 7 ####:
# Regression Discontinuity Design (RDD) analysis

# data
up_data <- election_data

# Filter relevant data: General constituencies and exclude by-elections
filtered_data <- up_data %>%
  filter(Year %in% c(2012, 2017, 2022), Constituency_Type == "GEN")

# Arrange data to identify close elections between Muslims and Hindus
filtered_data <- filtered_data %>%
  arrange(Constituency_No, Year, Position)

# Calculate margin of victory and identify close elections
filtered_data <- filtered_data %>%
  group_by(Year, Constituency_No) %>%
  mutate(margin = Vote_Share_Percentage - lead(Vote_Share_Percentage)) %>%
  ungroup() %>%
  filter(!is.na(margin))

# Filter to include only close elections where margin is within a threshold (e.g., 5%)
close_elections <- filtered_data %>%
  filter(abs(margin) <= 5 & ((Muslim1 == 1 & lead(Muslim1) == 0) | (Muslim1 == 0 & lead(Muslim1) == 1))) %>%
  mutate(is_muslim_winner = ifelse(Muslim1 == 1 & Position == 1, 1, 0)) %>%
  select(Constituency_No, Year, margin, is_muslim_winner)

# Prepare next election data
next_election_data <- filtered_data %>%
  mutate(next_year = Year + 5) %>%
  filter(Year %in% c(2017, 2022)) %>%
  group_by(Constituency_No, next_year) %>%
  summarise(muslim_share_next = mean(Muslim1, na.rm = TRUE)) %>%
  ungroup()

# Merge the datasets
rd_data <- close_elections %>%
  left_join(next_election_data, by = c("Constituency_No", "Year" = "next_year")) %>%
  filter(!is.na(muslim_share_next))

# Ensure rd_data has no NA values
rd_data <- rd_data %>%
  filter(!is.na(margin) & !is.na(is_muslim_winner) & !is.na(muslim_share_next))

# Check the range of the margin
summary(rd_data$margin)

# Run rdrobust with different polynomial orders
rd_results <- list()
for (poly_order in 1:3) {
  rd_results[[poly_order]] <- rdrobust(y = rd_data$muslim_share_next,
                                       x = rd_data$margin,
                                       c = 3,  # Ensure cut-off is set within the range of x
                                       p = poly_order)
}

# Extract results and create a table
rd_summary <- map_df(rd_results, function(res) {
  tibble(Estimate = res$coef[1],
         Std_Error = res$se[1],
         P_Value = res$pval[1],
         Order = res$p[1])
})

# Convert to LaTeX table
latex_table <- rd_summary %>%
  kable(format = "latex", caption = "RD Analysis Results with Different Polynomial Orders")

# Print the LaTeX table to the console
print(latex_table)

# Create RD plot
rdplot(y = rd_data$muslim_share_next, 
       x = rd_data$margin, 
       c = 3, 
       title = "RD Plot: Effect of Muslim Winning on Muslim Candidates Share",
       x.label = "Margin of Victory",
       y.label = "Share of Muslim Candidates in Next Election",
       col.dots = "blue",
       col.lines = "red",
       binselect = "esmv")
