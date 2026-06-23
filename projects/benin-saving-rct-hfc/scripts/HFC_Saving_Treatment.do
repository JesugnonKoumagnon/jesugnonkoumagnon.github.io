/*------------------------------------------------------------------------------

High Frequency Checks for the Saving Treatment Survey, Benin, 2024
--------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
								Data Quality Check Do-File
-------------------------------------------------------------------------------*/


/*------------------------------------------------------------------------------
Set Stata work environment
-------------------------------------------------------------------------------*/
clear all
version 16
set more off

* Set working directory (adjust as needed)
cd "<path-to-project-folder>/HFC"

* Load the data and combine it with the modalities
kobo2stata using "data_06.07.24.11.50.xlsx", xlsform("questionnaire_06.07.24.11.50.xlsx") surveylabel("label::French") choiceslabel("label::French") dropnotes usenotsave
br
*List 
list participant_id name if village == "Adjogansa"

* Correct some imperfections
replace participant_id = "ME0923" if village == "Adjogansa" & participant_id == "ME0927"
replace name = "[REDACTED - respondent name]" if village == "Adjogansa" & participant_id == "ME0923" // PII redacted for public repo
* Save the data
save "saving1.dta", replace

putexcel set "HFC_Saving_Treatment_Results.xlsx", sheet("Results") modify

* Download the package tabout
*ssc install tabout

* 1. Check for duplicates based on unique identifiers (participant ID)
duplicates report participant_id
duplicates tag participant_id, generate(dup_tag)

* Create separate sheets for each controller with duplicates in the Excel file
levelsof controlor if dup_tag > 0, local(controllers)
foreach controller in `controllers' {
    preserve
    keep if controlor == "`controller'" & dup_tag > 0

    * Export to specific sheet in Excel
    export excel using "HFC_Saving_Treatment_Results.xlsx", sheet("`controller'_duplicates") firstrow(variables) replace
    restore
}

* 2. participant_id
cap isid participant_id // Check if participant_id is unique
count if missing(participant_id)

/* 4. Number of visits */
levelsof controlor if number_of_visit < 1 | number_of_visit > 2, local(controllerss)
foreach controller in `controllerss' {
    preserve
    keep if controlor == "`controllers'" & number_of_visit < 1 | number_of_visit > 2

    * Export to specific sheet in Excel
    export excel using "HFC_Saving_Treatment_Results.xlsx", sheet("`controller'_visit", replace) firstrow(variables)
    restore
}


* Respondent available
list participant_id if respondent_available == 3 | respondent_available==-888
count if respondent_available == 3 | respondent_available==-888
if r(N) > 0 {
	export excel  if respondent_available == 3 | respondent_available==-888 using "HFC_Saving_Treatment_Results.xlsx", sheet("Respondent Not Availability", replace) firstrow(variables)
}


* 7. Next availability other (-555 = autre)
list next_availability_other if respondent_available==2 & next_availability == -555 & missing(next_availability_other)
count if respondent_available==2 & next_availability == -555 & missing(next_availability_other)
if r(N) > 0 {
	preserve
	keep if next_availability == -555 & missing(next_availability_other)
	export excel participant_id next_availability next_availability_other using "HFC_Saving_Treatment_Results.xlsx", sheet("Missing_Other_Availability", replace) firstrow(variables)
	restore
}

* 9. other_phone_number2
count if other_phone_number1 == 1 & missing(other_phone_number2)

* 10. Connection_status
tab connection_status
count if connection_status == 3
if r(N) > 0 {
    export excel  if connection_status == 3 using "HFC_Saving_Treatment_Results.xlsx", sheet("Connected_Formally", replace) firstrow(variables)
}

* 11. Attemp to connect
count if connection_status== 3
if r(N) > 0 {
    tab attempted2 if connection_status == 3 // Si pas manquant so there is a problem
    tabout attempted2 if connection_status == 3 using "Attemp_to_connect.xlsx", cells(freq col) format(0 1) clab(_) replace
}

list participant_id if connection_status !=3 & attempted2 == -999
list participant_id if connection_status !=3 & attempted2 == -888 // Ici il ya un problème parceque il a essayé de se connecter mais ne sait pas quand il a lancé la précodure un peu bizarre

* 15. Saving_methods
tab saving_methods, missing
list saving_methods if connection_status!=3 // If there is not -888 or -999 so n o problem
preserve
 keep if connection_status != 3
 export excel  using "HFC_Saving_Treatment_Results.xlsx", sheet("Saving_Methods_ConnStatus3", replace) firstrow(variables)
restore

* 16. Saving_methods_other
count if saving_methods555==1
gen a=r(N)
count
gen ss=r(N)
count if missing(saving_methods_other)
gen b=ss- r(N)
if a ==b {
	display "Correct"
}

* 17. Reasons_not_saving
count if saving_methods7==1
tab reasons_not_saving if saving_methods7 ==1, missing

/* 18. Saving_frequencies
tab saving_frequencies if inrange(saving_methods, 1, 6), missing
tabout saving_frequencies if inrange(saving_methods, 1, 6) using "HFC_Saving_Treatment_Results.xlsx", cells(freq col) format(0 1) clab(_) missing replace sheet(Saving_Frequencies_Methods1to6)*/

* 19. Identity_document
tab identity_document, missing
count if identity_document == -555 
if r(N) > 0 {
    list identity_document_other if identity_document == -555
}

* 21. willngness1
tab willngness1, missing
/* To findout the missing we can do this:
count if connection_status==3 
count if connection_fees_payment==1
count if saving_methods == 1
*/
tab willngness1 if connection_status==3 // if not missing it is not logic 

