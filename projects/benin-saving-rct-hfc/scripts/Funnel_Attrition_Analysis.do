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
kobo2stata using "data_07.07.24.xlsx", xlsform("questionnaire_06.07.24.11.50.xlsx") surveylabel("label::French") choiceslabel("label::French") dropnotes usenotsave
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

****Correction
list today participant_id if dup_tag ==1
drop if participant_id=="ME0218" & today==23557
drop if participant_id=="ME0307" & today==23558
drop if participant_id=="ME0352" & today==23558
drop if participant_id=="ME0411" & today==23557
drop if participant_id=="ME0414" & today==23558
drop if participant_id=="ME0801" & today==23557
drop if participant_id=="ME0857" & today==23558
drop if participant_id=="ME0909" & today==23558
drop if participant_id=="ME1184" & today==23558
drop if participant_id=="ME1459" & today==23559
drop if participant_id=="ME1802" & today==23559
drop if participant_id=="ME1825" & today==23558
drop if participant_id=="ME1851" & today==23558

save "saving1.dta", replace


** Tabulation per region
by arrondissement , sort : asdoc tabulate village


*** Respondent availability
list participant_id if respondent_available == 3 | respondent_available==-888
count if respondent_available == 3 | respondent_available==-888
display 277- r(N)

*** Donc à ce niveau sur les 277, 23 refus obtenus so nous sommes à 254

** Connection status
tab connection_status
count if connection_status==3
**** On obtient 19 donc moins encore ce qui revient à 235

*** Connection Fees Payment
tab connection_fees_payment
count if connection_fees_payment==1
**** 10 ont déjà payer les frais donc on est finalement à 225

**** Nombre de personnes épargnant
// People who save
gen saves = 0 if  saving_methods7==1 | saving_methods888==1
replace saves =1 if saves==. & connection_fees_payment!=1 & connection_status !=3 & respondent_available != 3 & respondent_available!=-888
count if saves==1

// 3. People who think saving is a good idea
count if !missing(willngness1) & connection_fees_payment!=1 & connection_status !=3 & respondent_available != 3 & respondent_available!=-888

// 4. People who adhere to the idea of saving
count if !missing(willngness2) & connection_fees_payment!=1 & connection_status !=3 & respondent_available != 3 & respondent_available!=-888

// 5. People willing to work in the second phase
count if !missing(willngness3) & connection_fees_payment!=1 & connection_status !=3 & respondent_available != 3 & respondent_available!=-888

// 6. Minimum amount, deadlines, and people formally connected
tab  willingness_deposit_amount_other

