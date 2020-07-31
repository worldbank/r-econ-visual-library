use ReplicationDataGhanaJDE.dta, clear
keep wave sheno timecash timeequip timetreat cashtreat equiptreat ///
      realfinalprofit totalK expend_health_3months expend_education_3months expend_total_3months ///
      fem highcapture highcapital male_male male_mixed female_female female_mixed ///
      finalsales  inventories  hourslastweek useasusu businesshome married ///
      educ_years digitspan akanspeaker gaspeaker age firmage everloan business_taxnumber ///
      trimgroup control
save ReplicationDataGhanaJDE_short.dta, replace