* 22. willngness2, willngness3, time_start_saving, willingnes_frequencies
foreach var of varlist willngness2 willngness3 time_start_saving willingnes_frequencies {
    tab `var' if willngness1 == 1, missing
    tabout `var' if willngness1 == 1 using "`var'_willigness_1.csv", cells(freq col) format(0 1) clab(_) replace
}


* 22.b. For this second case if person that chose No for willngness1 can not answer the question. So in the case we observe so information in the table there is a problem. mistyping
foreach var of varlist willngness2 willngness3 time_start_saving willingnes_frequencies {
    tab `var' if willngness1 !=1
	tabout `var' if willngness1 != 1 using "`var'_NOTWillngness1_0.csv", cells(freq col) format(0 1) clab(_) replace
}

* Therefore, we can fix this error by recoding those No by Yes. To do that we will use 
*replace willngness1=1 if willngness2 !=. &willngness1!=1

* 24. willingness_deposit_amount
tab willingness_deposit_amount if willngness1 !=1
tabout willingness_deposit_amount if willngness1 != 1 using "Willingness_Deposit_Amount_Not_1.csv", cells(freq col) format(0 1) clab(_) replace

tab willingness_deposit_amount if willngness1 == 1, missing
tabout willingness_deposit_amount if willngness1 == 1 using "Willingness_Deposit_Amount_1.csv", cells(freq col) format(0 1) clab(_) replace

* 25. willingness_deposit_amount_other
list willingness_deposit_amount_other if willingness_deposit_amount == -555 & willingness_deposit_amount_other <= 0
preserve
keep if willingness_deposit_amount == -555 & willingness_deposit_amount_other <= 0
count
if r(N) > 0 {
	export excel using "HFC_Saving_Treatment_Results.xlsx", sheet("Willingness_Deposit_Amount_Other", replace) firstrow(variables)
}
restore

* 26. willingness_time_account and time start saving
list participant_id if time_start_saving==0 | time_start_saving<0 
preserve
keep if time_start_saving==0 | time_start_saving<0
count
if r(N) > 0 {
	export excel  using "HFC_Saving_Treatment_Results.xlsx", sheet("time_start_saving", replace) firstrow(variables)
}
restore
list participant_id if time_start_saving>0 
tab willingness_time_account if willngness1 == 1, missing


* 29. explanation
tab explanation if reasons_not_saving1 == 1, missing
tabout explanation if reasons_not_saving1 == 1 using "explanation_not_saving", cells(freq col) format(0 1) clab(_) replace

* 30. Save_at_imf
tab save_at_imf if  explanation == 1, missing
tabout save_at_imf if  explanation == 1 using "save_at_imf.csv", cells(freq col) format(0 1) clab(_) replace

* 31. New_imf
tab new_imf if save_at_imf == 2, missing
list new_imf_other if new_imf == -555 
preserve
keep if new_imf == -555 
export excel participant_id new_imf_other using "HFC_Saving_Treatment_Results.xlsx", sheet("List_other_IMF", replace) firstrow(variables)
restore

* 32. New_imf
tab new_imf if save_at_imf == 4, missing
tabout new_imf if save_at_imf == 2 using "save_IMF_other.csv", cells(freq col) format(0 1) clab(_) replace 

* 35. Saving_frequencies2
tab saving_frequencies2 if saving_frequencies2<0, missing
tabout saving_frequencies2 if save_at_imf == 1 & saving_frequencies2<0 using "other_saving_plan.csv", cells(freq col) format(0 1) clab(_)  replace


* 36. Deposit_amount
tab deposit_amount if save_at_imf == 2, missing
list deposit_amount_other if deposit_amount == -555 & deposit_amount_other <= 0
count if deposit_amount == -555 & deposit_amount_other <= 0



* 37. Time_amount
tab time_amount if (saving_frequencies2 == 2 | saving_frequencies2 == 3) & deposit_amount == 1, missing
tabout time_amount if (saving_frequencies2 == 2 | saving_frequencies2 == 3) & deposit_amount == 1 using "Time_Amount_SavingFrequencies2_2or3_DepositAmount1.csv", cells(freq col) format(0 1) clab(_) replace

* 38. Finadev_id
tab finadev_id if identity_document == 2, missing

* 39. Comments
count if !missing(comments) 

* 41. Visit_number
sum visit_number
count if visit_number < 1 | visit_number > 3
if r(N) > 0 {
    export excel participant_id visit_number using "HFC_Saving_Treatment_Results.xlsx", sheet("Participant_Visit_Number") firstrow(variables) replace
}

* 42. End_interview
tab end_interview, missing

* 43. End_interview_reasons
tab end_interview_reasons, missing
count if end_interview_reasons == -555
if r(N) > 0 {
    list end_interview_reasons_other if end_interview_reasons == -555 
	export excel end_interview_reasons_other if end_interview_reasons==555 "HFC_Saving_Treatment_Results.xlsx", sheet("Reasons_end_interview) firstrow(variables) replace
}

* 44. Survey_language
count if survey_language == -555
if r(N) > 0 {
    list survey_langage_other if survey_language == -555
	tabout survey_langage_other if survey_language == -555 using "Survey_language_other.csv", cells(freq col) format(0 1) clab(_) replace
}


* 45. Survey_status
count if survey_status == -555
if r(N) > 0 {
    list survey_status_other if survey_status == -555
	tabout survey_status_other if survey_status == -555 using "Survey_Status_other.csv", cells(freq col) format(0 1) clab(_) replace
}


* 46. Reasons
count if survey_status == 2 | survey_status == 3
if r(N) > 0 {
    tab reasons if survey_status == 2 | survey_status == 3, missing
    tabout reasons if survey_status == 2 | survey_status == 3 using "Reasons_stop_survey.csv", cells(freq col) format(0 1) clab(_) replace
}



