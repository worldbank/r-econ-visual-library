/* Impact Evaluation in Practice, second edition
HISP Case Study
do file for tables and figures in book */

clear
clear matrix
set more off
*============================*
*Install packages to update Stata as needed
*============================*
ssc install psmatch2, replace
net install st0366.pkg, all replace force from(http://www.stata-journal.com/software/sj14-4/)
net install sg65.pkg, all replace force from(http://www.stata.com/stb/stb35)
net install sxd4.pkg, all replace force from(http://www.stata.com/stb/stb60)

*============================*
*Specify the access path to the computer folder you will use for the analysis
*============================*
cd "INSERT THE PATH OF THE FOLDER WHERE YOU SAVED THE DATASET, EG. C:\My Documents\HISP"
*============================*
*Initialize
*============================*
cap log close
log using "solution_log.txt", replace 
*Open the cleaned data set
use "evaluation.dta" 

*============================*
*Macros: make sure you run this piece of code before running the regressions
*============================*
*put together a standard list of explanatory variables to be used in multivariate analysis
global controls  age_hh age_sp educ_hh educ_sp female_hh indigenous hhsize dirtfloor bathroom land hospital_distance
describe

*============================*
*Start solution
*============================*

*Method 1: No Design - before and after (Chapter 3)
* In this method, you compare the before and after situation of households who 
* enrolled in the program in villages covered by HISP.

*Select the relevant data
use "evaluation.dta", clear
keep if treatment_locality==1 
keep if enrolled ==1

*Table 3.1 Method 1-HISP Impact Using Before-After (Comparison of Means) 
ttest health_expenditures, by(round) 

*Table 3.2 Method 1-HISP Impact Using Before-After (Regression Analysis) Linear Regression
reg health_expenditures round, cl(locality_identifier)

*Table 3.2 Method 1-HISP Impact Using Before-After (Regression Analysis) Multivariate Linear Regression
reg health_expenditures round $controls, cl(locality_identifier)

*----------------------------------------------------*
*Method 2: No Design - enrolled-not enrolled (Chapter 3)
* In this method, you compare follow-up situation of enrolled and not enrolled households in villages covered by HISP.

*Select the relevant data
use "evaluation.dta", clear
keep if treatment_locality==1
keep if round==1

*Table 3.3 Method 2-HISP Impact Using Enrolled-Nonenrolled (Comparison of Means)
ttest health_expenditures, by(enrolled)

*Table 3.4 Method 2-HISP Impact Using Enrolled-Nonenrolled (Regression Analysis) Linear Regression
reg health_expenditures enrolled, cl(locality_identifier)

*Table 3.4 Method 2-HISP Impact Using Enrolled-Nonenrolled (Regression Analysis) Multivariate Linear Regression
reg health_expenditures enrolled $controls, cl( locality_identifier)

*----------------------------------------------------*
*Method 3: Randomized assignment (Chapter 4)
* In this method, you compare follow-up situation of eligible households in treatment and comparison villages.

*Select the relevant data
use "evaluation.dta", clear
keep if eligible==1

*Table 4.1 Method 3-Balance between Treatment and Comparison Villages at Baseline for Health Expenditures 
ttest health_expenditures if round ==0, by(treatment_locality)

*Table 4.1 Method 3-Balance between Treatment and Comparison Villages at Baseline for Controls 
foreach x of global controls {
	describe `x'
	ttest `x' if round ==0, by(treatment_locality)
	}

*Table 4.2 Method 3-HISP Impact Using Randomized Assignment (Comparison of Means) at Baseline 
ttest health_expenditures if round ==0, by(treatment_locality) 

*Table 4.2 Method 3-HISP Impact Using Randomized Assignment (Comparison of Means) at Follow-up 
ttest health_expenditures if round ==1, by(treatment_locality)

*Table 4.3 Method 3-HISP Impact Using Randomized Assignment (Regression Analysis) Linear Regression 
reg health_expenditures treatment_locality if round ==1, cl(locality_identifier)

*Table 4.3 Method 3-HISP Impact Using Randomized Assignment (Regression Analysis) Multivariate Linear Regression 
reg health_expenditures treatment_locality $controls if round ==1, cl(locality_identifier)

*----------------------------------------------------*
*Method 4: Instrumental Variables (Chapter 5)
* In this method, everyone is eligible for the program. You compare what happens in promoted and non-promoted villages.

*Select the relevant data
use "evaluation.dta", clear
drop eligible
drop treatment_locality
drop enrolled


*Table 5.1	Method 4-HISP Impact Using Randomized Promotion (Comparison of Means) at Baseline 
ttest health_expenditures if round ==0, by(promotion_locality)

*Table 5.1	Method 4-HISP Impact Using Randomized Promotion (Comparison of Means) at Follow-up 
ttest health_expenditures if round ==1, by(promotion_locality)

*Table 5.1	Method 4-HISP Impact Using Randomized Promotion (Comparison of Means) for Enrollment
ttest enrolled_rp if round ==1, by(promotion_locality)

*Table 5.1 Method 4-HISP Impact Using Randomized Promotion (Regression Analysis) Linear Regression
ivreg health_expenditures (enrolled_rp = promotion_locality) if round ==1, first

*Table 5.2 Method 4-HISP Impact Using Randomized Promotion (Regression Analysis) Multivariate Linear Regression
ivreg health_expenditures (enrolled_rp = promotion_locality) $controls if round ==1, first

*----------------------------------------------------*
*Method 5: RDD (Chapter 6)
* In this method, you compare health expenditures at follow-up between households just above 
* and just below the poverty index threshold, in the treatment localities.

*Select the relevant data
use "evaluation.dta", clear
keep if treatment_locality==1

*Additional Poverty Index and Health Expenditures at the Health Insurance Subsidy Program Baseline
reg health_expenditures poverty_index if round ==0
predict he_pred0
graph7 he_pred0 poverty_index if round ==0

*Figure 6.5 HISP Household Density by Poverty Index 
	* The below line of code creates a simple graph.
	kdensity poverty_index

	*The below lines of code allow you to reproduce figure 6.7 exactly as depicted in the book
	*Figure 6.5 HISP: Density of Households, by Baseline Poverty Index 
	#delimit;
	cap erase fig65.gph;
	kdensity poverty_index, 
		saving(fig65) 
		title("") 
		note("Technical note: Density estimated using univariate epanechnikov kernel method.") 
		ytitle("Estimated density") 
		xtitle("Baseline poverty index (20-100)") 
		ylabel(, angle(horizontal)) 
		plotregion(fcolor(white)) 
		graphregion(fcolor(white)) 
		lwidth(medthick) 
		lcolor(black)
		xline(58, lcolor(black) lwidth(medthick))
		text(.005 60 "Not eligible", placement(e) box)
		text(.005 56 "Eligible", placement(w) box)
		text( 0 58 "58", placement(nw)) ;

*Figure 6.6 Participation in HISP, by Baseline Poverty Index
* (Note: RDD uses the random assignment scenario, which assumes full compliance)
	* The below line of code creates a simple graph.
	rdplot enrolled poverty_index if treatment_locality==1, c(58) p(1) numbinl(58) numbinr(42) 

	*The below lines of code allow you to reproduce figure 6.6 exactly as depicted in the book
	#delimit;
	graph twoway scatter enrolled poverty_index , 
		title("") 
		ylabel(, angle(horizontal)) 
		ytitle("Participation rate in HISP") 
		xtitle("Baseline poverty index (20-100)") 
		plotregion(fcolor(white)) 
		graphregion(fcolor(white)) 
		xline(58, lcolor(black) lwidth(medthick))
		msize(medium) mcolor(black)
		text(.5 60 "Not eligible", placement(e) box)
		text(.5 56 "Eligible", placement(w) box);
	#delimit cr

*Figure 6.6 Poverty Index and Health Expenditures, HISP, Two Years Later 

/*Normalize the poverty index at 0*/ 
gen poverty_index_left=poverty_index-58 if poverty_index<=58 
	replace poverty_index_left=0 if poverty_index>58
gen poverty_index_right=poverty_index-58 if poverty_index>58 
	replace poverty_index_right=0 if poverty_index<=58

reg health_expenditures poverty_index_left poverty_index_right eligible if round ==1
predict he_pred1

	* The below line of code creates a simple graph.
	graph7 he_pred1 poverty_index if round ==1

	*The below lines of code allow you to reproduce figure 6.6 exactly as depicted in the book
	#delimit ;
	graph twoway scatter health_expenditures poverty_index if round==1 & treatment_locality==1 & health_expenditures<60, msize(vtiny) mcolor(black)||
	scatter he_pred1 poverty_index if round==1 , msize(medium) mcolor(black) msymbol(O) ||
	pcarrowi 20 59 10 59, msize(thick) mlwidth(thick) mcolor(black) lwidth(medthick) lcolor(black) ||, 
	title("")
	ytitle("Health expenditures ($)")
	xtitle("Baseline poverty index (20-100)") 
	ylabel(, angle(horizontal)) 
	plotregion(fcolor(white)) 
	graphregion(fcolor(white)) 
	xline(58, lcolor(black) lwidth(medthick))
	text(55 60 "Not eligible", placement(e) box)
	text(55 56 "Eligible", placement(w) box)
	text(21 55 "A", placement(w) box)
	text(7 60 "B", placement(e) box)
	text( -1 58 "58", placement(ne))
	legend (lab(3 "Estimated impact on health expenditures"));
	#delimit cr

*Table 6.1 Method 5-HISP Impact Using Regression Discontinuity Design (Regression Analysis) Multivariate Linear Regression
reg health_expenditures eligible poverty_index_left poverty_index_right $controls if round ==1

*----------------------------------------------------*
*Method 6: Dif in Dif (Chapter 7)
* In this method, you compare the change in health expenditures over time 
* between enrolled and nonenrolled households in the treatment localities.

*Select the relevant data
use "evaluation.dta", clear
keep if treatment_locality==1

*Table 7.2 Method 6-HISP Impact Using Difference-in-Differences (Before-after comparison of means for nonenrolled households)
ttest health_expenditures if enrolled ==0, by(round)

*Table 7.2 Method 6-HISP Impact Using Difference-in-Differences (Before-after comparison of means for enrolled households)
ttest health_expenditures if enrolled ==1, by(round)

*Table 7.3 Method 6-HISP Impact Using Difference-in-Differences (Regression Analysis) Linear Regression
/*Create the DD variable*/
gen enrolled_round = enrolled*round
reg health_expenditures enrolled_round round enrolled, cl(locality_identifier)

*Table 7.3 Method 6-HISP Impact Using Difference-in-Differences (Regression Analysis) Multivariate Regression
reg health_expenditures enrolled_round round enrolled $controls, cl(locality_identifier)


*----------------------------------------------------*

 *Method 7: Matching (Chapter 8) - restricted set
* In this method, you compare health expenditures at follow-up between enrolled 
* households and a set of matched nonenrolled households from both treament and comparison villages.

*Select the relevant data
use "evaluation.dta", clear

* reshape the database so that each household appears in only one row.
* The information on baseline and follow-up for each household appears in a single row.
* This is called a "wide" dataset.

reshape wide health_expenditures age_hh age_sp educ_hh educ_sp hospital, i(household_identifier) j(round)
* Baseline characteristics now appear twice. Keep only one.
drop age_hh1 age_sp1 educ_hh1 educ_sp1 hospital1
rename age_hh0 age_hh
rename age_sp0 age_sp
rename educ_hh0 educ_hh
rename educ_sp0 educ_sp
rename hospital0 hospital

/*Graph to show region of common support*/ 
probit enrolled age_hh educ_hh
predict pscore
kdensity pscore if enrolled ==1, gen(take1 den1)
kdensity pscore if enrolled ==0, gen(take0 den0)
twoway (line den0 take0) (line den1 take1)

* Nearest neighbor matching on a 0/1 variable requires the observations to be sorted in a random order. 
* Sort the observations in a random order
* generate a random number and sort observations according to that number
set seed 100
generate u=runiform()
sort u

*Table 8.1 - Table 8.3 HISP Impact Using Matching
psmatch2 enrolled age_hh educ_hh, out(health_expenditures1) /*Note: You can install psmatch2 with the command 'ssc install psmatch2'*/
tab _support

*Table 8.3: Standard error on the impact estimate
* There are different views on the way to estimate the standard error - here are two of them.
* Estimating standard errors using bootstrapping.
set seed 100
bootstrap r(att) : psmatch2 enrolled age_hh educ_hh, out(health_expenditures1)
* Estimating standard errors using linear regression. (Reported in the book)
reg health_expenditures1 enrolled [fweight=_weight]

*----------------------------------------------------*

*Method 7: Matching (Chapter 8) - full set
use "evaluation.dta", clear

* reshape the database
reshape wide health_expenditures age_hh age_sp educ_hh educ_sp hospital, i(household_identifier) j(round)
drop age_hh1 age_sp1 educ_hh1 educ_sp1 hospital1
rename age_hh0 age_hh
rename age_sp0 age_sp
rename educ_hh0 educ_hh
rename educ_sp0 educ_sp
rename hospital0 hospital

/*Graph to show region of common support*/ 
probit enrolled $controls 
predict pscore
kdensity pscore if enrolled ==1, gen(take1 den1)
kdensity pscore if enrolled ==0, gen(take0 den0)
twoway (line den0 take0) (line den1 take1)

* Nearest neighbor propensity score matching on a 0/1 variable requires the observations to be sorted in a random order. 
* Sort the observations in a random order
* generate a random number and sort observations according to that number
set seed 100
generate u=runiform()
sort u

*Table 8.1 - Table 8.3 HISP Impact Using Matching
psmatch2 enrolled $controls, out(health_expenditures1) 
/*Note: You can install psmatch2 with the command 'ssc install psmatch2'*/
tab _support

*Table 8.3: Standard error on the impact estimate
* There are different views on the way to estimate the standard error - here are two of them.
* Estimating standard errors using bootstrapping.
set seed 100
bootstrap r(att) : psmatch2 enrolled $controls, out(health_expenditures1)
* Estimating standard errors using linear regression.  (Reported in the book)
reg health_expenditures1 enrolled [fweight=_weight]

*----------------------------------------------------*
* Matched difference-in-differences

* Manually compute the matched difference-in-differences
sort _id
gen health_exp_match0 = health_expenditures0[_n1] /*variable contains health expenditures of nearest neighbor match at baseline */
gen health_exp_match1 = health_expenditures1[_n1] /*variable contains health expenditures of nearest neighbor match at follow-up */
summ health_expenditures0 health_expenditures1 health_exp_match0 health_exp_match1 if enrolled==1
gen matchedDD=(health_expenditures1-health_expenditures0)-(health_exp_match1-health_exp_match0) if enrolled==1
summ matchedDD

* Use regression to compute matched difference-in-differences  and standard error on DD
gen diff=health_expenditures1-health_expenditures0
tab _weight, missing
gen matched=_weight>=1 & _weight~=.& enrolled==0
drop if matched==0&enrolled==0
reg diff enrolled [fweight=_weight]

* Note that you might find some small difference in the estimates depending on the software version.


*----------------------------------------------------*
* Power Calculations for HISP+ (Chapter 15)

use "evaluation.dta", clear

*Note: Focus on the randomized assignment case in chapter 4
drop if eligible==0

*Baseline parameters 
sum health_expenditures if round==0
	iclassr health_expenditures locality_identifier if round==0, noisily 
/*Note: You may need to install the iclassr command. */

sum hospital if round==0
	iclassr hospital locality_identifier if round== 0 , noisily

*Follow-up parameters in treatment communities 
sum health_expenditures if round==1 & treatment_locality==1 
	local m1 = `r(mean)' /*This saves the mean which will be used as m1 in power calculations below*/
	local sd = `r(sd)' /*This saves the standard deviation which will be used as sd1 and sd2 in power calclulations below*/

iclassr health_expenditures locality_identifier if round==1 & treatment_locality==1, noisily /*This gives you the intra-cluster correlation, or rho*/
	local rho = $S_1 /*This saves the intra-cluster correlation, or rho, which will be used in clustered power calculations below*/
	display `rho'

sum hospital if round==1 & treatment_locality==1
	local m1_h = `r(mean)'
	local sd_h = `r(sd)'

iclassr hospital locality_identifier if round==1 & treatment_locality==1, noisily

*Power Calculation for Random Sample (Absolute Effects)

*Table 15.2 - Sample Size Required for Various Minimum Detectable Effects (Decrease in Health Expenditures), Power = 0.9, No Clustering

*Compute mean2 wih the minimum detectable effect
local mde_1 = `m1'-1
local mde_2 = `m1'-2
local mde_3 = `m1'-3

/*$1 Minimum Detectable Effect*/ sampsi `m1' `mde_1', p(0.9) r(1) sd1(`sd') sd2(`sd') /*Note: Use the command sampncti when sample sizes are small*/
/*$2 Minimum Detectable Effect*/ sampsi `m1' `mde_2', p(0.9) r(1) sd1(`sd') sd2(`sd')
/*$3 Minimum Detectable Effect*/ sampsi `m1' `mde_3', p(0.9) r(1) sd1(`sd') sd2(`sd')

*Table 15.3 - Sample Size Required for Various Minimum Detectable Effects (Decrease in Health Expenditures), Power = 0.8, No Clustering
sampsi `m1' `mde_1', p(0.8) r(1) sd1(`sd') sd2(`sd')
sampsi `m1' `mde_2', p(0.8) r(1) sd1(`sd') sd2(`sd')
sampsi `m1' `mde_3', p(0.8) r(1) sd1(`sd') sd2(`sd')

*Table 15.4 - Sample Size Required for Various Minimum Detectable Effects (Increase in Hospitalization Rate), Power = 0.8, No Clustering

*Compute mean2 wih the minimum detectable effects for hospitalization rates (in %)
local mde_h_1 = `m1_h'+0.01
local mde_h_2 = `m1_h'+0.02
local mde_h_3 = `m1_h'+0.03

/*1% Minimum Detectable Effect*/ sampsi `m1_h' `mde_h_1', p(0.8) r(1) sd1(`sd_h') sd2(`sd_h')
/*2% Minimum Detectable Effect*/ sampsi `m1_h' `mde_h_2', p(0.8) r(1) sd1(`sd_h') sd2(`sd_h')
/*3% Minimum Detectable Effect*/ sampsi `m1_h' `mde_h_3', p(0.8) r(1) sd1(`sd_h') sd2(`sd_h')

*Power Calculation for Clustered Sample (Absolute Effects)

*Table 15.5 - Sample Size Required for Various Minimum Detectable Effects, Power = 0.8, Max of 100 Clusters (Decrease in Health Expenditures)
sampsi `m1' `mde_1', p(0.8) r(1) sd1(`sd') sd2(`sd')
	sampclus, numclus(100) rho(`rho') /*This corrects for clusters, Note: You may need to install the sampclus command*/
sampsi  `m1' `mde_2', p(0.8) r(1) sd1(`sd') sd2(`sd')
	sampclus, numclus(100) rho(`rho') 
sampsi  `m1' `mde_3', p(0.8) r(1) sd1(`sd') sd2(`sd')
 	sampclus, numclus(100) rho(`rho') 

*Power Calculation for Clustered Sample (Varying Number of Clusters, Minimum Detectable Effect of $2 Decrease in Health Expenditures) 

*Table 15.6 - Sample Size Required to Detect a $2 Minimum Impactfor Various Numbers of Clusters, Power = 0.8

/*30 Clusters*/sampsi  `m1' `mde_2', p(0.8) r(1) sd1(`sd') sd2(`sd')
	sampclus, numclus(30) rho(`rho')
/*58 Clusters*/sampsi  `m1' `mde_2', p(0.8) r(1) sd1(`sd') sd2(`sd')
	sampclus, numclus(58) rho(`rho')
/*81 Clusters*/sampsi  `m1' `mde_2', p(0.8) r(1) sd1(`sd') sd2(`sd')
	sampclus, numclus(81) rho(`rho')
/*90 Clusters*/sampsi  `m1' `mde_2', p(0.8) r(1) sd1(`sd') sd2(`sd')
	sampclus, numclus(90) rho(`rho')
/*120 Clusters*/sampsi  `m1' `mde_2', p(0.8) r(1) sd1(`sd') sd2(`sd')
	sampclus, numclus(120) rho(`rho')


*============================*

*End
log close

