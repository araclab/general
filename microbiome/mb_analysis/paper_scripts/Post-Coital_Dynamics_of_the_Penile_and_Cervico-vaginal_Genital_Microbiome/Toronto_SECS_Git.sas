 /*============================================================================
 Program Name:  SECS Microbiome.sas 
 Author......:  Dan Park
 Date........:	23FEB2021
 Language....:  SAS 9.4
 Purpose.....;  
 Input.......:  
 Output......: 	
 Use.........: 
 Notes.......:   
===========================   REVISION LOG   ==================================

============================================================================= */

dm 'clear log';

*---------------------;

PROC IMPORT OUT= WORK.genus_raw 
            DATAFILE= "path/file" 
            DBMS=xlsx REPLACE;
			GETNAMES=YES;
RUN;

PROC IMPORT OUT= WORK.asv_raw 
            DATAFILE= "path/file" 
            DBMS=xlsx REPLACE;
			GETNAMES=YES;
RUN;

PROC IMPORT OUT= WORK.species_raw 
            DATAFILE= "path/file" 
            DBMS=xlsx REPLACE;
			GETNAMES=YES;
RUN;

PROC IMPORT OUT= WORK.meta_raw
            DATAFILE= "path/file" 
            DBMS=xlsx REPLACE;
			GETNAMES=YES;
RUN;

PROC IMPORT OUT= WORK.id_conc
            DATAFILE= "path/file" 
            DBMS=xlsx REPLACE;
			GETNAMES=YES;
RUN;

PROC IMPORT OUT= WORK.id_conc
            DATAFILE= "path/file" 
            DBMS=xlsx REPLACE;
			GETNAMES=YES;
RUN;

PROC IMPORT OUT= WORK.immune_raw
            DATAFILE= "path/file" 
            DBMS=xlsx REPLACE;
			GETNAMES=YES;
RUN;

*==================================;
*Descriptive analysis;

proc contents data=secs_analytic;
run;

proc freq data=meta_raw;
table gender;
run;

proc freq data=meta;
table gender;
run;

proc means data=samples n mean;
var age log_std_qty;
class site time;
run;

*Get age info for included IDs;
proc sort data=meta; by ID; run;
proc sort data=secs_analytic; by ID; run;
data meta_incl;
merge secs_analytic (in=a) meta partner_id;
by ID;
if a;
keep ID Age gender circumcision BVStatusE FemaleEthnicity MaleEthnicity PID sex_type;
run;
proc sort data=meta_incl nodups ; by ID; run;

proc means data=meta_incl n mean std;
var age ;
class gender ;
run;

proc freq data=meta_raw;
table gender ;
run;

proc freq data=meta_incl;
table gender * ( BVStatusE circumcision sex_type FemaleEthnicity MaleEthnicity);
format gender gender. circumcision circumcision. ;
run;

*Ethnicity;
proc freq data=samples;
table femaleethnicity;
where time=1 and gender=0; /*Switch to time=2 for additional ID*/
format gender gender. ;
run;

proc freq data=samples;
table maleethnicity;
where time=2 and gender = 1;
format gender gender. ;
run;

proc freq data=samples; table site * id / norow nocol nopercent; run;

proc freq data=samples;
table site * time / norow nocol nopercent;
run;

proc sgplot data=samples;
scatter x=site y=SexParN / jitter;
where time = 1;
run;

proc freq data=samples;
table site * sex_type * time  / norow  nopercent missing;
where std_qty ^= .;
run;

proc freq data=samples;
table site * circumcision * time  / norow nocol nopercent;
format sex_type sex_type. circumcision circumcision.;
run;

proc freq data=samples;
table site * sex_type * circumcision * time  / norow nocol nopercent;
format sex_type sex_type. circumcision circumcision.;
run;

proc freq data=samples;
table sex_type * circumcision  /  norow nopercent chisq;
where site = "CorSul" and time=1;
format sex_type sex_type. circumcision circumcision.;
run;

proc freq data=samples;
table circumcision * condom  /  nocol nopercent chisq missing;
where site = "CorSul" and time=1;
format sex_type sex_type. circumcision circumcision.;
run;

proc freq data=samples;
table DayPostBln Cyclephase;
where site = "Cervical" and time = 1;
run;

proc freq data=samples;
table NugentBV1 ;
where site = "Cervical" and time = 1;
run;

proc sgplot data=samples;
histogram DayPostBln / binwidth=1;
xaxis min=0;
where site = "Cervical" and time = 1;
run;

proc sgplot data=samples;
vbar F_EthnicityCat;
where site = "Cervical" and time = 1;
run;

proc sgplot data=samples;
vbar NugentBV1;
where site = "Cervical" and time = 1;
format nugentbv1 nugentbv.;
run;

proc freq data=samples;
table NugentBV1 * F_EthnicityCat / nocol nopercent chisq;
where site = "Cervical" and time = 1;
format nugentbv1 nugentbv.;
run;

proc freq data=samples;
table ContraUSe;
where site = "Cervical" and time = 2;
run;

proc means data=samples;
var Baseline_2hn _2h_post_sex_visitn _8h_Since_sexn _2days_since_sexn;
where site = "Cervical" and time = 2;
run;

*---------------------------;
*Overview of prevalence, relative abundance, absolute abundance;

*Prevalence;
data prevalence;
	length taxa $30. pct_row 8. count 8. prev_T1 8. prev_T2 8. prev_T3 8. prev_T4 8. n_prev_T1 8. n_prev_T2 8. n_prev_T3 8. n_prev_T4 8.;
run;

proc freq data=samples_long noprint;
table taxa / out=prev_temp;
run;

proc append base=prevalence data=prev_temp force; run;

data prevalence; set prevalence;
	if taxa in ('' 'std_qty') then delete;
run;

%macro prev (var= , sample=);
proc freq data=samples_long noprint;
title '&sample.';
table taxa * &var. / nocol nopercent  out=prev_temp outpct;
where  site = "&sample.";
run;

data prev_temp; set prev_temp;
	if &var. = . then delete; else
	if &var. = 0 and PCT_ROW = 100 then PCT_ROW = 0; else
	if &var. = 0 then delete;

	keep taxa pct_row COUNT;
run;

data prevalence;
	merge prevalence (in=a) prev_temp;
	by taxa;
	if a;

	&var. = pct_row; 
	n_&var. = count;
run;

data prev_&sample.; set prevalence; run;
%mend;

%prev (var=prev_T1, sample=CorSul);
%prev (var=prev_T2, sample=CorSul);
%prev (var=prev_T3, sample=CorSul);
%prev (var=prev_T4, sample=CorSul);

%prev (var=prev_T1, sample=Cervical);
%prev (var=prev_T2, sample=Cervical);
%prev (var=prev_T3, sample=Cervical);
%prev (var=prev_T4, sample=Cervical);


proc export data=prev_cervical
			OUTFILE = "path/file"
			DBMS=xlsx REPLACE;
run;

proc export data=prev_corsul
			OUTFILE = "path/file"
			DBMS=xlsx REPLACE;
run;


*Species Level Prevalence;
*Prevalence;
data prevalence_species;
	length taxa $30. pct_row 8. count 8. prev_T1 8. prev_T2 8. prev_T3 8. prev_T4 8. n_prev_T1 8. n_prev_T2 8. n_prev_T3 8. n_prev_T4 8.;
run;

proc freq data=species_long noprint;
table taxa / out=prev_temp;
run;

proc append base=prevalence_species data=prev_temp force; run;

data prevalence_species; set prevalence_species;
	if taxa in ('' 'std_qty') then delete;
run;

%macro prev (var= , sample=);
proc freq data=species_long noprint;
title '&sample.';
table taxa * &var. / nocol nopercent  out=prev_temp outpct;
where  site = "&sample.";
run;

data prev_temp; set prev_temp;
	if &var. = . then delete; else
	if &var. = 0 and PCT_ROW = 100 then PCT_ROW = 0; else
	if &var. = 0 then delete;

	keep taxa pct_row COUNT;
run;

data prevalence_species;
	merge prevalence_species (in=a) prev_temp;
	by taxa;
	if a;

	&var. = pct_row;
	n_&var. = count;
run;

data prev_sp_&sample.; set prevalence_species; run;
%mend;

%prev (var=prev_T1, sample=CorSul);
%prev (var=prev_T2, sample=CorSul);
%prev (var=prev_T3, sample=CorSul);
%prev (var=prev_T4, sample=CorSul);

%prev (var=prev_T1, sample=Cervical);
%prev (var=prev_T2, sample=Cervical);
%prev (var=prev_T3, sample=Cervical);
%prev (var=prev_T4, sample=Cervical);

proc export data=prev_sp_cervical
			OUTFILE = "path/file"
			DBMS=xlsx REPLACE;
run;

proc export data=prev_sp_corsul
			OUTFILE = "path/file"
			DBMS=xlsx REPLACE;
run;

*-;
*BVAB / BASICs;
data secs_analytic; set secs_analytic;
if p_BVAB > 0 then prev_BVAB = 1; else
if p_BVAB = 0 then prev_BVAB = 0;
run;

proc means data=secs_analytic;
var prev_BVAB prev_BASIC;
class time site;
run;

proc means data=secs_analytic;
var prev_BVAB prev_BASIC;
class condom site time  ;
run;


*By stratifications;
*Genus level;
data prevalence;
	length taxa $30. pct_row 8. count 8. prev_T1 8. prev_T2 8. prev_T3 8. prev_T4 8. n_prev_T1 8. n_prev_T2 8. n_prev_T3 8. n_prev_T4 8.;
run;

proc freq data=samples_long noprint;
table taxa / out=prev_temp;
run;

proc append base=prevalence data=prev_temp force; run;

data prevalence; set prevalence;
	if taxa in ('' 'std_qty' 'Age' 'BVStatusA' 'BVStatusE' 'Cyclephase' 'DayPostBln' 'Gender'
		'MaleEthnicity' 'NugentBV1' 'NugentBV1_Cat' 'NugentBV2' 'NugentBV2_Cat' 'NugentBV3' 'NugentBV3_Cat'
		'NugentBV4' 'NugentBV4_Cat' 'NugentSA' 'NugentSE' 'ORDER6' 'ORDER6c' 'ORDER6nc' 'ORDER7' 'ORDER7c'
		'ORDER7nc' 'ORDER8' 'ORDER8c' 'ORDER8nc' 'ORDER9' 'ORDER9c' 'ORDER9nc' 'SexParN' 'condom') 
	then delete;
run;

%macro prev (var= , sample=, covar=, value=);
proc freq data=samples_long noprint;
title '&sample.';
table taxa * &var. / nocol nopercent  out=prev_temp outpct;
where  site = "&sample." and &covar.=&value.;
run;

data prev_temp; set prev_temp;
	if &var. = . then delete; else
	if &var. = 0 and PCT_ROW = 100 then PCT_ROW = 0; else
	if &var. = 0 then delete;

	keep taxa pct_row COUNT;
run;

data prevalence;
	merge prevalence (in=a) prev_temp;
	by taxa;
	if a;

	&var. = pct_row; 
	n_&var. = count;
run;

data prev_&sample._strata; set prevalence; run;
%mend;

*Nugent Scores;
%prev (var=prev_T1, sample=Cervical, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T2, sample=Cervical, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T3, sample=Cervical, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T4, sample=Cervical, covar=NugentBV1_Cat, value=2);

%prev (var=prev_T1, sample=CorSul, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T2, sample=CorSul, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T3, sample=CorSul, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T4, sample=CorSul, covar=NugentBV1_Cat, value=2);

*Cycle phase;
%prev (var=prev_T1, sample=Cervical, covar=cyclephase, value=1);
%prev (var=prev_T2, sample=Cervical, covar=cyclephase, value=1);
%prev (var=prev_T3, sample=Cervical, covar=cyclephase, value=1);
%prev (var=prev_T4, sample=Cervical, covar=cyclephase, value=1);

%prev (var=prev_T1, sample=CorSul, covar=cyclephase, value=1);
%prev (var=prev_T2, sample=CorSul, covar=cyclephase, value=1);
%prev (var=prev_T3, sample=CorSul, covar=cyclephase, value=1);
%prev (var=prev_T4, sample=CorSul, covar=cyclephase, value=1);

*Circumcision;
%prev (var=prev_T1, sample=Cervical, covar=circumcision, value=0);
%prev (var=prev_T2, sample=Cervical, covar=circumcision, value=0);
%prev (var=prev_T3, sample=Cervical, covar=circumcision, value=0);
%prev (var=prev_T4, sample=Cervical, covar=circumcision, value=0);

%prev (var=prev_T1, sample=CorSul, covar=circumcision, value=1);
%prev (var=prev_T2, sample=CorSul, covar=circumcision, value=1);
%prev (var=prev_T3, sample=CorSul, covar=circumcision, value=1);
%prev (var=prev_T4, sample=CorSul, covar=circumcision, value=1);

*Condom use - no condom;
%prev (var=prev_T1, sample=Cervical, covar=condom, value=0);
%prev (var=prev_T2, sample=Cervical, covar=condom, value=0);
%prev (var=prev_T3, sample=Cervical, covar=condom, value=0);
%prev (var=prev_T4, sample=Cervical, covar=condom, value=0);

%prev (var=prev_T1, sample=CorSul, covar=condom, value=0);
%prev (var=prev_T2, sample=CorSul, covar=condom, value=0);
%prev (var=prev_T3, sample=CorSul, covar=condom, value=0);
%prev (var=prev_T4, sample=CorSul, covar=condom, value=0);

*Condom use - condom used;
%prev (var=prev_T1, sample=Cervical, covar=condom, value=1);
%prev (var=prev_T2, sample=Cervical, covar=condom, value=1);
%prev (var=prev_T3, sample=Cervical, covar=condom, value=1);
%prev (var=prev_T4, sample=Cervical, covar=condom, value=1);

%prev (var=prev_T1, sample=CorSul, covar=condom, value=1);
%prev (var=prev_T2, sample=CorSul, covar=condom, value=1);
%prev (var=prev_T3, sample=CorSul, covar=condom, value=1);
%prev (var=prev_T4, sample=CorSul, covar=condom, value=1);


*Species;
data prevalence_species;
	length taxa $30. pct_row 8. count 8. prev_T1 8. prev_T2 8. prev_T3 8. prev_T4 8. n_prev_T1 8. n_prev_T2 8. n_prev_T3 8. n_prev_T4 8.;
run;

proc freq data=species_long noprint;
table taxa / out=prev_temp;
run;

proc append base=prevalence_species data=prev_temp force; run;

data prevalence_species; set prevalence_species;
	if taxa in ('' 'std_qty' 'Age' 'BVStatusA' 'BVStatusE' 'Cyclephase' 'DayPostBln' 'Gender'
		'MaleEthnicity' 'NugentBV1' 'NugentBV1_Cat' 'NugentBV2' 'NugentBV2_Cat' 'NugentBV3' 'NugentBV3_Cat'
		'NugentBV4' 'NugentBV4_Cat' 'NugentSA' 'NugentSE' 'ORDER6' 'ORDER6c' 'ORDER6nc' 'ORDER7' 'ORDER7c'
		'ORDER7nc' 'ORDER8' 'ORDER8c' 'ORDER8nc' 'ORDER9' 'ORDER9c' 'ORDER9nc' 'SexParN' 'condom') 
	then delete;
run;

%macro prev (var= , sample=, covar=, value=);
proc freq data=species_long noprint;
title '&sample.';
table taxa * &var. / nocol nopercent  out=prev_temp outpct;
where  site = "&sample." and &covar.=&value.;
run;

data prev_temp; set prev_temp;
	if &var. = . then delete; else
	if &var. = 0 and PCT_ROW = 100 then PCT_ROW = 0; else
	if &var. = 0 then delete;

	keep taxa pct_row COUNT;
run;

data prevalence_species;
	merge prevalence_species (in=a) prev_temp;
	by taxa;
	if a;

	&var. = pct_row;
	n_&var. = count;
run;

data prev_sp_&sample._strata; set prevalence_species; run;
%mend;

*Nugent Scores;
%prev (var=prev_T1, sample=Cervical, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T2, sample=Cervical, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T3, sample=Cervical, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T4, sample=Cervical, covar=NugentBV1_Cat, value=2);

%prev (var=prev_T1, sample=CorSul, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T2, sample=CorSul, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T3, sample=CorSul, covar=NugentBV1_Cat, value=2);
%prev (var=prev_T4, sample=CorSul, covar=NugentBV1_Cat, value=2);

*Nugent Scores;
%prev (var=prev_T1, sample=Cervical, covar=cyclephase, value=1);
%prev (var=prev_T2, sample=Cervical, covar=cyclephase, value=1);
%prev (var=prev_T3, sample=Cervical, covar=cyclephase, value=1);
%prev (var=prev_T4, sample=Cervical, covar=cyclephase, value=1);

%prev (var=prev_T1, sample=CorSul, covar=cyclephase, value=1);
%prev (var=prev_T2, sample=CorSul, covar=cyclephase, value=1);
%prev (var=prev_T3, sample=CorSul, covar=cyclephase, value=1);
%prev (var=prev_T4, sample=CorSul, covar=cyclephase, value=1);

*Circumcision;
%prev (var=prev_T1, sample=Cervical, covar=circumcision, value=1);
%prev (var=prev_T2, sample=Cervical, covar=circumcision, value=1);
%prev (var=prev_T3, sample=Cervical, covar=circumcision, value=1);
%prev (var=prev_T4, sample=Cervical, covar=circumcision, value=1);

%prev (var=prev_T1, sample=CorSul, covar=circumcision, value=0);
%prev (var=prev_T2, sample=CorSul, covar=circumcision, value=0);
%prev (var=prev_T3, sample=CorSul, covar=circumcision, value=0);
%prev (var=prev_T4, sample=CorSul, covar=circumcision, value=0);

*Condom Use - No Condom;
%prev (var=prev_T1, sample=Cervical, covar=condom, value=0);
%prev (var=prev_T2, sample=Cervical, covar=condom, value=0);
%prev (var=prev_T3, sample=Cervical, covar=condom, value=0);
%prev (var=prev_T4, sample=Cervical, covar=condom, value=0);

%prev (var=prev_T1, sample=CorSul, covar=condom, value=0);
%prev (var=prev_T2, sample=CorSul, covar=condom, value=0);
%prev (var=prev_T3, sample=CorSul, covar=condom, value=0);
%prev (var=prev_T4, sample=CorSul, covar=condom, value=0);

*Condom Use - Condom used;
%prev (var=prev_T1, sample=Cervical, covar=condom, value=1);
%prev (var=prev_T2, sample=Cervical, covar=condom, value=1);
%prev (var=prev_T3, sample=Cervical, covar=condom, value=1);
%prev (var=prev_T4, sample=Cervical, covar=condom, value=1);

%prev (var=prev_T1, sample=CorSul, covar=condom, value=1);
%prev (var=prev_T2, sample=CorSul, covar=condom, value=1);
%prev (var=prev_T3, sample=CorSul, covar=condom, value=1);
%prev (var=prev_T4, sample=CorSul, covar=condom, value=1);


*Statistical tests;
*Circumcision;
%macro prev_test (var= );
proc freq data=secs_analytic_long;
title &var.;
table prev_T1 * circumcision / norow nopercent chisq;
where site = "CorSul" and  taxa=&var. 	/*and condom = 0*/;
format circumcision circumcision.;
run;
%mend;

%prev_test (var= "Dialister");
%prev_test (var= "Dialister_micraerophilus");
%prev_test (var= "Dialister_propionicifaciens");
%prev_test (var= "Dialister_succinatiphilus_0_8");
%prev_test (var= "Finegoldia_magna");
%prev_test (var= "Gardnerella_vaginalis");
%prev_test (var= "Hoylesella_timonensis");

%prev_test (var= "Mobiluncus");
%prev_test (var= "Peptostreptococcus_anaerobius");
%prev_test (var= "Prevotella");
%prev_test (var= "Prevotella_bivia");
%prev_test (var= "Prevotella_disiens");
%prev_test (var= "Prevotella_timonensis");

*Cervical;
*Cycle phase (run with macros below);
%macro prev_test (var= );
proc freq data=secs_analytic_long;
title &var.;
table prev_T1 * cyclephase / norow nopercent chisq;
where site = "Cervical" and  taxa=&var.;
run;
%mend;

*Race (run with macros below);
%macro prev_test (var= );
proc freq data=secs_analytic_long;
title &var.;
table prev_T1 * f_ethnicitycat / norow nopercent chisq;
where site = "Cervical" and  taxa=&var.;
run;
%mend;

*Nugent BV (run with macros below);
%macro prev_test (var= );
proc freq data=secs_analytic_long;
title &var.;
table prev_T1 * nugentbv1_cat / norow nopercent chisq;
where site = "Cervical" and  taxa=&var.;
run;
%mend;

%prev_test (var= "Corynebacterium");
%prev_test (var= "Dialister");
%prev_test (var= "Dialister_micraerophilus");
%prev_test (var= "Dialister_propionicifaciens");
%prev_test (var= "Dialister_succinatiphilus_0_8");
%prev_test (var= "Finegoldia");
%prev_test (var= "Gardnerella");
%prev_test (var= "Gardnerella_vaginalis");
%prev_test (var= "Lactobacillus");
%prev_test (var= "Lactobacillus_crispatus");
%prev_test (var= "Lactobacillus_crispatus_0_8");
%prev_test (var= "Lactobacillus_gasseri");
%prev_test (var= "Lactobacillus_iners");
%prev_test (var= "Lactobacillus_reuteri");
%prev_test (var= "Mobiluncus");
%prev_test (var= "Peptostreptococcus");
%prev_test (var= "Porphyromonas");
%prev_test (var= "Prevotella");
%prev_test (var= "Prevotella_bivia");
%prev_test (var= "Prevotella_disiens");
%prev_test (var= "Sneathia");

*Prev test;
*stratified by condom use;
%macro mcnemar (taxa= , site = , value=);
proc freq data=samples_long;
	title "McNemar's - &taxa. &site. condom=&value.";
	tables Prev_T1 * Prev_T2 / agree expected norow nocol nopercent; 
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;
proc freq data=samples_long;
	title "McNemar's - &taxa. &site. condom=&value.";
	tables Prev_T2 * Prev_T3 / agree expected norow nocol nopercent; 
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;
proc freq data=samples_long;
	title "McNemar's - &taxa. &site. condom=&value.";
	tables Prev_T3 * Prev_T4 / agree expected norow nocol nopercent; 
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;
proc freq data=samples_long;
	title "McNemar's - &taxa. &site. condom=&value.";
	tables Prev_T1 * Prev_T4 / agree expected norow nocol nopercent; 
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;
%mend;

%mcnemar (taxa=Bacillus, site=CorSul, value=0);
%mcnemar (taxa=Corynebacterium, site=CorSul, value=1);
%mcnemar (taxa=Dialister, site=CorSul, value=1);
%mcnemar (taxa=Finegoldia, site=CorSul, value=1);
%mcnemar (taxa=Gardnerella, site=CorSul, value=1);
%mcnemar (taxa=Lactobacillus, site=CorSul, value=0);
%mcnemar (taxa=Mobiluncus, site=CorSul, value=1);
%mcnemar (taxa=Negativicoccus, site=CorSul, value=1);
%mcnemar (taxa=Peptoniphilus, site=CorSul, value=1);
%mcnemar (taxa=Peptostreptococcus, site=CorSul, value=1);
%mcnemar (taxa=Porphyromonas, site=CorSul, value=1);
%mcnemar (taxa=Prevotella, site=CorSul, value=1);
%mcnemar (taxa=Staphylococcus, site=CorSul, value=1);

%mcnemar (taxa=Bacillus, site=Cervical, value=0);
%mcnemar (taxa=Corynebacterium, site=Cervical, value=1);
%mcnemar (taxa=Dialister, site=Cervical, value=1);
%mcnemar (taxa=Finegoldia, site=Cervical, value=1);
%mcnemar (taxa=Gardnerella, site=Cervical, value=1);
%mcnemar (taxa=Lactobacillus, site=Cervical, value=1);
%mcnemar (taxa=Mobiluncus, site=Cervical, value=1);
%mcnemar (taxa=Negativicoccus, site=Cervical, value=1);
%mcnemar (taxa=Peptoniphilus, site=Cervical, value=1);
%mcnemar (taxa=Peptostreptococcus, site=Cervical, value=1);
%mcnemar (taxa=Porphyromonas, site=Cervical, value=1);
%mcnemar (taxa=Prevotella, site=Cervical, value=1);
%mcnemar (taxa=Staphylococcus, site=Cervical, value=1);

*Mcnemars exact;
data McNemar_Exact;
input Tx Ty Count;
datalines;
0 0 4.5 
0 1 4.5
1 0 0.5
1 1 0.5
;
 
proc freq data=McNemar_Exact;
  tables Tx*Ty / nopercent norow nocol agree;
  weight Count;
  ods select CrossTabFreqs McNemarsTest;
run;

*Species;
%macro mcnemar (taxa= , site = , value=);
proc freq data=species_long;
	title "McNemar's - &taxa. &site. condom=&value.";
	tables Prev_T1 * Prev_T2 / agree expected norow nocol nopercent; 
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;
proc freq data=species_long;
	title "McNemar's - &taxa. &site. condom=&value.";
	tables Prev_T1 * Prev_T3 / agree expected norow nocol nopercent; 
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;
proc freq data=species_long;
	title "McNemar's - &taxa. &site. condom=&value.";
	tables Prev_T1 * Prev_T4 / agree expected norow nocol nopercent; 
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;
%mend;

%mcnemar (taxa=Dialister_micraerophilus, site=CorSul, value=0);
%mcnemar (taxa=Dialister_propionicifaciens, site=CorSul, value=0);
%mcnemar (taxa=Dialister_succinatiphilus_0_8, site=CorSul, value=0);
%mcnemar (taxa=Finegoldia_magna, site=CorSul, value=0);
%mcnemar (taxa=Gardnerella_vaginalis, site=CorSul, value=0);

%mcnemar (taxa=Lactobacillus_crispatus, site=CorSul, value=0);
%mcnemar (taxa=Lactobacillus_gasseri, site=CorSul, value=0);
%mcnemar (taxa=Lactobacillus_iners, site=CorSul, value=0);
%mcnemar (taxa=Lactobacillus_jensenii_0_8, site=CorSul, value=0);
%mcnemar (taxa=Lactobacillus_reuteri, site=CorSul, value=0);
%mcnemar (taxa=Mobiluncus_curtisii, site=CorSul, value=0);
%mcnemar (taxa=Negativicoccus_succinicivorans, site=CorSul, value=0);

%mcnemar (taxa=Peptoniphilus_asaccharolyticus_0, site=CorSul, value=0);
%mcnemar (taxa=Peptoniphilus_lacrimalis, site=CorSul, value=0);
%mcnemar (taxa=Peptostreptococcus_anaerobius, site=CorSul, value=0);
%mcnemar (taxa=Porphyromonas_asaccharolytica, site=CorSul, value=0);
%mcnemar (taxa=Prevotella_bivia, site=CorSul, value=0);
%mcnemar (taxa=Prevotella_buccalis, site=CorSul, value=0);
%mcnemar (taxa=Prevotella_corporis, site=CorSul, value=0);
%mcnemar (taxa=Prevotella_disiens, site=CorSul, value=0);
%mcnemar (taxa=Prevotella_timonensis, site=CorSul, value=0);
%mcnemar (taxa=Staphylococcus_aureus_0_8, site=CorSul, value=0);
%mcnemar (taxa=Staphylococcus_epidermidis, site=CorSul, value=0);

*Cerv;
%mcnemar (taxa=Dialister_micraerophilus, site=Cervical, value=0);
%mcnemar (taxa=Dialister_propionicifaciens, site=Cervical, value=0);
%mcnemar (taxa=Dialister_succinatiphilus_0_8, site=Cervical, value=0);
%mcnemar (taxa=Finegoldia_magna, site=Cervical, value=0);
%mcnemar (taxa=Gardnerella_vaginalis, site=Cervical, value=0);

%mcnemar (taxa=Lactobacillus_crispatus, site=Cervical, value=0);
%mcnemar (taxa=Lactobacillus_gasseri, site=Cervical, value=0);
%mcnemar (taxa=Lactobacillus_iners, site=Cervical, value=0);
%mcnemar (taxa=Lactobacillus_jensenii_0_8, site=Cervical, value=0);
%mcnemar (taxa=Lactobacillus_reuteri, site=Cervical, value=0);
%mcnemar (taxa=Mobiluncus_curtisii, site=Cervical, value=0);
%mcnemar (taxa=Negativicoccus_succinicivorans, site=Cervical, value=0);

%mcnemar (taxa=Peptoniphilus_asaccharolyticus_0, site=Cervical, value=0);
%mcnemar (taxa=Peptoniphilus_lacrimalis, site=Cervical, value=0);
%mcnemar (taxa=Peptostreptococcus_anaerobius, site=Cervical, value=0);
%mcnemar (taxa=Porphyromonas_asaccharolytica, site=Cervical, value=0);
%mcnemar (taxa=Prevotella_bivia, site=Cervical, value=0);
%mcnemar (taxa=Prevotella_buccalis, site=Cervical, value=0);
%mcnemar (taxa=Prevotella_corporis, site=Cervical, value=0);
%mcnemar (taxa=Prevotella_disiens, site=Cervical, value=0);
%mcnemar (taxa=Prevotella_timonensis, site=Cervical, value=0);
%mcnemar (taxa=Staphylococcus_aureus_0_8, site=Cervical, value=0);
%mcnemar (taxa=Staphylococcus_epidermidis, site=Cervical, value=0);

*Mcnemars exact;
data McNemar_Exact;
input Tx Ty Count;
datalines;
0 0 6.5 
0 1 22.5
1 0 0.5
1 1 0.5
;
 
proc freq data=McNemar_Exact;
  tables Tx*Ty / nopercent norow nocol agree;
  weight Count;
  ods select CrossTabFreqs McNemarsTest;
run;

*-;
*Significance testing;
*Species for condomless and circ status;
%macro mcnemar (taxa= , site = , value=);
proc freq data=species_long;
	title "McNemar's - &taxa. &site. condom=&value.";
	tables circumcision * Prev_T1 * Prev_T2 / agree  norow nocol nopercent; 
	where taxa = "&taxa." and site = "&site." and condom = &value.;
	format circumcision circumcision.;
run;
proc freq data=species_long;
	title "McNemar's - &taxa. &site. condom=&value.";
	tables circumcision * Prev_T1 * Prev_T3 / agree  norow nocol nopercent; 
	where taxa = "&taxa." and site = "&site." and condom = &value.;
	format circumcision circumcision.;
run;
proc freq data=species_long;
	title "McNemar's - &taxa. &site. condom=&value.";
	tables circumcision * Prev_T1 * Prev_T4 / agree  norow nocol nopercent; 
	where taxa = "&taxa." and site = "&site." and condom = &value.;
	format circumcision circumcision.;
run;
%mend;

%mcnemar (taxa=Dialister_micraerophilus, site=CorSul, value=0);
%mcnemar (taxa=Dialister_propionicifaciens, site=CorSul, value=0);
%mcnemar (taxa=Dialister_succinatiphilus_0_8, site=CorSul, value=0);
%mcnemar (taxa=Finegoldia_magna, site=CorSul, value=0);
%mcnemar (taxa=Gardnerella_vaginalis, site=CorSul, value=0);

%mcnemar (taxa=Lactobacillus_crispatus, site=CorSul, value=0);
%mcnemar (taxa=Lactobacillus_gasseri, site=CorSul, value=0);
%mcnemar (taxa=Lactobacillus_iners, site=CorSul, value=0);
%mcnemar (taxa=Lactobacillus_jensenii_0_8, site=CorSul, value=0);
%mcnemar (taxa=Lactobacillus_reuteri, site=CorSul, value=0);
%mcnemar (taxa=Mobiluncus_curtisii, site=CorSul, value=0);

%mcnemar (taxa=Peptoniphilus_asaccharolyticus_0, site=CorSul, value=0);
%mcnemar (taxa=Peptoniphilus_lacrimalis, site=CorSul, value=0);
%mcnemar (taxa=Peptostreptococcus_anaerobius, site=CorSul, value=0);
%mcnemar (taxa=Porphyromonas_asaccharolytica, site=CorSul, value=0);
%mcnemar (taxa=Prevotella_bivia, site=CorSul, value=0);
%mcnemar (taxa=Prevotella_buccalis, site=CorSul, value=0);
%mcnemar (taxa=Prevotella_corporis, site=CorSul, value=0);
%mcnemar (taxa=Prevotella_disiens, site=CorSul, value=0);
%mcnemar (taxa=Prevotella_timonensis, site=CorSul, value=0);
%mcnemar (taxa=Staphylococcus_aureus_0_8, site=CorSul, value=0);
%mcnemar (taxa=Staphylococcus_epidermidis, site=CorSul, value=0);

*Cerv;
%mcnemar (taxa=Dialister_micraerophilus, site=Cervical, value=0);
%mcnemar (taxa=Dialister_propionicifaciens, site=Cervical, value=0);
%mcnemar (taxa=Dialister_succinatiphilus_0_8, site=Cervical, value=0);
%mcnemar (taxa=Finegoldia_magna, site=Cervical, value=0);
%mcnemar (taxa=Gardnerella_vaginalis, site=Cervical, value=0);

%mcnemar (taxa=Lactobacillus_crispatus, site=Cervical, value=0);
%mcnemar (taxa=Lactobacillus_gasseri, site=Cervical, value=0);
%mcnemar (taxa=Lactobacillus_iners, site=Cervical, value=0);
%mcnemar (taxa=Lactobacillus_jensenii_0_8, site=Cervical, value=0);
%mcnemar (taxa=Lactobacillus_reuteri, site=Cervical, value=0);
%mcnemar (taxa=Mobiluncus_curtisii, site=Cervical, value=0);
%mcnemar (taxa=Negativicoccus_succinicivorans, site=Cervical, value=0);

%mcnemar (taxa=Peptoniphilus_asaccharolyticus_0, site=Cervical, value=0);
%mcnemar (taxa=Peptoniphilus_lacrimalis, site=Cervical, value=0);
%mcnemar (taxa=Peptostreptococcus_anaerobius, site=Cervical, value=0);
%mcnemar (taxa=Porphyromonas_asaccharolytica, site=Cervical, value=0);
%mcnemar (taxa=Prevotella_bivia, site=Cervical, value=0);
%mcnemar (taxa=Prevotella_buccalis, site=Cervical, value=0);
%mcnemar (taxa=Prevotella_corporis, site=Cervical, value=0);
%mcnemar (taxa=Prevotella_disiens, site=Cervical, value=0);
%mcnemar (taxa=Prevotella_timonensis, site=Cervical, value=0);
%mcnemar (taxa=Staphylococcus_aureus_0_8, site=Cervical, value=0);
%mcnemar (taxa=Staphylococcus_epidermidis, site=Cervical, value=0);

*----------------------;
*Relative Abdunance;
*----------------------;

*All taxa;
proc means data=samples_rel n mean q1 median q3 ;
title 'Overview of All Taxa - Relative Abundance by Time and Sample Type';
var &taxa_list;
class  site time;
run;

*BVAB/BASICs;
proc means data=secs_analytic n mean q1 median q3 ;
title 'Overview of All Taxa - Relative Abundance by Time and Sample Type';
var p_BASIC p_BVAB;
class  site time;
run;

proc means data=secs_analytic n mean q1 median q3 ;
title 'Overview of All Taxa - Relative Abundance by Time and Sample Type';
var p_BASIC p_BVAB;
class condom site time ;
run;

*--;
*Output rel ab changes;

proc means data=samples_rel_long n  q1 mean q3 maxdec=3;
title '';
	var T1 T2 T3 T4 T1_2 T2_3 T3_4 T1_4;
	class site;
	where taxa = 'Staphylococcus';
run;

data tab_genus_relab;
length Taxa $32 Site $8 T1_Mean 8 T2_Mean 8 T3_Mean 8 T4_Mean 8 T1_2_Mean 8 T2_3_Mean 8 T3_4_Mean 8T1_4_Mean 8 T1_2_StdDev 8 T2_3_StdDev 8 T3_4_StdDev 8 T1_4_StdDev 8;
run;

%macro relab (taxa= );
proc means data=samples_rel_long n  q1 mean q3 maxdec=3;
title '';
	var T1 T2 T3 T4 T1_2 T2_3 T3_4 T1_4;
	class site;
	output out=tab_genus_relab_temp(drop=_type_ _freq_) mean= std= /autoname;
	where taxa = &taxa. and site in ("Cervical" "CorSul");
run;

data tab_genus_relab_temp; set tab_genus_relab_temp;
taxa = &taxa.;
run;

proc append data=tab_genus_relab_temp base=tab_genus_relab force;
run;

%mend;

*Cervical;
%relab (taxa="Actinomyces"); %relab (taxa="Actinomycetales_Unclassified_Unc"); %relab (taxa="Anaerococcus"); %relab (taxa="Campylobacter");
%relab (taxa="Corynebacterium"); %relab (taxa="Dermabacter"); %relab (taxa="Dialister"); %relab (taxa="Ezakiella");
%relab (taxa="Finegoldia"); %relab (taxa="Gardnerella");  %relab (taxa="Lactobacillus"); %relab (taxa="Negativicoccus");
%relab (taxa="Peptoniphilus"); %relab (taxa="Porphyromonas"); %relab (taxa="Prevotella"); %relab (taxa="Propionibacterium");
%relab (taxa="Staphylococcus"); %relab (taxa="Streptococcus"); %relab (taxa="Veillonella");

*Coronal Sulcus;
%relab (taxa="Anaerococcus"); %relab (taxa="Atopobium"); %relab (taxa="Bacilli_Unclassified_Unclassifie"); %relab (taxa="Clostridiales_Unclassified_Uncla");
%relab (taxa="Corynebacterium"); %relab (taxa="Dialister"); %relab (taxa="Enterorhabdus_0_8"); %relab (taxa="Finegoldia");
%relab (taxa="Firmicutes_Unclassified_Unclassi"); %relab (taxa="Gardnerella"); %relab (taxa="Gemella"); %relab (taxa="Lactobacillales_Unclassified_Unc");
%relab (taxa="Lactobacillus"); %relab (taxa="Peptoniphilus"); %relab (taxa="Peptostreptococcus"); %relab (taxa="Prevotella");
%relab (taxa="Staphylococcus"); %relab (taxa="Streptococcus"); %relab (taxa="Veillonella");

data tab_genus_relab; set tab_genus_relab;
if site= '' then delete;
run;


*-;
*stratified by condom use;

data tab_genus_relab;
length Taxa $32 Site $8 T1_Mean 8 T2_Mean 8 T3_Mean 8 T4_Mean 8 T1_2_Mean 8 T2_3_Mean 8 T3_4_Mean 8T1_4_Mean 8 T1_2_StdDev 8 T2_3_StdDev 8 T3_4_StdDev 8 T1_4_StdDev 8;
run;

%macro relab (taxa= );
proc means data=samples_rel_long n  q1 mean q3 maxdec=3;
title '';
	var T1 T2 T3 T4 T1_2 T2_3 T3_4 T1_4;
	class site;
	output out=tab_genus_relab_temp(drop=_type_ _freq_) mean= std= /autoname;
	where taxa = &taxa. and site in ("Cervical" "CorSul") and condom=1;
run;

data tab_genus_relab_temp; set tab_genus_relab_temp;
taxa = &taxa.;
run;

proc append data=tab_genus_relab_temp base=tab_genus_relab force;
run;

%mend;

*Cervical;

   *no condom;
%relab (taxa="Actinomyces"); %relab (taxa="Actinomycetales_Unclassified_Unc"); %relab (taxa="Aerococcus"); %relab (taxa="Anaerococcus"); %relab (taxa="Atopobium"); 
%relab (taxa="Bacilli_Unclassified_Unclassifie"); %relab (taxa="Campylobacter"); %relab (taxa="Clostridiales_Unclassified_Uncla"); %relab (taxa="Clostridium_sensu_stricto"); 
%relab (taxa="Corynebacterium"); %relab (taxa="Dialister"); %relab (taxa="Enterococcus"); %relab (taxa="Enterorhabdus_0_8"); %relab (taxa="Escherichia_Shigella"); 
%relab (taxa="Ezakiella"); %relab (taxa="Finegoldia"); %relab (taxa="Firmicutes_Unclassified_Unclassi"); %relab (taxa="Gardnerella"); %relab (taxa="Gemella"); 
%relab (taxa="Haemophilus"); %relab (taxa="Lactobacillales_Unclassified_Unc"); %relab (taxa="Lactobacillus"); %relab (taxa="Megasphaera"); %relab (taxa="Neisseria"); 
%relab (taxa="Parvimonas"); %relab (taxa="Peptoniphilus"); %relab (taxa="Peptostreptococcus"); %relab (taxa="Porphyromonas"); %relab (taxa="Prevotella"); 
%relab (taxa="Staphylococcus"); %relab (taxa="Streptococcus"); %relab (taxa="Veillonella");  

	*condom used;
%relab (taxa="Acinetobacter"); %relab (taxa="Actinomyces"); %relab (taxa="Aerococcus"); %relab (taxa="Anaerococcus"); %relab (taxa="Anaeroglobus"); %relab (taxa="Atopobium"); 
%relab (taxa="Bacilli_Unclassified_Unclassifie"); %relab (taxa="Bifidobacterium"); %relab (taxa="Brevibacterium"); %relab (taxa="Campylobacter"); 
%relab (taxa="Clostridium_sensu_stricto"); %relab (taxa="Corynebacterium"); %relab (taxa="Dialister"); %relab (taxa="Dysgonomonas"); %relab (taxa="Enterococcus"); 
%relab (taxa="Eremococcus"); %relab (taxa="Escherichia_Shigella"); %relab (taxa="Finegoldia"); %relab (taxa="Firmicutes_Unclassified_Unclassi"); %relab (taxa="Fusobacterium"); 
%relab (taxa="Gardnerella"); %relab (taxa="Gemella"); %relab (taxa="Granulicatella"); %relab (taxa="Haemophilus"); %relab (taxa="Haemophilus_0_8"); %relab (taxa="Howardella"); 
%relab (taxa="Lactobacillales_Unclassified_Unc"); %relab (taxa="Lactobacillus"); %relab (taxa="Neisseria"); %relab (taxa="Pediococcus"); %relab (taxa="Peptoniphilus"); 
%relab (taxa="Peptostreptococcus"); %relab (taxa="Porphyromonas"); %relab (taxa="Prevotella"); %relab (taxa="Propionibacterium"); %relab (taxa="Providencia"); 
%relab (taxa="Rothia"); %relab (taxa="Staphylococcus"); %relab (taxa="Streptococcus"); %relab (taxa="Veillonella"); 

*Coronal Sulcus;

   *no condom;
%relab (taxa="Acinetobacter"); %relab (taxa="Actinomyces"); %relab (taxa="Actinomycetales_Unclassified_Unc"); %relab (taxa="Actinotignum"); %relab (taxa="Aerococcus"); 
%relab (taxa="Anaerococcus"); %relab (taxa="Anaeroglobus"); %relab (taxa="Arcanobacterium"); %relab (taxa="Atopobium"); %relab (taxa="Bacilli_Unclassified_Unclassifie"); 
%relab (taxa="Bifidobacterium"); %relab (taxa="Brevibacterium"); %relab (taxa="Campylobacter"); %relab (taxa="Citrobacter_0_8"); %relab (taxa="Clostridiales_Unclassified_Uncla"); 
%relab (taxa="Clostridium_sensu_stricto"); %relab (taxa="Corynebacterium"); %relab (taxa="Dermabacter"); %relab (taxa="Dermabacter_0_8"); %relab (taxa="Dialister"); 
%relab (taxa="Dysgonomonas"); %relab (taxa="Enhydrobacter"); %relab (taxa="Enterococcus"); %relab (taxa="Eremococcus"); %relab (taxa="Escherichia_Shigella"); 
%relab (taxa="Ezakiella"); %relab (taxa="Facklamia"); %relab (taxa="Finegoldia"); %relab (taxa="Firmicutes_Unclassified_Unclas"); %relab (taxa="Fusobacterium"); 
%relab (taxa="Gardnerella"); %relab (taxa="Gemella"); %relab (taxa="Granulicatella"); %relab (taxa="Haemophilus"); %relab (taxa="Howardella"); %relab (taxa="Kocuria"); 
%relab (taxa="Lactobacillales_Unclassified_U"); %relab (taxa="Lactobacillus"); %relab (taxa="Megasphaera"); %relab (taxa="Micrococcus"); %relab (taxa="Mobiluncus"); 
%relab (taxa="Morganella"); %relab (taxa="Murdochiella"); %relab (taxa="Negativicoccus"); %relab (taxa="Neisseria"); %relab (taxa="Olsenella"); %relab (taxa="Parvibacter_0_8"); 
%relab (taxa="Parvimonas"); %relab (taxa="Peptococcus"); %relab (taxa="Peptoniphilus"); %relab (taxa="Peptostreptococcus"); %relab (taxa="Porphyromonas"); 
%relab (taxa="Prevotella"); %relab (taxa="Propionibacterium"); %relab (taxa="Providencia"); %relab (taxa="Pseudomonas"); %relab (taxa="Rothia"); 
%relab (taxa="Saccharibacteria_genera_incertia"); %relab (taxa="Saccharofermentans_0_8"); %relab (taxa="Sphingomonas"); %relab (taxa="Staphylococcus"); 
%relab (taxa="Streptococcus"); %relab (taxa="Streptophyta"); %relab (taxa="Tannerella_0_8"); %relab (taxa="Varibaculum"); %relab (taxa="Veillonella");

	*condom used;
%relab (taxa="Acinetobacter"); %relab (taxa="Actinomyces"); %relab (taxa="Actinomycetales_Unclassified_Unc"); %relab (taxa="Actinotignum"); %relab (taxa="Aerococcus"); 
%relab (taxa="Alloprevotella"); %relab (taxa="Anaerococcus"); %relab (taxa="Anaeroglobus"); %relab (taxa="Atopobium"); %relab (taxa="Bacilli_Unclassified_Unclassifie"); 
%relab (taxa="Brachybacterium"); %relab (taxa="Brevibacterium"); %relab (taxa="Campylobacter"); %relab (taxa="Clostridiales_Unclassified_Uncla"); 
%relab (taxa="Clostridium_sensu_stricto"); %relab (taxa="Corynebacterium"); %relab (taxa="Dermabacter"); %relab (taxa="Dermabacter_0_8"); %relab (taxa="Dermacoccus"); 
%relab (taxa="Dialister"); %relab (taxa="Enhydrobacter"); %relab (taxa="Enterococcus"); %relab (taxa="Eremococcus"); %relab (taxa="Escherichia_Shigella"); 
%relab (taxa="Ezakiella"); %relab (taxa="Finegoldia"); %relab (taxa="Firmicutes_Unclassified_Unclassi"); %relab (taxa="Fusobacterium"); %relab (taxa="Gardnerella"); 
%relab (taxa="Gemella"); %relab (taxa="Granulicatella"); %relab (taxa="Haemophilus"); %relab (taxa="Haemophilus_0_8"); %relab (taxa="Howardella"); %relab (taxa="Kocuria"); 
%relab (taxa="Kytococcus"); %relab (taxa="Lachnoanaerobaculum"); %relab (taxa="Lactobacillales_Unclassified_Unc"); %relab (taxa="Lactobacillus"); %relab (taxa="Micrococcus"); 
%relab (taxa="Mobiluncus"); %relab (taxa="Morganella"); %relab (taxa="Murdochiella"); %relab (taxa="Negativicoccus"); %relab (taxa="Neisseria"); %relab (taxa="Parvibacter_0_8"); 
%relab (taxa="Peptococcus"); %relab (taxa="Peptoniphilus"); %relab (taxa="Peptostreptococcus"); %relab (taxa="Porphyromonas"); %relab (taxa="Prevotella"); 
%relab (taxa="Propionibacterium"); %relab (taxa="Propionimicrobium"); %relab (taxa="Providencia"); %relab (taxa="Pseudomonas"); %relab (taxa="Roseburia"); %relab (taxa="Rothia"); 
%relab (taxa="Saccharibacteria_genera_incertia"); %relab (taxa="Staphylococcus"); %relab (taxa="Streptococcus"); %relab (taxa="Streptophyta"); %relab (taxa="Veillonella"); 

*--;
*Species rel ab;
proc means data=species_rel n mean q1 median q3 ;
title 'Overview of All Taxa - Relative Abundance by Time and Sample Type';
var &species_list;
class  site time;
run;


data tab_sp_relab;
length Taxa $32 Site $8 T1_Mean 8 T2_Mean 8 T3_Mean 8 T4_Mean 8 T1_2_Mean 8 T2_3_Mean 8 T3_4_Mean 8T1_4_Mean 8 T1_2_StdDev 8 T2_3_StdDev 8 T3_4_StdDev 8 T1_4_StdDev 8;
run;

%macro relab (taxa= );
proc means data=species_rel_long n  q1 mean q3 maxdec=3;
title '';
	var T1 T2 T3 T4 T1_2 T2_3 T3_4 T1_4;
	class site;
	output out=tab_sp_relab_temp(drop=_type_ _freq_) mean= std= /autoname;
	where taxa = &taxa. and site in ("Cervical" "CorSul");
run;

data tab_sp_relab_temp; set tab_sp_relab_temp;
taxa = &taxa.;
run;

proc append data=tab_sp_relab_temp base=tab_sp_relab force;
run;
%mend;

*Taxa;
%relab (taxa="Acinetobacter_baumannii");  %relab (taxa="Dialister_micraerophilus");  %relab (taxa="Dialister_propionicifaciens");  
%relab (taxa="Dialister_succinatiphilus_0_8");  %relab (taxa="Finegoldia_magna");  %relab (taxa="Gardnerella_vaginalis");  
%relab (taxa="Lactobacillus_crispatus");  %relab (taxa="Lactobacillus_crispatus_0_8");  %relab (taxa="Lactobacillus_crispatus_DSM_20");  
%relab (taxa="Lactobacillus_crispatus_S1");  %relab (taxa="Lactobacillus_crispatus_S1_0_8");  %relab (taxa="Lactobacillus_gasseri");  
%relab (taxa="Lactobacillus_iners");  %relab (taxa="Lactobacillus_reuteri");  %relab (taxa="Mobiluncus_curtisii");  
%relab (taxa="Negativicoccus_succinicivorans");  %relab (taxa="Peptoniphilus_asaccharolyticus_0");  %relab (taxa="Peptoniphilus_lacrimalis");  
%relab (taxa="Peptoniphilus_timonensis_JC401");  %relab (taxa="Peptostreptococcus_anaerobius");  %relab (taxa="Porphyromonas_asaccharolytica");  
%relab (taxa="Prevotella_bivia");  %relab (taxa="Prevotella_buccalis");  %relab (taxa="Prevotella_corporis");  
%relab (taxa="Prevotella_disiens");  %relab (taxa="Sneathia_sp_Sn35");

 %relab (taxa="Hoylesella_timonensis");  %relab (taxa="Staphylococcus_epidermidis");


proc means data=species_rel_long n  q1 mean q3 maxdec=3;
title '';
	var T1 T2 T3 T4 T1_2 T2_3 T3_4 T1_4;
	class site;
	output out=tab_sp_relab_temp(drop=_type_ _freq_) mean= std= /autoname;
	where taxa = "Gardnerella_vaginalis" and site = "CorSul" and condom = 0;
run;

proc univariate data=species_rel_long ;
var T1_2;
	where taxa = "Gardnerella_vaginalis" and site = "CorSul" and condom = 0;
run;

*-;
*Condom use;
data tab_sp_relab;
length Taxa $32 Site $8 T1_Mean 8 T2_Mean 8 T3_Mean 8 T4_Mean 8 T1_2_Mean 8 T2_3_Mean 8 T3_4_Mean 8T1_4_Mean 8 T1_2_StdDev 8 T2_3_StdDev 8 T3_4_StdDev 8 T1_4_StdDev 8;
run;

%macro relab (taxa= );
proc means data=species_rel_long n  q1 mean q3 maxdec=3;
title '';
	var T1 T2 T3 T4 T1_2 T2_3 T3_4 T1_4;
	class site;
	output out=tab_sp_relab_temp(drop=_type_ _freq_) mean= std= /autoname;
	where taxa = &taxa. and site in ("Cervical" "CorSul") and condom = 0;
run;

data tab_sp_relab_temp; set tab_sp_relab_temp;
taxa = &taxa.;
run;

proc append data=tab_sp_relab_temp base=tab_sp_relab force;
run;
%mend;

*Taxa - cor sul - no condom;
%relab (taxa="Actinomyces_neuii"); %relab (taxa="Actinomyces_radingae"); %relab (taxa="Actinomyces_turicensis"); %relab (taxa="Actinomycetales_Unclassified_Unc"); 
%relab (taxa="Anaerococcus_hydrogenalis"); %relab (taxa="Anaerococcus_lactolyticus"); %relab (taxa="Anaerococcus_obesiensis_ph10_0_8"); 
%relab (taxa="Anaerococcus_octavius_0_8"); %relab (taxa="Anaerococcus_prevotii_DSM_20548"); %relab (taxa="Anaerococcus_prevotii_DSM_20548_"); 
%relab (taxa="Anaerococcus_senegalensis_JC48_0"); %relab (taxa="Anaerococcus_sp_S9_PR_5_0_8"); %relab (taxa="Anaeroglobus_geminatus"); 
%relab (taxa="Arcanobacterium_phocae"); %relab (taxa="Brevibacterium_paucivorans_0_8"); %relab (taxa="C_glucuronolyticum_0_8"); %relab (taxa="Campylobacter_hominis"); 
%relab (taxa="Candidatus_Peptoniphilus_massile"); %relab (taxa="Clostridiales_Unclassified_Uncla"); %relab (taxa="Clostridium_carboxidivorans_0_8"); 
%relab (taxa="Coriobacteriaceae_Unclassified_U"); %relab (taxa="Corynebacterium_afermentans_0_8"); %relab (taxa="Corynebacterium_amycolatum_0_8"); 
%relab (taxa="Corynebacterium_appendicis"); %relab (taxa="Corynebacterium_appendicis_0_8"); %relab (taxa="Corynebacterium_argentoratense_0"); 
%relab (taxa="Corynebacterium_aurimucosum"); %relab (taxa="Corynebacterium_imitans"); %relab (taxa="Corynebacterium_kroppenstedtii"); 
%relab (taxa="Corynebacterium_pilbarense_0_8"); %relab (taxa="Corynebacterium_pyruviciproducen"); %relab (taxa="Corynebacterium_simulans_0_8"); 
%relab (taxa="Corynebacterium_singulare_0_8"); %relab (taxa="Corynebacterium_thomssenii"); %relab (taxa="Corynebacterium_tuberculostearic"); 
%relab (taxa="Corynebacterium_ureicelerivorans"); %relab (taxa="Dermabacter_hominis"); %relab (taxa="Dialister_micraerophilus"); %relab (taxa="Dialister_propionicifaciens"); 
%relab (taxa="Dialister_succinatiphilus_0_8"); %relab (taxa="Dysgonomonas_gadei"); %relab (taxa="Dysgonomonas_mossii_0_8"); %relab (taxa="Enterobacteriaceae_Unclassified_"); 
%relab (taxa="Enterococcus_faecalis"); %relab (taxa="Eremococcus_coleocola"); %relab (taxa="Escherichia_Shigella_fergusonii_"); %relab (taxa="Facklamia_hominis"); 
%relab (taxa="Finegoldia_magna"); %relab (taxa="Firmicutes_Unclassified_Unclassi"); %relab (taxa="Gardnerella_vaginalis"); %relab (taxa="Gemella_haemolysans"); 
%relab (taxa="Gemella_sanguinis"); %relab (taxa="Haemophilus_parainfluenzae"); %relab (taxa="Howardella_ureilytica"); %relab (taxa="Kocuria_salsicia_0_8"); 
%relab (taxa="Lachnospiraceae_Unclassified_Unc"); %relab (taxa="Lactobacillus_crispatus"); %relab (taxa="Lactobacillus_fornicalis_0_8"); %relab (taxa="Lactobacillus_gasseri"); 
%relab (taxa="Lactobacillus_iners"); %relab (taxa="Lactobacillus_jensenii_0_8"); %relab (taxa="Lactobacillus_reuteri"); %relab (taxa="Megasphaera_micronuciformis"); 
%relab (taxa="Micrococcus_aloeverae_0_8"); %relab (taxa="Mobiluncus_curtisii"); %relab (taxa="Moraxellaceae_Unclassified_Uncla"); %relab (taxa="Morganella_morganii"); 
%relab (taxa="Murdochiella_sp_S5_A16_0_8"); %relab (taxa="Negativicoccus_succinicivorans"); %relab (taxa="Neisseria_perflava"); %relab (taxa="Peptococcus_niger"); 
%relab (taxa="Peptoniphilus_asaccharolyticus_0"); %relab (taxa="Peptoniphilus_grossensis_ph5_0_8"); %relab (taxa="Peptoniphilus_harei_0_8"); %relab (taxa="Peptoniphilus_lacrimalis"); 
%relab (taxa="Peptoniphilus_sp_7_2_0_8"); %relab (taxa="Peptoniphilus_sp_BV3AC2_0_8"); %relab (taxa="Peptoniphilus_sp_S5_A2_0_8"); %relab (taxa="Peptoniphilus_sp_S9_PR_13_0_8"); 
%relab (taxa="Peptostreptococcus_anaerobius"); %relab (taxa="Peptostreptococcus_stomatis"); %relab (taxa="Porphyromonadaceae_Unclassified_"); 
%relab (taxa="Porphyromonas_asaccharolytica"); %relab (taxa="Porphyromonas_asaccharolytica_0_"); %relab (taxa="Porphyromonas_bennonis"); 
%relab (taxa="Porphyromonas_circumdentaria_0_8"); %relab (taxa="Prevotella_bergensis"); %relab (taxa="Prevotella_bivia"); %relab (taxa="Prevotella_buccalis"); 
%relab (taxa="Prevotella_corporis"); %relab (taxa="Prevotella_disiens"); %relab (taxa="Prevotella_melaninogenica"); %relab (taxa="Prevotella_pallens"); 
%relab (taxa="Prevotella_timonensis"); %relab (taxa="Propionibacterium_acnes"); %relab (taxa="Providencia_rustigianii"); %relab (taxa="Pseudomonas_guariconensis_0_8"); 
%relab (taxa="Rothia_mucilaginosa"); %relab (taxa="Ruminococcaceae_Unclassified_Unc"); %relab (taxa="S000414273_Campylobacter"); %relab (taxa="Staphylococcus_aureus_0_8"); 
%relab (taxa="Staphylococcus_epidermidis"); %relab (taxa="Staphylococcus_epidermidis_0_8"); %relab (taxa="Staphylococcus_epidermidis_RP62A"); 
%relab (taxa="Staphylococcus_hominis_0_8"); %relab (taxa="Streptococcus_agalactiae"); %relab (taxa="Streptococcus_anginosus"); %relab (taxa="Streptococcus_mitis_0_8"); 
%relab (taxa="Streptococcus_oligofermentans_0_"); %relab (taxa="Streptococcus_salivarius"); %relab (taxa="TM7_phylum_sp_oral_clone_DR034"); %relab (taxa="Varibaculum_cambriense"); 
%relab (taxa="Veillonella_atypica_0_8"); %relab (taxa="Veillonella_dispar"); %relab (taxa="Veillonella_montpellierensis"); %relab (taxa="uncultured_Anaerococcus_sp"); 
%relab (taxa="uncultured_Anaerococcus_sp_0_8"); %relab (taxa="uncultured_Olsenella_sp_0_8"); %relab (taxa="uncultured_Prevotella_sp_0_8"); 
%relab (taxa="uncultured_bacterium_Atopobium"); %relab (taxa="uncultured_bacterium_Ezakiella"); %relab (taxa="uncultured_bacterium_Parvimonas"); 
%relab (taxa="uncultured_organism_Atopobium"); %relab (taxa="uncultured_organism_Granulicatel");

*Cervical Secretions - no condom;
%relab (taxa="Actinomycetales_Unclassified_Unc"); %relab (taxa="Aerococcus_christensenii"); %relab (taxa="Anaerococcus_prevotii_DSM_20548"); 
%relab (taxa="Clostridiales_Unclassified_Uncla"); %relab (taxa="Coriobacteriaceae_Unclassified_U"); %relab (taxa="Corynebacterium_tuberculostearic"); 
%relab (taxa="Dialister_micraerophilus"); %relab (taxa="Dialister_propionicifaciens"); %relab (taxa="Dialister_succinatiphilus_0_8"); 
%relab (taxa="Escherichia_Shigella_fergusonii_"); %relab (taxa="Finegoldia_magna"); %relab (taxa="Firmicutes_Unclassified_Unclassi"); %relab (taxa="Gardnerella_vaginalis"); 
%relab (taxa="Gemella_haemolysans"); %relab (taxa="Haemophilus_parainfluenzae"); %relab (taxa="Lactobacillales_Unclassified_Unc"); %relab (taxa="Lactobacillus_acidophilus_0_8"); 
%relab (taxa="Lactobacillus_crispatus"); %relab (taxa="Lactobacillus_fornicalis_0_8"); %relab (taxa="Lactobacillus_gasseri"); %relab (taxa="Lactobacillus_iners"); 
%relab (taxa="Lactobacillus_jensenii_0_8"); %relab (taxa="Lactobacillus_reuteri"); %relab (taxa="Megasphaera_indica_0_8"); %relab (taxa="Neisseria_perflava"); 
%relab (taxa="Peptoniphilus_grossensis_ph5_0_8"); %relab (taxa="Peptoniphilus_lacrimalis"); %relab (taxa="Peptoniphilus_sp_BV3AC2_0_8"); 
%relab (taxa="Peptoniphilus_sp_S9_PR_13_0_8"); %relab (taxa="Peptostreptococcus_anaerobius"); %relab (taxa="Prevotella_bivia"); %relab (taxa="Prevotella_buccalis"); 
%relab (taxa="Prevotella_disiens"); %relab (taxa="Prevotella_timonensis"); %relab (taxa="S000414273_Campylobacter"); %relab (taxa="Staphylococcus_epidermidis"); 
%relab (taxa="Staphylococcus_epidermidis_0_8"); %relab (taxa="Streptococcus_agalactiae"); %relab (taxa="Streptococcus_anginosus"); %relab (taxa="Streptococcus_mitis_0_8"); 
%relab (taxa="Streptococcus_salivarius"); %relab (taxa="Veillonella_montpellierensis"); %relab (taxa="issierellia_bacterium_KA00581"); %relab (taxa="uncultured_Anaerococcus_sp"); 
%relab (taxa="uncultured_Prevotella_sp_0_8"); %relab (taxa="uncultured_bacterium_Atopobium"); %relab (taxa="uncultured_bacterium_Ezakiella");

*Cor Sul, condom;
%relab (taxa="Acinetobacter_guillouiae_0_8"); %relab (taxa="Actinomyces_neuii"); %relab (taxa="Actinomyces_odontolyticus"); %relab (taxa="Actinomyces_radingae"); 
%relab (taxa="Actinomycetales_Unclassified_Unc"); %relab (taxa="Actinotignum_sanguinis"); %relab (taxa="Anaerococcus_octavius_0_8"); 
%relab (taxa="Anaerococcus_prevotii_DSM_20548"); %relab (taxa="Anaerococcus_prevotii_DSM_20548_"); %relab (taxa="Anaerococcus_senegalensis_JC48_0"); 
%relab (taxa="Anaeroglobus_geminatus"); %relab (taxa="Bacteroidales_Unclassified_Uncla"); %relab (taxa="C_glucuronolyticum_0_8"); %relab (taxa="Candidatus_Peptoniphilus_massile"); 
%relab (taxa="Clostridiales_Unclassified_Uncla"); %relab (taxa="Coriobacteriaceae_Unclassified_U"); %relab (taxa="Corynebacterium_afermentans_0_8"); 
%relab (taxa="Corynebacterium_appendicis"); %relab (taxa="Corynebacterium_argentoratense_0"); %relab (taxa="Corynebacterium_imitans"); %relab (taxa="Corynebacterium_pilbarense_0_8"); 
%relab (taxa="Corynebacterium_pyruviciproducen"); %relab (taxa="Corynebacterium_singulare_0_8"); %relab (taxa="Corynebacterium_thomssenii"); 
%relab (taxa="Corynebacterium_tuberculostearic"); %relab (taxa="Dermabacter_hominis"); %relab (taxa="Dialister_micraerophilus"); %relab (taxa="Dialister_propionicifaciens"); 
%relab (taxa="Dialister_succinatiphilus_0_8"); %relab (taxa="Enterobacteriaceae_Unclassified_"); %relab (taxa="Enterococcus_faecalis"); %relab (taxa="Eremococcus_coleocola"); 
%relab (taxa="Escherichia_Shigella_fergusonii_"); %relab (taxa="Finegoldia_magna"); %relab (taxa="Fusobacterium_periodonticum"); %relab (taxa="Gardnerella_vaginalis");  %relab (taxa="Gemella_haemolysans"); 
%relab (taxa="Gemella_sanguinis"); %relab (taxa="Haemophilus_parainfluenzae"); %relab (taxa="Haemophilus_pittmaniae"); %relab (taxa="Howardella_ureilytica"); 
%relab (taxa="Kocuria_salsicia_0_8"); %relab (taxa="Lachnospiraceae_Unclassified_Unc"); %relab (taxa="Lactobacillus_coleohominis"); %relab (taxa="Lactobacillus_crispatus"); 
%relab (taxa="Lactobacillus_gasseri"); %relab (taxa="Lactobacillus_iners"); %relab (taxa="Lactobacillus_jensenii_0_8"); %relab (taxa="Lactobacillus_reuteri"); 
%relab (taxa="Micrococcus_endophyticus_0_8"); %relab (taxa="Mobiluncus_curtisii"); %relab (taxa="Moraxellaceae_Unclassified_Uncla"); %relab (taxa="Morganella_morganii"); 
%relab (taxa="Murdochiella_sp_S5_A16_0_8"); %relab (taxa="Negativicoccus_succinicivorans"); %relab (taxa="Peptococcus_niger"); %relab (taxa="Peptoniphilus_asaccharolyticus_0"); 
%relab (taxa="Peptoniphilus_grossensis_ph5_0_8"); %relab (taxa="Peptoniphilus_harei_0_8"); %relab (taxa="Peptoniphilus_lacrimalis"); %relab (taxa="Peptoniphilus_sp_7_2_0_8"); 
%relab (taxa="Peptoniphilus_sp_BV3AC2_0_8"); %relab (taxa="Peptoniphilus_sp_S5_A2_0_8"); %relab (taxa="Peptoniphilus_sp_S9_PR_13_0_8"); %relab (taxa="Peptostreptococcus_anaerobius"); 
%relab (taxa="Porphyromonas_asaccharolytica_0_"); %relab (taxa="Porphyromonas_bennonis"); %relab (taxa="Porphyromonas_pasteri_0_8"); %relab (taxa="Prevotella_bergensis"); 
%relab (taxa="Prevotella_bivia"); %relab (taxa="Prevotella_buccalis"); %relab (taxa="Prevotella_disiens"); %relab (taxa="Prevotella_melaninogenica"); 
%relab (taxa="Prevotella_timonensis"); %relab (taxa="Propionibacterium_acnes"); %relab (taxa="Propionimicrobium_lymphophilum"); %relab (taxa="Providencia_rustigianii"); 
%relab (taxa="Rothia_dentocariosa"); %relab (taxa="Rothia_mucilaginosa"); %relab (taxa="S000414273_Campylobacter"); %relab (taxa="Staphylococcus_aureus_0_8"); 
%relab (taxa="Staphylococcus_epidermidis"); %relab (taxa="Staphylococcus_epidermidis_0_8"); %relab (taxa="Staphylococcus_epidermidis_RP62A"); %relab (taxa="Streptococcus_agalactiae"); 
%relab (taxa="Streptococcus_mitis_0_8"); %relab (taxa="Streptococcus_salivarius"); %relab (taxa="Streptococcus_sinensis_0_8"); %relab (taxa="Veillonella_atypica_0_8"); 
%relab (taxa="Veillonella_dispar"); %relab (taxa="Veillonellaceae_Unclassified_Unc"); %relab (taxa="uncultured_Anaerococcus_sp"); %relab (taxa="uncultured_Anaerococcus_sp_0_8"); 
%relab (taxa="uncultured_Prevotella_sp_0_8"); %relab (taxa="uncultured_bacterium_Atopobium"); %relab (taxa="uncultured_bacterium_Ezakiella"); 
%relab (taxa="uncultured_organism_Granulicatel");

*Cervical, condom;
%relab (taxa="Acinetobacter_bereziniae_0_8"); %relab (taxa="Actinomyces_neuii"); %relab (taxa="Aerococcus_christensenii"); %relab (taxa="Anaerococcus_octavius_0_8"); 
%relab (taxa="Anaerococcus_prevotii_DSM_20548"); %relab (taxa="Anaeroglobus_geminatus"); %relab (taxa="Atopobium_sp_S7MSR3"); %relab (taxa="Brevibacterium_massiliense_0_8"); 
%relab (taxa="Candidatus_Peptoniphilus_massile"); %relab (taxa="Clostridium_colicanis"); %relab (taxa="Corynebacterium_afermentans_0_8"); %relab (taxa="Corynebacterium_aurimucosum"); 
%relab (taxa="Corynebacterium_aurimucosum_0_8"); %relab (taxa="Corynebacterium_coyleae_0_8"); %relab (taxa="Corynebacterium_imitans"); %relab (taxa="Corynebacterium_pilbarense_0_8"); 
%relab (taxa="Corynebacterium_singulare_0_8"); %relab (taxa="Corynebacterium_sundsvallense_0_"); %relab (taxa="Corynebacterium_tuberculostearic"); 
%relab (taxa="Corynebacterium_tuscaniense"); %relab (taxa="Dialister_micraerophilus"); %relab (taxa="Dialister_propionicifaciens"); %relab (taxa="Dialister_succinatiphilus_0_8"); 
%relab (taxa="Dysgonomonas_oryzarvi_0_8"); %relab (taxa="Enterococcus_faecalis"); %relab (taxa="Eremococcus_coleocola"); %relab (taxa="Escherichia_Shigella_fergusonii_"); 
%relab (taxa="Finegoldia_magna"); %relab (taxa="Firmicutes_Unclassified_Unclassi"); %relab (taxa="Fusobacterium_periodonticum"); %relab (taxa="Gardnerella_vaginalis"); 
%relab (taxa="Gemella_haemolysans"); %relab (taxa="Gemella_sanguinis"); %relab (taxa="Haemophilus_parainfluenzae"); %relab (taxa="Howardella_ureilytica"); 
%relab (taxa="Lactobacillales_Unclassified_Unc"); %relab (taxa="Lactobacillus_acidophilus_0_8"); %relab (taxa="Lactobacillus_coleohominis"); %relab (taxa="Lactobacillus_crispatus"); 
%relab (taxa="Lactobacillus_fornicalis_0_8"); %relab (taxa="Lactobacillus_gasseri"); %relab (taxa="Lactobacillus_iners"); %relab (taxa="Lactobacillus_jensenii_0_8"); 
%relab (taxa="Lactobacillus_paracasei"); %relab (taxa="Lactobacillus_paracasei_0_8"); %relab (taxa="Lactobacillus_pontis_0_8"); %relab (taxa="Lactobacillus_reuteri"); 
%relab (taxa="Pediococcus_acidilactici"); %relab (taxa="Peptoniphilus_grossensis_ph5_0_8"); %relab (taxa="Peptoniphilus_lacrimalis"); %relab (taxa="Peptostreptococcus_anaerobius"); 
%relab (taxa="Porphyromonas_sp_1aAG15_1_x3"); %relab (taxa="Prevotella_bivia"); %relab (taxa="Prevotella_disiens"); %relab (taxa="Prevotella_timonensis"); 
%relab (taxa="Propionibacterium_acnes"); %relab (taxa="Providencia_rustigianii"); %relab (taxa="Rothia_dentocariosa"); %relab (taxa="Rothia_mucilaginosa"); 
%relab (taxa="S000414273_Campylobacter"); %relab (taxa="Staphylococcus_epidermidis"); %relab (taxa="Staphylococcus_epidermidis_0_8"); %relab (taxa="Streptococcus_agalactiae"); 
%relab (taxa="Streptococcus_anginosus"); %relab (taxa="Streptococcus_mitis_0_8"); %relab (taxa="Streptococcus_salivarius"); %relab (taxa="Veillonella_tobetsuensis_0_8"); 
%relab (taxa="uncultured_bacterium_Atopobium");


*-;

data tab_sp_relab; set tab_sp_relab;
if site= '' then delete;
run;

*Circ;
	*Genus;
%macro relab (taxa= );
proc means data=samples_rel_long n  mean std maxdec=4;
title '';
	var T1;
	class circumcision;
	where taxa = &taxa. and site = "Cervical";
	format circumcision circumcision.;
run;

proc npar1way data=samples_rel_long wilcoxon;
	var T1;
	class circumcision;
	where taxa = &taxa. and site = "Cervical";
	format circumcision circumcision.;
run;
%mend;

%relab (taxa="Prevotella");  %relab (taxa="Lactobacillus"); %relab (taxa="Corynebacterium"); %relab (taxa="Staphylococcus"); 
%relab (taxa="Gardnerella"); %relab (taxa="Finegoldia"); %relab (taxa="Streptococcus"); %relab (taxa="Atopobium");
%relab (taxa="Peptoniphilus"); %relab (taxa="Anaerococcus"); %relab (taxa="Actinomyces"); %relab (taxa="Mobiluncus");
%relab (taxa="Veillonella"); %relab (taxa="Dialister"); %relab (taxa="Megasphaera"); %relab (taxa="Porphyromonas");
%relab (taxa="Clostridiales_Unclassified_Uncla"); %relab (taxa="Ezakiella");

	*Species;
%macro relab (taxa= );
proc means data=species_rel_long n  mean std maxdec=4;
title '';
	var T1;
	class circumcision;
	where taxa = &taxa. and site = "Cervical";
	format circumcision circumcision.;
run;

proc npar1way data=species_rel_long wilcoxon;
	var T1;
	class circumcision;
	where taxa = &taxa. and site = "Cervical";
	format circumcision circumcision.;
run;
%mend;
 %relab (taxa="Dialister_micraerophilus");  %relab (taxa="Dialister_propionicifaciens");  
%relab (taxa="Dialister_succinatiphilus_0_8"); %relab (taxa="Peptostreptococcus_anaerobius"); 
%relab (taxa="Prevotella_bivia"); %relab (taxa="Prevotella_disiens");

*Significance testing;

%macro relab (taxa= , site=, value= );
proc means data=samples_rel_long n  mean std maxdec=4;
title '';
	var T1_2 T1_4;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;

proc univariate data=samples_rel_long ;
	var T1_2 T2_3 T3_4 T1_4;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;
%mend;

%relab (taxa=Corynebacterium, site=CorSul, value=0);
%relab (taxa=Dialister, site=CorSul, value=0);
%relab (taxa=Finegoldia, site=CorSul, value=0);
%relab (taxa=Gardnerella, site=CorSul, value=0);
%relab (taxa=Lactobacillus, site=CorSul, value=0);
%relab (taxa=Mobiluncus, site=CorSul, value=0);
%relab (taxa=Negativicoccus, site=CorSul, value=0);
%relab (taxa=Peptoniphilus, site=CorSul, value=0);
%relab (taxa=Peptostreptococcus, site=CorSul, value=0);
%relab (taxa=Porphyromonas, site=CorSul, value=0);
%relab (taxa=Prevotella, site=CorSul, value=0);
%relab (taxa=Staphylococcus, site=CorSul, value=0);

%relab (taxa=Corynebacterium, site=Cervical, value=0);
%relab (taxa=Dialister, site=Cervical, value=0);
%relab (taxa=Finegoldia, site=Cervical, value=0);
%relab (taxa=Gardnerella, site=Cervical, value=0);
%relab (taxa=Lactobacillus, site=Cervical, value=0);
*%relab (taxa=Mobiluncus, site=Cervical, value=0);
*%relab (taxa=Negativicoccus, site=Cervical, value=0);
%relab (taxa=Peptoniphilus, site=Cervical, value=0);
%relab (taxa=Peptostreptococcus, site=Cervical, value=0);
%relab (taxa=Porphyromonas, site=Cervical, value=0);
%relab (taxa=Prevotella, site=Cervical, value=0);
%relab (taxa=Staphylococcus, site=Cervical, value=0);

*with condom;
%relab (taxa=Corynebacterium, site=CorSul, value=1);
%relab (taxa=Dialister, site=CorSul, value=1);
%relab (taxa=Finegoldia, site=CorSul, value=1);
%relab (taxa=Gardnerella, site=CorSul, value=1);
%relab (taxa=Lactobacillus, site=CorSul, value=1);
%relab (taxa=Mobiluncus, site=CorSul, value=1);
%relab (taxa=Negativicoccus, site=CorSul, value=1);
%relab (taxa=Peptoniphilus, site=CorSul, value=1);
%relab (taxa=Peptostreptococcus, site=CorSul, value=1);
%relab (taxa=Porphyromonas, site=CorSul, value=1);
%relab (taxa=Prevotella, site=CorSul, value=1);
%relab (taxa=Staphylococcus, site=CorSul, value=1);

%relab (taxa=Corynebacterium, site=Cervical, value=1);
%relab (taxa=Dialister, site=Cervical, value=1);
%relab (taxa=Finegoldia, site=Cervical, value=1);
%relab (taxa=Gardnerella, site=Cervical, value=1);
%relab (taxa=Lactobacillus, site=Cervical, value=1);
*%relab (taxa=Mobiluncus, site=Cervical, value=1);
*%relab (taxa=Negativicoccus, site=Cervical, value=1);
%relab (taxa=Peptoniphilus, site=Cervical, value=1);
%relab (taxa=Peptostreptococcus, site=Cervical, value=1);
%relab (taxa=Porphyromonas, site=Cervical, value=1);
%relab (taxa=Prevotella, site=Cervical, value=1);
%relab (taxa=Staphylococcus, site=Cervical, value=1);


*Species;
%macro relab (taxa= , site=, value= );
proc means data=species_rel_long n  mean std maxdec=4;
title "'&taxa.";
	var T1 T2 T3 T4 ;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;

proc univariate data=species_rel_long ;
	var T1_2 T1_3 T1_4  ;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;
%mend;
%relab (taxa=Dialister_micraerophilus, site=CorSul, value=0);	/*BASIC*/
%relab (taxa=Dialister_propionicifaciens, site=CorSul, value=0);	/*BASIC*/
%relab (taxa=Dialister_succinatiphilus_0_8, site=CorSul, value=0);	/*BASIC*/
%relab (taxa=Finegoldia_magna, site=CorSul, value=0);
%relab (taxa=Gardnerella_vaginalis, site=CorSul, value=0);

%relab (taxa=Lactobacillus_crispatus, site=CorSul, value=0);
%relab (taxa=Lactobacillus_gasseri, site=CorSul, value=0);
%relab (taxa=Lactobacillus_iners, site=CorSul, value=0);
%relab (taxa=Lactobacillus_jensenii_0_8, site=CorSul, value=0);
%relab (taxa=Lactobacillus_reuteri, site=CorSul, value=0);
%relab (taxa=Mobiluncus_curtisii, site=CorSul, value=0);
%relab (taxa=Negativicoccus_succinicivorans, site=CorSul, value=0);

%relab (taxa=Peptoniphilus_asaccharolyticus_0, site=CorSul, value=0);
%relab (taxa=Peptoniphilus_lacrimalis, site=CorSul, value=0);
%relab (taxa=Peptostreptococcus_anaerobius, site=CorSul, value=0);	/*BASIC*/
%relab (taxa=Porphyromonas_asaccharolytica, site=CorSul, value=0);
%relab (taxa=Prevotella_bivia, site=CorSul, value=0); 	/*BASIC*/
%relab (taxa=Prevotella_buccalis, site=CorSul, value=0);
%relab (taxa=Prevotella_corporis, site=CorSul, value=0);
%relab (taxa=Prevotella_disiens, site=CorSul, value=0);	/*BASIC*/
%relab (taxa=Prevotella_timonensis, site=CorSul, value=0);
%relab (taxa=Staphylococcus_aureus_0_8, site=CorSul, value=0);
%relab (taxa=Staphylococcus_epidermidis, site=CorSul, value=0);

*Cerv;
%relab (taxa=Dialister_micraerophilus, site=Cervical, value=0);
%relab (taxa=Dialister_propionicifaciens, site=Cervical, value=0);
%relab (taxa=Dialister_succinatiphilus_0_8, site=Cervical, value=0);
%relab (taxa=Finegoldia_magna, site=Cervical, value=0);
%relab (taxa=Gardnerella_vaginalis, site=Cervical, value=0);

%relab (taxa=Lactobacillus_crispatus, site=Cervical, value=0);
%relab (taxa=Lactobacillus_gasseri, site=Cervical, value=0);
%relab (taxa=Lactobacillus_iners, site=Cervical, value=0);
%relab (taxa=Lactobacillus_jensenii_0_8, site=Cervical, value=0);
%relab (taxa=Lactobacillus_reuteri, site=Cervical, value=0);
%relab (taxa=Mobiluncus_curtisii, site=Cervical, value=0);
%relab (taxa=Negativicoccus_succinicivorans, site=Cervical, value=0);

%relab (taxa=Peptoniphilus_asaccharolyticus_0, site=Cervical, value=0);
%relab (taxa=Peptoniphilus_lacrimalis, site=Cervical, value=0);
%relab (taxa=Peptostreptococcus_anaerobius, site=Cervical, value=0);
%relab (taxa=Porphyromonas_asaccharolytica, site=Cervical, value=0);
%relab (taxa=Prevotella_bivia, site=Cervical, value=0);
%relab (taxa=Prevotella_buccalis, site=Cervical, value=0);
*%relab (taxa=Prevotella_corporis, site=Cervical, value=0);
%relab (taxa=Prevotella_disiens, site=Cervical, value=0);
%relab (taxa=Prevotella_timonensis, site=Cervical, value=0);
%relab (taxa=Staphylococcus_aureus_0_8, site=Cervical, value=0);
%relab (taxa=Staphylococcus_epidermidis, site=Cervical, value=0);


*-;
*Species by circ and condom;

*Species;
%macro relab (taxa= , site=, value= );
proc means data=species_rel_long n  mean std maxdec=4;
title "'&taxa.";
	var T1 T2 T3 T4 ;
	class circumcision;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
	format circumcision circumcision.;
run;

proc univariate data=species_rel_long ;
	var T1_2 T1_3 T1_4  ;
	class circumcision;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
	format circumcision circumcision.;
run;
%mend;
%relab (taxa=Dialister_micraerophilus, site=CorSul, value=0);	/*BASIC*/
%relab (taxa=Dialister_propionicifaciens, site=CorSul, value=0);	/*BASIC*/
%relab (taxa=Dialister_succinatiphilus_0_8, site=CorSul, value=0);	/*BASIC*/
%relab (taxa=Finegoldia_magna, site=CorSul, value=0);
%relab (taxa=Gardnerella_vaginalis, site=CorSul, value=0);
%relab (taxa=Hoylesella_timonensis, site=CorSul, value=0);

%relab (taxa=Lactobacillus_crispatus, site=CorSul, value=0);
%relab (taxa=Lactobacillus_gasseri, site=CorSul, value=0);
%relab (taxa=Lactobacillus_iners, site=CorSul, value=0);
%relab (taxa=Lactobacillus_jensenii_0_8, site=CorSul, value=0);
%relab (taxa=Lactobacillus_reuteri, site=CorSul, value=0);
%relab (taxa=Mobiluncus_curtisii, site=CorSul, value=0);
%relab (taxa=Negativicoccus_succinicivorans, site=CorSul, value=0);

%relab (taxa=Peptoniphilus_asaccharolyticus_0, site=CorSul, value=0);
%relab (taxa=Peptoniphilus_lacrimalis, site=CorSul, value=0);
%relab (taxa=Peptostreptococcus_anaerobius, site=CorSul, value=0);	/*BASIC*/
%relab (taxa=Porphyromonas_asaccharolytica, site=CorSul, value=0);
%relab (taxa=Prevotella_bivia, site=CorSul, value=0); 	/*BASIC*/
%relab (taxa=Prevotella_buccalis, site=CorSul, value=0);
%relab (taxa=Prevotella_corporis, site=CorSul, value=0);
%relab (taxa=Prevotella_disiens, site=CorSul, value=0);	/*BASIC*/
%relab (taxa=Prevotella_timonensis, site=CorSul, value=0);
%relab (taxa=Staphylococcus_aureus_0_8, site=CorSul, value=0);
%relab (taxa=Staphylococcus_epidermidis, site=CorSul, value=0);

*Cerv;
%relab (taxa=Dialister_micraerophilus, site=Cervical, value=0);
%relab (taxa=Dialister_propionicifaciens, site=Cervical, value=0);
%relab (taxa=Dialister_succinatiphilus_0_8, site=Cervical, value=0);
%relab (taxa=Finegoldia_magna, site=Cervical, value=0);
%relab (taxa=Gardnerella_vaginalis, site=Cervical, value=0);

%relab (taxa=Lactobacillus_crispatus, site=Cervical, value=0);
%relab (taxa=Lactobacillus_gasseri, site=Cervical, value=0);
%relab (taxa=Lactobacillus_iners, site=Cervical, value=0);
%relab (taxa=Lactobacillus_jensenii_0_8, site=Cervical, value=0);
%relab (taxa=Lactobacillus_reuteri, site=Cervical, value=0);
%relab (taxa=Mobiluncus_curtisii, site=Cervical, value=0);
%relab (taxa=Negativicoccus_succinicivorans, site=Cervical, value=0);

%relab (taxa=Peptoniphilus_asaccharolyticus_0, site=Cervical, value=0);
%relab (taxa=Peptoniphilus_lacrimalis, site=Cervical, value=0);
%relab (taxa=Peptostreptococcus_anaerobius, site=Cervical, value=0);
%relab (taxa=Porphyromonas_asaccharolytica, site=Cervical, value=0);
%relab (taxa=Prevotella_bivia, site=Cervical, value=0);
%relab (taxa=Prevotella_buccalis, site=Cervical, value=0);
*%relab (taxa=Prevotella_corporis, site=Cervical, value=0);
%relab (taxa=Prevotella_disiens, site=Cervical, value=0);
%relab (taxa=Prevotella_timonensis, site=Cervical, value=0);
%relab (taxa=Staphylococcus_aureus_0_8, site=Cervical, value=0);
%relab (taxa=Staphylococcus_epidermidis, site=Cervical, value=0);


*----------------------;
*Absolute Abundance;
*----------------------;

proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa by Sample Type';
var &taxa_list;
class  site ;
run;

proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var &taxa_list;
class  site time;
run;

*BASIC and BVAB;
data secs_analytic; set secs_analytic;
l_BASIC = log10(BASIC+1);
l_BVAB = log10(BVAB+1);
run;

proc means data=secs_analytic n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var l_BASIC;
class  site time;
where l_BASIC > 0;
run;

proc means data=secs_analytic n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var l_BVAB;
class  site time;
where l_BVAB > 0;
run;

proc means data=secs_analytic n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var l_BASIC;
class condom site time;
where l_BASIC > 0;
run;

proc means data=secs_analytic n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var l_BVAB;
class condom site time;
where l_BVAB > 0;
run;

*Taxa;

data tab_genus_absab;
	length taxa $32 site $8 T1 8 T2 8 T3 8 T4 8 ;
run;

%macro medabs (var= );
proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type among Positives';
var &var.;
	output out=tab_genus_absab_temp(drop=_type_ _freq_) median=  /autoname;
class site time;
where &var. > 0;
run;

data tab_genus_absab_temp; set tab_genus_absab_temp; 
	if site = '' then delete;
	if time = . then delete;
	median = &var._Median;
	keep taxa site time median;
run;

proc transpose data= tab_genus_absab_temp out=tab_genus_absab_temp prefix=T;
	id time;
	by site;
	var Median;
run;

data tab_genus_absab_temp; set tab_genus_absab_temp;
	taxa = "&var.";
	drop _NAME_;
run;

proc append data = tab_genus_absab_temp base=tab_genus_absab;
run;

%mend;

*Cor Sul;
%medabs (var=Actinomyces); %medabs(var=Actinomycetales_Unclassified_Unc); %medabs(var=Anaerococcus); %medabs(var=Campylobacter); %medabs(var=Corynebacterium); 
%medabs(var=Dermabacter); %medabs(var=Dialister); %medabs(var=Ezakiella); %medabs(var=Finegoldia); %medabs(var=Gardnerella); %medabs(var=Lactobacillus); 
%medabs(var=Negativicoccus); %medabs(var=Peptoniphilus); %medabs(var=Porphyromonas); %medabs(var=Prevotella); %medabs(var=Propionibacterium); %medabs(var=Staphylococcus); 
%medabs(var=Streptococcus); %medabs(var=Veillonella);

*Cervical;
%medabs (var=Anaerococcus); %medabs(var=Atopobium); %medabs(var=Bacilli_Unclassified_Unclassifie); %medabs(var=Clostridiales_Unclassified_Uncla); 
%medabs(var=Corynebacterium); %medabs(var=Dialister); %medabs(var=Enterorhabdus_0_8); %medabs(var=Finegoldia); 
%medabs(var=Firmicutes_Unclassified_Unclassi); %medabs(var=Gardnerella); %medabs(var=Gemella); %medabs(var=Lactobacillales_Unclassified_Unc); 
%medabs(var=Lactobacillus); %medabs(var=Peptoniphilus); %medabs(var=Peptostreptococcus); %medabs(var=Prevotella); %medabs(var=Staphylococcus); 
%medabs(var=Streptococcus); %medabs(var=Veillonella);


*Stratified by condom use;
	*change condom status in where statement;

data tab_genus_absab;
	length taxa $32 site $8 T1 8 T2 8 T3 8 T4 8 ;
run;

%macro medabs (var= );
proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type among Positives';
var &var.;
	output out=tab_genus_absab_temp(drop=_type_ _freq_) median=  /autoname;
class site time;
where &var. > 0 and condom = 1;
run;

data tab_genus_absab_temp; set tab_genus_absab_temp; 
	if site = '' then delete;
	if time = . then delete;
	median = &var._Median;
	keep taxa site time median;
run;

proc transpose data= tab_genus_absab_temp out=tab_genus_absab_temp prefix=T;
	id time;
	by site;
	var Median;
run;

data tab_genus_absab_temp; set tab_genus_absab_temp;
	taxa = "&var.";
	drop _NAME_;
run;

proc append data = tab_genus_absab_temp base=tab_genus_absab;
run;

%mend;

*Cor Sul;
	*no condom;
%medabs (var=Actinomyces); %medabs(var=Actinomycetales_Unclassified_Unc); %medabs(var=Anaerococcus); %medabs(var=Campylobacter); %medabs(var=Corynebacterium); 
%medabs(var=Dermabacter); %medabs(var=Dialister); %medabs(var=Ezakiella); %medabs(var=Finegoldia); %medabs(var=Gardnerella); %medabs(var=Lactobacillus); 
%medabs(var=Negativicoccus); %medabs(var=Peptoniphilus); %medabs(var=Porphyromonas); %medabs(var=Prevotella); %medabs(var=Propionibacterium); %medabs(var=Staphylococcus); 
%medabs(var=Streptococcus); %medabs(var=Veillonella);

	*condom;
%medabs (var=Acinetobacter); %medabs (var=Actinomyces); %medabs (var=Actinomycetales_Unclassified_Unc); %medabs (var=Actinotignum); %medabs (var=Aerococcus); 
%medabs (var=Alloprevotella); %medabs (var=Anaerococcus); %medabs (var=Anaeroglobus); %medabs (var=Atopobium); %medabs (var=Bacilli_Unclassified_Unclassifie); 
%medabs (var=Brachybacterium); %medabs (var=Brevibacterium); %medabs (var=Campylobacter); %medabs (var=Clostridiales_Unclassified_Uncla); 
%medabs (var=Clostridium_sensu_stricto); %medabs (var=Corynebacterium); %medabs (var=Dermabacter); %medabs (var=Dermabacter_0_8); %medabs (var=Dermacoccus); 
%medabs (var=Dialister); %medabs (var=Enhydrobacter); %medabs (var=Enterococcus); %medabs (var=Eremococcus); %medabs (var=Escherichia_Shigella); 
%medabs (var=Ezakiella); %medabs (var=Finegoldia); %medabs (var=Firmicutes_Unclassified_Unclassi); %medabs (var=Fusobacterium); %medabs (var=Gardnerella); 
%medabs (var=Gemella); %medabs (var=Granulicatella); %medabs (var=Haemophilus); %medabs (var=Haemophilus_0_8); %medabs (var=Howardella); %medabs (var=Kocuria); 
%medabs (var=Kytococcus); %medabs (var=Lachnoanaerobaculum); %medabs (var=Lactobacillales_Unclassified_Unc); %medabs (var=Lactobacillus); %medabs (var=Micrococcus); 
%medabs (var=Mobiluncus); %medabs (var=Morganella); %medabs (var=Murdochiella); %medabs (var=Negativicoccus); %medabs (var=Neisseria); 
%medabs (var=Parvibacter_0_8); %medabs (var=Peptococcus); %medabs (var=Peptoniphilus); %medabs (var=Peptostreptococcus); %medabs (var=Porphyromonas); 
%medabs (var=Prevotella); %medabs (var=Propionibacterium); %medabs (var=Propionimicrobium); %medabs (var=Providencia); %medabs (var=Pseudomonas); 
%medabs (var=Roseburia); %medabs (var=Rothia); %medabs (var=Saccharibacteria_genera_incertia); %medabs (var=Staphylococcus); %medabs (var=Streptococcus); 
%medabs (var=Streptophyta); %medabs (var=Veillonella);

*Cervical;
	*no condom;
%medabs (var=Anaerococcus); %medabs(var=Atopobium); %medabs(var=Bacilli_Unclassified_Unclassifie); %medabs(var=Clostridiales_Unclassified_Uncla); 
%medabs(var=Corynebacterium); %medabs(var=Dialister); %medabs(var=Enterorhabdus_0_8); %medabs(var=Finegoldia); 
%medabs(var=Firmicutes_Unclassified_Unclassi); %medabs(var=Gardnerella); %medabs(var=Gemella); %medabs(var=Lactobacillales_Unclassified_Unc); 
%medabs(var=Lactobacillus); %medabs(var=Peptoniphilus); %medabs(var=Peptostreptococcus); %medabs(var=Prevotella); %medabs(var=Staphylococcus); 
%medabs(var=Streptococcus); %medabs(var=Veillonella);

	*condom;
%medabs(var=Acinetobacter); %medabs(var=Actinomyces); %medabs(var=Aerococcus); %medabs(var=Anaerococcus); %medabs(var=Anaeroglobus); %medabs(var=Atopobium); 
%medabs(var=Bacilli_Unclassified_Unclassifie); %medabs(var=Bifidobacterium); %medabs(var=Brevibacterium); %medabs(var=Campylobacter); %medabs(var=Clostridium_sensu_stricto); 
%medabs(var=Corynebacterium); %medabs(var=Dialister); %medabs(var=Dysgonomonas); %medabs(var=Enterococcus); %medabs(var=Eremococcus); %medabs(var=Escherichia_Shigella); 
%medabs(var=Finegoldia); %medabs(var=Firmicutes_Unclassified_Unclassi); %medabs(var=Fusobacterium); %medabs(var=Gardnerella); %medabs(var=Gemella); %medabs(var=Granulicatella); 
%medabs(var=Haemophilus); %medabs(var=Haemophilus_0_8); %medabs(var=Howardella); %medabs(var=Lactobacillales_Unclassified_Unc); %medabs(var=Lactobacillus); %medabs(var=Neisseria); 
%medabs(var=Pediococcus); %medabs(var=Peptoniphilus); %medabs(var=Peptostreptococcus); %medabs(var=Porphyromonas); %medabs(var=Prevotella); %medabs(var=Propionibacterium); 
%medabs(var=Providencia); %medabs(var=Rothia); %medabs(var=Staphylococcus); %medabs(var=Streptococcus); %medabs(var=Veillonella); 

*LRR;
data tab_genus_lrr;
length Taxa $32 Site $8 LR1_2_Median 8 LR2_3_Median 8 LR3_4_Median 8 LR1_4_Median 8 ;
run;

%macro lrr (taxa= );
proc means data=samples_long n  q1 median q3 maxdec=3;
title '';
	var LR1_2 LR2_3 LR3_4 LR1_4;
	class site;
	output out=tab_genus_lrr_temp(drop=_type_ _freq_) median=  /autoname;
	where taxa = "&taxa." and site in ("Cervical" "CorSul");
run;

data tab_genus_lrr_temp; set tab_genus_lrr_temp;
taxa = "&taxa.";
run;

proc append data=tab_genus_lrr_temp base=tab_genus_lrr force;
run;
%mend;

*Cor Sul;
%lrr (taxa=Actinomyces); %lrr(taxa=Actinomycetales_Unclassified_Unc); %lrr(taxa=Anaerococcus); %lrr(taxa=Campylobacter); %lrr(taxa=Corynebacterium); 
%lrr(taxa=Dermabacter); %lrr(taxa=Dialister); %lrr(taxa=Ezakiella); %lrr(taxa=Finegoldia); %lrr(taxa=Gardnerella); %lrr(taxa=Lactobacillus); 
%lrr(taxa=Negativicoccus); %lrr(taxa=Peptoniphilus); %lrr(taxa=Porphyromonas); %lrr(taxa=Prevotella); %lrr(taxa=Propionibacterium); %lrr(taxa=Staphylococcus); 
%lrr(taxa=Streptococcus); %lrr(taxa=Veillonella);

*Cervical;
%lrr (taxa=Anaerococcus); %lrr(taxa=Atopobium); %lrr(taxa=Bacilli_Unclassified_Unclassifie); %lrr(taxa=Clostridiales_Unclassified_Uncla); 
%lrr(taxa=Corynebacterium); %lrr(taxa=Dialister); %lrr(taxa=Enterorhabdus_0_8); %lrr(taxa=Finegoldia); 
%lrr(taxa=Firmicutes_Unclassified_Unclassi); %lrr(taxa=Gardnerella); %lrr(taxa=Gemella); %lrr(taxa=Lactobacillales_Unclassified_Unc); 
%lrr(taxa=Lactobacillus); %lrr(taxa=Peptoniphilus); %lrr(taxa=Peptostreptococcus); %lrr(taxa=Prevotella); %lrr(taxa=Staphylococcus); 
%lrr(taxa=Streptococcus); %lrr(taxa=Veillonella);

*--;
*Species;

proc means data=species n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var &species_list;
class  site time;
run;

data tab_sp_absab;
length taxa $32 site $12 time 8 median 8;
run;

%macro medabs (var= );
proc means data=species n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var &var.;
class site time;
output out=tab_sp_absab_temp (drop=_type_ _freq_) median= /autoname;
where &var. > 0 ;
run;

proc sort data=tab_sp_absab_temp; by site time; run;
proc transpose data=tab_sp_absab_temp out=tab_sp_absab_temp;
by site time;
run;

data tab_sp_absab_temp; set tab_sp_absab_temp;
taxa = "&var.";
median= COL1;
drop COL1 _NAME_;
run;

proc append data=tab_sp_absab_temp base=tab_sp_absab;
run;
%mend;

%medabs (var=Acinetobacter_baumannii);
%medabs (var=Dialister_micraerophilus);
%medabs (var=Dialister_propionicifaciens);
%medabs (var=Dialister_succinatiphilus_0_8);
%medabs (var=Finegoldia_magna); 
%medabs (var=Gardnerella_vaginalis); 
%medabs (var=Lactobacillus_crispatus); 
%medabs (var=Lactobacillus_gasseri);
%medabs (var=Lactobacillus_iners);
%medabs (var=Lactobacillus_reuteri);
%medabs (var=Mobiluncus_curtisii);
%medabs (var=Negativicoccus_succinicivorans);
%medabs (var=Peptoniphilus_asaccharolyticus_0);
%medabs (var=Peptoniphilus_lacrimalis);
%medabs (var=Peptostreptococcus_anaerobius);
%medabs (var=Porphyromonas_asaccharolytica);
%medabs (var=Prevotella_bivia);
%medabs (var=Prevotella_buccalis);
%medabs (var=Prevotella_corporis);
%medabs (var=Prevotella_disiens);
%medabs (var=Sneathia_sp_Sn35);

*-;
*Condom strata;
	*Change condom status in where statement;

data tab_sp_absab;
length taxa $32 site $12 time 8 median 8;
run;

%macro medabs (var= );
proc means data=species n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var &var.;
class site time;
output out=tab_sp_absab_temp (drop=_type_ _freq_) median= /autoname;
where &var. > 0 and condom = 1;
run;

proc sort data=tab_sp_absab_temp; by site time; run;
proc transpose data=tab_sp_absab_temp out=tab_sp_absab_temp;
by site time;
run;

data tab_sp_absab_temp; set tab_sp_absab_temp;
taxa = "&var.";
median= COL1;
drop COL1 _NAME_;
run;

proc append data=tab_sp_absab_temp base=tab_sp_absab;
run;
%mend;


*Taxa - cor sul - no condom;
%medabs (var=Actinomyces_neuii); %medabs (var=Actinomyces_radingae); %medabs (var=Actinomyces_turicensis); %medabs (var=Actinomycetales_Unclassified_Unc); 
%medabs (var=Anaerococcus_hydrogenalis); %medabs (var=Anaerococcus_lactolyticus); %medabs (var=Anaerococcus_obesiensis_ph10_0_8); 
%medabs (var=Anaerococcus_octavius_0_8); %medabs (var=Anaerococcus_prevotii_DSM_20548); %medabs (var=Anaerococcus_prevotii_DSM_20548_); 
%medabs (var=Anaerococcus_senegalensis_JC48_0); %medabs (var=Anaerococcus_sp_S9_PR_5_0_8); %medabs (var=Anaeroglobus_geminatus); 
%medabs (var=Arcanobacterium_phocae); %medabs (var=Brevibacterium_paucivorans_0_8); %medabs (var=C_glucuronolyticum_0_8); %medabs (var=Campylobacter_hominis); 
%medabs (var=Candidatus_Peptoniphilus_massile); %medabs (var=Clostridiales_Unclassified_Uncla); %medabs (var=Clostridium_carboxidivorans_0_8); 
%medabs (var=Coriobacteriaceae_Unclassified_U); %medabs (var=Corynebacterium_afermentans_0_8); %medabs (var=Corynebacterium_amycolatum_0_8); 
%medabs (var=Corynebacterium_appendicis); %medabs (var=Corynebacterium_appendicis_0_8); %medabs (var=Corynebacterium_argentoratense_0); 
%medabs (var=Corynebacterium_aurimucosum); %medabs (var=Corynebacterium_imitans); %medabs (var=Corynebacterium_kroppenstedtii); 
%medabs (var=Corynebacterium_pilbarense_0_8); %medabs (var=Corynebacterium_pyruviciproducen); %medabs (var=Corynebacterium_simulans_0_8); 
%medabs (var=Corynebacterium_singulare_0_8); %medabs (var=Corynebacterium_thomssenii); %medabs (var=Corynebacterium_tuberculostearic); 
%medabs (var=Corynebacterium_ureicelerivorans); %medabs (var=Dermabacter_hominis); %medabs (var=Dialister_micraerophilus); %medabs (var=Dialister_propionicifaciens); 
%medabs (var=Dialister_succinatiphilus_0_8); %medabs (var=Dysgonomonas_gadei); %medabs (var=Dysgonomonas_mossii_0_8); %medabs (var=Enterobacteriaceae_Unclassified_); 
%medabs (var=Enterococcus_faecalis); %medabs (var=Eremococcus_coleocola); %medabs (var=Escherichia_Shigella_fergusonii_); %medabs (var=Facklamia_hominis); 
%medabs (var=Finegoldia_magna); %medabs (var=Firmicutes_Unclassified_Unclassi); %medabs (var=Gardnerella_vaginalis); %medabs (var=Gemella_haemolysans); 
%medabs (var=Gemella_sanguinis); %medabs (var=Haemophilus_parainfluenzae); %medabs (var=Howardella_ureilytica); %medabs (var=Kocuria_salsicia_0_8); 
%medabs (var=Lachnospiraceae_Unclassified_Unc); %medabs (var=Lactobacillus_crispatus); %medabs (var=Lactobacillus_fornicalis_0_8); %medabs (var=Lactobacillus_gasseri); 
%medabs (var=Lactobacillus_iners); %medabs (var=Lactobacillus_jensenii_0_8); %medabs (var=Lactobacillus_reuteri); %medabs (var=Megasphaera_micronuciformis); 
%medabs (var=Micrococcus_aloeverae_0_8); %medabs (var=Mobiluncus_curtisii); %medabs (var=Moraxellaceae_Unclassified_Uncla); %medabs (var=Morganella_morganii); 
%medabs (var=Murdochiella_sp_S5_A16_0_8); %medabs (var=Negativicoccus_succinicivorans); %medabs (var=Neisseria_perflava); %medabs (var=Peptococcus_niger); 
%medabs (var=Peptoniphilus_asaccharolyticus_0); %medabs (var=Peptoniphilus_grossensis_ph5_0_8); %medabs (var=Peptoniphilus_harei_0_8); %medabs (var=Peptoniphilus_lacrimalis); 
%medabs (var=Peptoniphilus_sp_7_2_0_8); %medabs (var=Peptoniphilus_sp_BV3AC2_0_8); %medabs (var=Peptoniphilus_sp_S5_A2_0_8); %medabs (var=Peptoniphilus_sp_S9_PR_13_0_8); 
%medabs (var=Peptostreptococcus_anaerobius); %medabs (var=Peptostreptococcus_stomatis); %medabs (var=Porphyromonadaceae_Unclassified_); 
%medabs (var=Porphyromonas_asaccharolytica); %medabs (var=Porphyromonas_asaccharolytica_0_); %medabs (var=Porphyromonas_bennonis); 
%medabs (var=Porphyromonas_circumdentaria_0_8); %medabs (var=Prevotella_bergensis); %medabs (var=Prevotella_bivia); %medabs (var=Prevotella_buccalis); 
%medabs (var=Prevotella_corporis); %medabs (var=Prevotella_disiens); %medabs (var=Prevotella_melaninogenica); %medabs (var=Prevotella_pallens); 
%medabs (var=Prevotella_timonensis); %medabs (var=Propionibacterium_acnes); %medabs (var=Providencia_rustigianii); %medabs (var=Pseudomonas_guariconensis_0_8); 
%medabs (var=Rothia_mucilaginosa); %medabs (var=Ruminococcaceae_Unclassified_Unc); %medabs (var=S000414273_Campylobacter); %medabs (var=Staphylococcus_aureus_0_8); 
%medabs (var=Staphylococcus_epidermidis); %medabs (var=Staphylococcus_epidermidis_0_8); %medabs (var=Staphylococcus_epidermidis_RP62A); 
%medabs (var=Staphylococcus_hominis_0_8); %medabs (var=Streptococcus_agalactiae); %medabs (var=Streptococcus_anginosus); %medabs (var=Streptococcus_mitis_0_8); 
%medabs (var=Streptococcus_oligofermentans_0_); %medabs (var=Streptococcus_salivarius); %medabs (var=TM7_phylum_sp_oral_clone_DR034); %medabs (var=Varibaculum_cambriense); 
%medabs (var=Veillonella_atypica_0_8); %medabs (var=Veillonella_dispar); %medabs (var=Veillonella_montpellierensis); %medabs (var=uncultured_Anaerococcus_sp); 
%medabs (var=uncultured_Anaerococcus_sp_0_8); %medabs (var=uncultured_Olsenella_sp_0_8); %medabs (var=uncultured_Prevotella_sp_0_8); 
%medabs (var=uncultured_bacterium_Atopobium); %medabs (var=uncultured_bacterium_Ezakiella); %medabs (var=uncultured_bacterium_Parvimonas); 
%medabs (var=uncultured_organism_Atopobium); %medabs (var=uncultured_organism_Granulicatel);

*Cervical Secretions - no condom;
%medabs (var=Actinomycetales_Unclassified_Unc); %medabs (var=Aerococcus_christensenii); %medabs (var=Anaerococcus_prevotii_DSM_20548); 
%medabs (var=Clostridiales_Unclassified_Uncla); %medabs (var=Coriobacteriaceae_Unclassified_U); %medabs (var=Corynebacterium_tuberculostearic); 
%medabs (var=Dialister_micraerophilus); %medabs (var=Dialister_propionicifaciens); %medabs (var=Dialister_succinatiphilus_0_8); 
%medabs (var=Escherichia_Shigella_fergusonii_); %medabs (var=Finegoldia_magna); %medabs (var=Firmicutes_Unclassified_Unclassi); %medabs (var=Gardnerella_vaginalis); 
%medabs (var=Gemella_haemolysans); %medabs (var=Haemophilus_parainfluenzae); %medabs (var=Lactobacillales_Unclassified_Unc); %medabs (var=Lactobacillus_acidophilus_0_8); 
%medabs (var=Lactobacillus_crispatus); %medabs (var=Lactobacillus_fornicalis_0_8); %medabs (var=Lactobacillus_gasseri); %medabs (var=Lactobacillus_iners); 
%medabs (var=Lactobacillus_jensenii_0_8); %medabs (var=Lactobacillus_reuteri); %medabs (var=Megasphaera_indica_0_8); %medabs (var=Neisseria_perflava); 
%medabs (var=Peptoniphilus_grossensis_ph5_0_8); %medabs (var=Peptoniphilus_lacrimalis); %medabs (var=Peptoniphilus_sp_BV3AC2_0_8); 
%medabs (var=Peptoniphilus_sp_S9_PR_13_0_8); %medabs (var=Peptostreptococcus_anaerobius); %medabs (var=Prevotella_bivia); %medabs (var=Prevotella_buccalis); 
%medabs (var=Prevotella_disiens); %medabs (var=Prevotella_timonensis); %medabs (var=S000414273_Campylobacter); %medabs (var=Staphylococcus_epidermidis); 
%medabs (var=Staphylococcus_epidermidis_0_8); %medabs (var=Streptococcus_agalactiae); %medabs (var=Streptococcus_anginosus); %medabs (var=Streptococcus_mitis_0_8); 
%medabs (var=Streptococcus_salivarius); %medabs (var=Veillonella_montpellierensis); %medabs (var=issierellia_bacterium_KA00581); %medabs (var=uncultured_Anaerococcus_sp); 
%medabs (var=uncultured_Prevotella_sp_0_8); %medabs (var=uncultured_bacterium_Atopobium); %medabs (var=uncultured_bacterium_Ezakiella);

*Cor Sul, condom;
%medabs (var=Acinetobacter_guillouiae_0_8); %medabs (var=Actinomyces_neuii); %medabs (var=Actinomyces_odontolyticus); %medabs (var=Actinomyces_radingae); 
%medabs (var=Actinomycetales_Unclassified_Unc); %medabs (var=Actinotignum_sanguinis); %medabs (var=Anaerococcus_octavius_0_8); 
%medabs (var=Anaerococcus_prevotii_DSM_20548); %medabs (var=Anaerococcus_prevotii_DSM_20548_); %medabs (var=Anaerococcus_senegalensis_JC48_0); 
%medabs (var=Anaeroglobus_geminatus); %medabs (var=Bacteroidales_Unclassified_Uncla); %medabs (var=C_glucuronolyticum_0_8); %medabs (var=Candidatus_Peptoniphilus_massile); 
%medabs (var=Clostridiales_Unclassified_Uncla); %medabs (var=Coriobacteriaceae_Unclassified_U); %medabs (var=Corynebacterium_afermentans_0_8); 
%medabs (var=Corynebacterium_appendicis); %medabs (var=Corynebacterium_argentoratense_0); %medabs (var=Corynebacterium_imitans); %medabs (var=Corynebacterium_pilbarense_0_8); 
%medabs (var=Corynebacterium_pyruviciproducen); %medabs (var=Corynebacterium_singulare_0_8); %medabs (var=Corynebacterium_thomssenii); 
%medabs (var=Corynebacterium_tuberculostearic); %medabs (var=Dermabacter_hominis); %medabs (var=Dialister_micraerophilus); %medabs (var=Dialister_propionicifaciens); 
%medabs (var=Dialister_succinatiphilus_0_8); %medabs (var=Enterobacteriaceae_Unclassified_); %medabs (var=Enterococcus_faecalis); %medabs (var=Eremococcus_coleocola); 
%medabs (var=Escherichia_Shigella_fergusonii_); %medabs (var=Finegoldia_magna); %medabs (var=Fusobacterium_periodonticum); %medabs (var=Gardnerella_vaginalis);  %medabs (var=Gemella_haemolysans); 
%medabs (var=Gemella_sanguinis); %medabs (var=Haemophilus_parainfluenzae); %medabs (var=Haemophilus_pittmaniae); %medabs (var=Howardella_ureilytica); 
%medabs (var=Kocuria_salsicia_0_8); %medabs (var=Lachnospiraceae_Unclassified_Unc); %medabs (var=Lactobacillus_coleohominis); %medabs (var=Lactobacillus_crispatus); 
%medabs (var=Lactobacillus_gasseri); %medabs (var=Lactobacillus_iners); %medabs (var=Lactobacillus_jensenii_0_8); %medabs (var=Lactobacillus_reuteri); 
%medabs (var=Micrococcus_endophyticus_0_8); %medabs (var=Mobiluncus_curtisii); %medabs (var=Moraxellaceae_Unclassified_Uncla); %medabs (var=Morganella_morganii); 
%medabs (var=Murdochiella_sp_S5_A16_0_8); %medabs (var=Negativicoccus_succinicivorans); %medabs (var=Peptococcus_niger); %medabs (var=Peptoniphilus_asaccharolyticus_0); 
%medabs (var=Peptoniphilus_grossensis_ph5_0_8); %medabs (var=Peptoniphilus_harei_0_8); %medabs (var=Peptoniphilus_lacrimalis); %medabs (var=Peptoniphilus_sp_7_2_0_8); 
%medabs (var=Peptoniphilus_sp_BV3AC2_0_8); %medabs (var=Peptoniphilus_sp_S5_A2_0_8); %medabs (var=Peptoniphilus_sp_S9_PR_13_0_8); %medabs (var=Peptostreptococcus_anaerobius); 
%medabs (var=Porphyromonas_asaccharolytica_0_); %medabs (var=Porphyromonas_bennonis); %medabs (var=Porphyromonas_pasteri_0_8); %medabs (var=Prevotella_bergensis); 
%medabs (var=Prevotella_bivia); %medabs (var=Prevotella_buccalis); %medabs (var=Prevotella_disiens); %medabs (var=Prevotella_melaninogenica); 
%medabs (var=Prevotella_timonensis); %medabs (var=Propionibacterium_acnes); %medabs (var=Propionimicrobium_lymphophilum); %medabs (var=Providencia_rustigianii); 
%medabs (var=Rothia_dentocariosa); %medabs (var=Rothia_mucilaginosa); %medabs (var=S000414273_Campylobacter); %medabs (var=Staphylococcus_aureus_0_8); 
%medabs (var=Staphylococcus_epidermidis); %medabs (var=Staphylococcus_epidermidis_0_8); %medabs (var=Staphylococcus_epidermidis_RP62A); %medabs (var=Streptococcus_agalactiae); 
%medabs (var=Streptococcus_mitis_0_8); %medabs (var=Streptococcus_salivarius); %medabs (var=Streptococcus_sinensis_0_8); %medabs (var=Veillonella_atypica_0_8); 
%medabs (var=Veillonella_dispar); %medabs (var=Veillonellaceae_Unclassified_Unc); %medabs (var=uncultured_Anaerococcus_sp); %medabs (var=uncultured_Anaerococcus_sp_0_8); 
%medabs (var=uncultured_Prevotella_sp_0_8); %medabs (var=uncultured_bacterium_Atopobium); %medabs (var=uncultured_bacterium_Ezakiella); 
%medabs (var=uncultured_organism_Granulicatel);

*Cervical, condom;
%medabs (var=Acinetobacter_bereziniae_0_8); %medabs (var=Actinomyces_neuii); %medabs (var=Aerococcus_christensenii); %medabs (var=Anaerococcus_octavius_0_8); 
%medabs (var=Anaerococcus_prevotii_DSM_20548); %medabs (var=Anaeroglobus_geminatus); %medabs (var=Atopobium_sp_S7MSR3); %medabs (var=Brevibacterium_massiliense_0_8); 
%medabs (var=Candidatus_Peptoniphilus_massile); %medabs (var=Clostridium_colicanis); %medabs (var=Corynebacterium_afermentans_0_8); %medabs (var=Corynebacterium_aurimucosum); 
%medabs (var=Corynebacterium_aurimucosum_0_8); %medabs (var=Corynebacterium_coyleae_0_8); %medabs (var=Corynebacterium_imitans); %medabs (var=Corynebacterium_pilbarense_0_8); 
%medabs (var=Corynebacterium_singulare_0_8); %medabs (var=Corynebacterium_sundsvallense_0_); %medabs (var=Corynebacterium_tuberculostearic); 
%medabs (var=Corynebacterium_tuscaniense); %medabs (var=Dialister_micraerophilus); %medabs (var=Dialister_propionicifaciens); %medabs (var=Dialister_succinatiphilus_0_8); 
%medabs (var=Dysgonomonas_oryzarvi_0_8); %medabs (var=Enterococcus_faecalis); %medabs (var=Eremococcus_coleocola); %medabs (var=Escherichia_Shigella_fergusonii_); 
%medabs (var=Finegoldia_magna); %medabs (var=Firmicutes_Unclassified_Unclassi); %medabs (var=Fusobacterium_periodonticum); %medabs (var=Gardnerella_vaginalis); 
%medabs (var=Gemella_haemolysans); %medabs (var=Gemella_sanguinis); %medabs (var=Haemophilus_parainfluenzae); %medabs (var=Howardella_ureilytica); 
%medabs (var=Lactobacillales_Unclassified_Unc); %medabs (var=Lactobacillus_acidophilus_0_8); %medabs (var=Lactobacillus_coleohominis); %medabs (var=Lactobacillus_crispatus); 
%medabs (var=Lactobacillus_fornicalis_0_8); %medabs (var=Lactobacillus_gasseri); %medabs (var=Lactobacillus_iners); %medabs (var=Lactobacillus_jensenii_0_8); 
%medabs (var=Lactobacillus_paracasei); %medabs (var=Lactobacillus_paracasei_0_8); %medabs (var=Lactobacillus_pontis_0_8); %medabs (var=Lactobacillus_reuteri); 
%medabs (var=Pediococcus_acidilactici); %medabs (var=Peptoniphilus_grossensis_ph5_0_8); %medabs (var=Peptoniphilus_lacrimalis); %medabs (var=Peptostreptococcus_anaerobius); 
%medabs (var=Porphyromonas_sp_1aAG15_1_x3); %medabs (var=Prevotella_bivia); %medabs (var=Prevotella_disiens); %medabs (var=Prevotella_timonensis); 
%medabs (var=Propionibacterium_acnes); %medabs (var=Providencia_rustigianii); %medabs (var=Rothia_dentocariosa); %medabs (var=Rothia_mucilaginosa); 
%medabs (var=S000414273_Campylobacter); %medabs (var=Staphylococcus_epidermidis); %medabs (var=Staphylococcus_epidermidis_0_8); %medabs (var=Streptococcus_agalactiae); 
%medabs (var=Streptococcus_anginosus); %medabs (var=Streptococcus_mitis_0_8); %medabs (var=Streptococcus_salivarius); %medabs (var=Veillonella_tobetsuensis_0_8); 
%medabs (var=uncultured_bacterium_Atopobium);


*With CIs;
%macro medabs (var= );
proc means data=species n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var &var.;
class site time;
output out=tab_sp_absab_temp (drop=_type_ _freq_) median= /autoname;
where &var. > 0 and condom = 1;
run;

proc sort data=tab_sp_absab_temp; by site time; run;
proc transpose data=tab_sp_absab_temp out=tab_sp_absab_temp;
by site time;
run;

data tab_sp_absab_temp; set tab_sp_absab_temp;
taxa = "&var.";
median= COL1;
drop COL1 _NAME_;
run;

proc append data=tab_sp_absab_temp base=tab_sp_absab;
run;
%mend;

*------------------------;
*LRR;
data tab_sp_lrr;
length Taxa $32 Site $8 LR1_2_Median 8 LR2_3_Median 8 LR3_4_Median 8 LR1_4_Median 8 ;
run;

%macro lrr (taxa= );
proc means data=species_long n  q1 median q3 maxdec=3;
title '';
	var LR1_2 LR2_3 LR3_4 LR1_4;
	class site;
	output out=tab_sp_lrr_temp(drop=_type_ _freq_) median=  /autoname;
	where taxa = "&taxa." and site in ("Cervical" "CorSul");
run;

data tab_sp_lrr_temp; set tab_sp_lrr_temp;
taxa = "&taxa.";
run;

proc append data=tab_sp_lrr_temp base=tab_sp_lrr force;
run;
%mend;

*taxa;
%lrr (taxa=Acinetobacter_baumannii); %lrr (taxa=Dialister_micraerophilus); %lrr (taxa=Dialister_propionicifaciens); %lrr (taxa=Dialister_succinatiphilus_0_8); 
%lrr (taxa=Finegoldia_magna); %lrr (taxa=Gardnerella_vaginalis); %lrr (taxa=Lactobacillus_crispatus); %lrr (taxa=Lactobacillus_gasseri); 
%lrr (taxa=Lactobacillus_iners); %lrr (taxa=Lactobacillus_reuteri); %lrr (taxa=Mobiluncus_curtisii); %lrr (taxa=Negativicoccus_succinicivorans); 
%lrr (taxa=Peptoniphilus_asaccharolyticus_0); %lrr (taxa=Peptoniphilus_lacrimalis); %lrr (taxa=Peptostreptococcus_anaerobius); %lrr (taxa=Porphyromonas_asaccharolytica); 
%lrr (taxa=Prevotella_bivia); %lrr (taxa=Prevotella_buccalis); %lrr (taxa=Prevotella_corporis); %lrr (taxa=Prevotella_disiens); %lrr (taxa=Sneathia_sp_Sn35);

*---;
*Condom strata;
data tab_lrr;
length Taxa $32 Site $8 LR1_2_Mean 8 LR2_3_Mean 8 LR3_4_Mean 8 LR1_4_Mean 8 ;
run;

%macro lrr (taxa= );
proc means data=samples_long n  q1 mean q3 maxdec=3;
title '';
	var LR1_2 LR2_3 LR3_4 LR1_4;
	class site;
	output out=tab_lrr_temp(drop=_type_ _freq_) mean=  /autoname;
	where taxa = "&taxa." and site in ("Cervical" "CorSul") and condom = 1;
run;

data tab_lrr_temp; set tab_lrr_temp;
taxa = "&taxa.";
run;

proc append data=tab_lrr_temp base=tab_lrr force;
run;
%mend;

*taxa;
%lrr (taxa=Corynebacterium); %lrr (taxa=Dialister); %lrr (taxa=Finegoldia); %lrr (taxa=Gardnerella); %lrr (taxa=Lactobacillus); 
%lrr (taxa=Mobiluncus); %lrr (taxa=Negativicoccus); 
%lrr (taxa=Peptoniphilus); %lrr (taxa=Peptostreptococcus); %lrr (taxa=Porphyromonas); 
%lrr (taxa=Prevotella); %lrr (taxa=Sneathia); %lrr (taxa=Staphylococcus);

*Species;

data tab_sp_lrr;
length Taxa $32 Site $8 LR1_2_Mean 8 LR2_3_Mean 8 LR3_4_Mean 8 LR1_4_Mean 8 ;
run;

%macro lrr (taxa= );
proc means data=species_long n  q1 mean q3 maxdec=3;
title '';
	var LR1_2 LR2_3 LR3_4 LR1_4;
	class site;
	output out=tab_sp_lrr_temp(drop=_type_ _freq_) mean=  /autoname;
	where taxa = "&taxa." and site in ("Cervical" "CorSul") and condom = 1;
run;

data tab_sp_lrr_temp; set tab_sp_lrr_temp;
taxa = "&taxa.";
run;

proc append data=tab_sp_lrr_temp base=tab_sp_lrr force;
run;
%mend;

*taxa;
%lrr (taxa=Acinetobacter_baumannii); %lrr (taxa=Dialister_micraerophilus); %lrr (taxa=Dialister_propionicifaciens); %lrr (taxa=Dialister_succinatiphilus_0_8); 
%lrr (taxa=Finegoldia_magna); %lrr (taxa=Gardnerella_vaginalis); %lrr (taxa=Lactobacillus_crispatus); %lrr (taxa=Lactobacillus_gasseri); 
%lrr (taxa=Lactobacillus_iners); %lrr (taxa=Lactobacillus_jensenii_0_8); %lrr (taxa=Lactobacillus_reuteri); %lrr (taxa=Mobiluncus_curtisii); %lrr (taxa=Negativicoccus_succinicivorans); 
%lrr (taxa=Peptoniphilus_asaccharolyticus_0); %lrr (taxa=Peptoniphilus_lacrimalis); %lrr (taxa=Peptostreptococcus_anaerobius); %lrr (taxa=Porphyromonas_asaccharolytica); 
%lrr (taxa=Prevotella_bivia); %lrr (taxa=Prevotella_buccalis); %lrr (taxa=Prevotella_corporis); %lrr (taxa=Prevotella_disiens); %lrr (taxa=Prevotella_timonensis); 
%lrr (taxa=Sneathia_sp_Sn35); %lrr (taxa=Staphylococcus_aureus_0_8); %lrr (taxa=Staphylococcus_epidermidis);

*------;

proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var log_std_qty;
class time site condom   ;
run;

proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var log_std_qty;
class time site condom circumcision  ;
format Circumcision Circumcision.;
run;

proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var log_std_qty;
class  site time /* circumcision */;
format Circumcision Circumcision.;
where condom=0;
run;

proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var log_std_qty;
class time site condom circumcision  ;
where site = 'CorSul';
format Circumcision Circumcision.;
run;

proc npar1way data=samples wilcoxon;
var log_std_qty;
class time ;
where site = 'CorSul' and condom = 1 ;
format Circumcision Circumcision.;
run;

proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var log_std_qty;
class time site condom   ;
where site = 'Cervical';
run;

proc npar1way data=samples wilcoxon;
var log_std_qty;
class time ;
where site = 'Cervical' and condom = 0 and time in (1 2)  ;
format Circumcision Circumcision.;
run;

*BASICs / BVABs;
proc npar1way data=secs_analytic wilcoxon;
var l_BVAB;
class time ;
where site = 'CorSul' and condom = 0 and time in (1 4)  ;
format Circumcision Circumcision.;
run;

proc npar1way data=secs_analytic wilcoxon;
var p_BASIC;
class time ;
where site = 'Cervical' and condom = 0 and time in (1 2 )  ;
format Circumcision Circumcision.;
run;

ods graphics on / width = 6in height=6in;

proc sort data=samples; by circumcision  ; run;

proc sgpanel data=samples  ;
panelby time / rows=1 columns=4;
vbox log_std_qty / group = circumcision ;
format Circumcision Circumcision.;
where site = "CorSul";
run;

*Among no condom;
proc sgpanel data=samples  ;
panelby time / rows=1 columns=4;
vbox log_std_qty / group = circumcision ;
format Circumcision Circumcision.;
where site = "CorSul" and condom=0;
run;

proc sgpanel data=samples  ;
panelby time / rows=1 columns=4;
vbox log_std_qty / ;
where site = "Cervical";
run;

proc sgpanel data=samples  ;
panelby time / rows=1 columns=4;
vbox log_std_qty / category = circumcision;
format Circumcision Circumcision.;
where site = "Cervical";
run;

proc npar1way data=samples  wilcoxon;
var log_std_qty ;
class circumcision ;
format Circumcision Circumcision.;
where site = "CorSul" and time=4;
run;

proc univariate data=samples_long ;
var log_T1_2 ;
class site ;
where taxa='std_qty';
run;

*---;

proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var log_std_qty;
class  site F_EthnicityCat;
where time=1;
run;

*No strata;
%macro medabs (var= );
data secs_analytic; set secs_analytic;
l_&var. = log10(&var.+1);
run;

proc means data=secs_analytic n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type among Positives';
var &var. l_&var.;
class  time;
where &var. > 0 and site="Cervical";
run;
%mend;

*Condom;
%macro medabs (var= );
data secs_analytic; set secs_analytic;
l_&var. = log10(&var.+1);
run;

proc means data=secs_analytic n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type among Positives';
var &var. l_&var.;
class time condom;
where &var. > 0 and site="Cervical";
run;

proc npar1way data=secs_analytic wilcoxon;
var l_&var.;
class time;
where condom = 0 and &var. > 0 and site="Cervical";
run;
%mend;

*Cycle (run with same taxa as circ below);
%macro medabs (var= );
proc means data=secs_analytic n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type among Positives';
var &var.;
class cyclephase time;
where &var. > 0 and site="Cervical";
format cyclephase cyclephase.;
run;
%mend;

*Race (run with same taxa as circ below);
%macro medabs (var= );
proc means data=secs_analytic n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type among Positives';
var &var.;
class f_ethnicitycat time;
where &var. > 0 and site="Cervical" and time=1;
run;
%mend;

*BV Status (run with same taxa as circ below);
%macro medabs (var= );
proc means data=secs_analytic n  q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type among Positives';
var &var.;
class nugentbv1_cat time;
where &var. > 0 and site="Cervical" ;
format cyclephase cyclephase.;
run;
%mend;

*Circ;
%macro medabs (var= );
data secs_analytic; set secs_analytic;
l_&var. = log10(&var.+1);
run;

proc means data=secs_analytic n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type among Positives';
var &var. l_&var.;
class circumcision time;
where &var. > 0 and site="Cervical";
format Circumcision Circumcision.;
run;
%mend;

%medabs (var=Corynebacterium); 
%medabs (var=Dialister); 
%medabs (var=Dialister_micraerophilus); 
%medabs (var=Dialister_propionicifaciens); 
%medabs (var=Dialister_succinatiphilus_0_8);
%medabs (var=Finegoldia_magna); 
%medabs (var=Gardnerella);   
%medabs (var=Gardnerella_vaginalis);
%medabs (var=Gardnerella_vaginalis_0_8);
%medabs (var=Lactobacillus); 
%medabs (var=Lactobacillus_crispatus); 
%medabs (var=Lactobacillus_crispatus_0_8); 
%medabs (var=Lactobacillus_gasseri); 
%medabs (var=Lactobacillus_iners); 
%medabs (var=Lactobacillus_reuteri);
%medabs (var=Mobiluncus); 
%medabs (var=Peptostreptococcus_anaerobius);	
%medabs (var=Porphyromonas); 
%medabs (var=Prevotella); 
%medabs (var=Prevotella_bivia); 
%medabs (var=Prevotella_disiens); 
%medabs (var=Sneathia);

*Total abundance by circ;
proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var log_std_qty;
class  site circumcision;
format Circumcision Circumcision.;
where time=1;
run;

proc means data=samples n mean q1 median q3 ;
title 'Overview of All Taxa - Absolute Abundance by Time and Sample Type';
var log_std_qty;
class  site condom;
where time=1;
run;

proc npar1way data=samples wilcoxon;
var std_qty;
class Circumcision;
where site="CorSul" and time=1;
format Circumcision Circumcision.;
run;

proc npar1way data=samples wilcoxon;
var std_qty;
class condom;
where site="CorSul" and time=1;
run;

proc npar1way data=samples wilcoxon;
var std_qty;
class Circumcision;
where site="CorSul" and time=1 and condom=0;
run;

*Total abundance by cycle phase;
proc npar1way data=secs_analytic wilcoxon;
var prevotella_bivia;
class cyclephase;
where site="Cervical" and time=1 ;
run;

*Total abundance by pH;
proc npar1way data=secs_analytic wilcoxon;
var log_std_qty;
class pH_high;
where site="Cervical" and time=1 ;
run;


proc sgpanel data=secs_analytic;
panelby time / columns=4 rows=1;
vbox log_std_qty / category=pH_high;
where site="Cervical" ;
run;

title;

*Total abundance by race;
proc npar1way data=secs_analytic wilcoxon;
var log_std_qty;
class F_ethnicitycat;
where site="Cervical" and time=1 ;
run;

proc sgplot data=secs_analytic;
vbox log_std_qty / category=F_ethnicitycat;
where site="Cervical" and time=1;
run;

proc npar1way data=secs_analytic wilcoxon;
var mobiluncus;
class F_ethnicitycat;
where site="Cervical" and time=1 ;
run;

*Total abundance by BV;
proc npar1way data=secs_analytic wilcoxon;
var log_std_qty;
class NugentBV1_Cat;
where site="Cervical" and time=1 ;
run;

proc npar1way data=secs_analytic wilcoxon;
var dialister;
class NugentBV1_Cat;
where site="Cervical" and time=1 ;
run;

proc sgplot data=secs_analytic;
vbox log_std_qty / category=NugentBV1_Cat;
where site="Cervical" and time=1;
run;

*Wilcoxon test for abs abundances;
%macro wilcoxon (taxa= , class=);
proc npar1way data=secs_analytic wilcoxon;
	var &taxa. ;
	class &class.;
where site="Cervical" and time=1;
run;
%mend;

%wilcoxon (taxa=Corynebacterium, class=circumcision); 
%wilcoxon (taxa=Dialister, class=circumcision); 
%wilcoxon (taxa=Dialister_micraerophilus, class=circumcision); 
%wilcoxon (taxa=Dialister_propionicifaciens, class=circumcision); 
%wilcoxon (taxa=Dialister_succinatiphilus_0_8, class=circumcision);
%wilcoxon (taxa=Finegoldia_magna, class=circumcision); 
%wilcoxon (taxa=Gardnerella, class=circumcision);   
%wilcoxon (taxa=Gardnerella_vaginalis, class=circumcision);
%wilcoxon (taxa=Lactobacillus, class=circumcision); 
%wilcoxon (taxa=Lactobacillus_crispatus, class=circumcision); 
%wilcoxon (taxa=Lactobacillus_crispatus_0_8, class=circumcision); 
%wilcoxon (taxa=Lactobacillus_gasseri, class=circumcision); 
%wilcoxon (taxa=Lactobacillus_iners, class=circumcision); 
%wilcoxon (taxa=Lactobacillus_reuteri, class=circumcision);
%wilcoxon (taxa=Mobiluncus, class=circumcision); 
%wilcoxon (taxa=Peptostreptococcus_anaerobius, class=circumcision);	
%wilcoxon (taxa=Porphyromonas, class=circumcision); 
%wilcoxon (taxa=Prevotella, class=circumcision); 
%wilcoxon (taxa=Prevotella_bivia, class=circumcision); 
%wilcoxon (taxa=Prevotella_disiens, class=circumcision); 
%wilcoxon (taxa=Sneathia, class=circumcision);

*-;
*Significance testing;

%macro absab (taxa= , site=, value= );
proc means data=samples_long n mean median std maxdec=4;
title '';
	var log_T1 log_T2 log_T3 log_T4 log_T1_2 log_T1_3 log_T1_4;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;

proc univariate data=samples_long ;
	var log_T1_2 log_T1_3 log_T1_4  ;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;

%mend;

%absab (taxa=Corynebacterium, site=CorSul, value=0);
%absab (taxa=Dialister, site=CorSul, value=1);
%absab (taxa=Finegoldia, site=CorSul, value=1);
%absab (taxa=Gardnerella, site=CorSul, value=1);
%absab (taxa=Lactobacillus, site=CorSul, value=1);
%absab (taxa=Mobiluncus, site=CorSul, value=1);
%absab (taxa=Negativicoccus, site=CorSul, value=1);
%absab (taxa=Peptoniphilus, site=CorSul, value=1);
%absab (taxa=Peptostreptococcus, site=CorSul, value=1);
%absab (taxa=Porphyromonas, site=CorSul, value=1);
%absab (taxa=Prevotella, site=CorSul, value=1);
%absab (taxa=Staphylococcus, site=CorSul, value=1);
%absab (taxa=std_qty, site=CorSul, value=0);
%absab (taxa=std_qty, site=CorSul, value=1);


%absab (taxa=Corynebacterium, site=Cervical, value=0);
%absab (taxa=Dialister, site=Cervical, value=1);
%absab (taxa=Finegoldia, site=Cervical, value=1);
%absab (taxa=Gardnerella, site=Cervical, value=0);
%absab (taxa=Lactobacillus, site=Cervical, value=0);
*%absab (taxa=Mobiluncus, site=Cervical, value=1);
*%absab (taxa=Negativicoccus, site=Cervical, value=1);
%absab (taxa=Peptoniphilus, site=Cervical, value=1);
%absab (taxa=Peptostreptococcus, site=Cervical, value=1);
%absab (taxa=Porphyromonas, site=Cervical, value=1);
%absab (taxa=Prevotella, site=Cervical, value=0);
%absab (taxa=Staphylococcus, site=Cervical, value=1);

*Significance testing;
*Species;
%macro absab (taxa= , site=, value= );
proc means data=species_long n  mean std maxdec=4;
title "&taxa.";
	var log_T1 log_T2 log_T3 log_T4 ;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;

proc univariate data=species_long ;
	var T1_2 T1_3 T1_4 ;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
run;
%mend;
%absab (taxa=Dialister_micraerophilus, site=CorSul, value=0);
%absab (taxa=Dialister_propionicifaciens, site=CorSul, value=0);
%absab (taxa=Dialister_succinatiphilus_0_8, site=CorSul, value=0);
%absab (taxa=Finegoldia_magna, site=CorSul, value=0);
%absab (taxa=Gardnerella_vaginalis, site=CorSul, value=0);

%absab (taxa=Lactobacillus_crispatus, site=CorSul, value=0);
%absab (taxa=Lactobacillus_gasseri, site=CorSul, value=0);
%absab (taxa=Lactobacillus_iners, site=CorSul, value=0);
%absab (taxa=Lactobacillus_jensenii_0_8, site=CorSul, value=0);
%absab (taxa=Lactobacillus_reuteri, site=CorSul, value=0);
%absab (taxa=Mobiluncus_curtisii, site=CorSul, value=0);
%absab (taxa=Negativicoccus_succinicivorans, site=CorSul, value=0);

%absab (taxa=Peptoniphilus_asaccharolyticus_0, site=CorSul, value=0);
%absab (taxa=Peptoniphilus_lacrimalis, site=CorSul, value=0);
%absab (taxa=Peptostreptococcus_anaerobius, site=CorSul, value=0);
%absab (taxa=Porphyromonas_asaccharolytica, site=CorSul, value=0);
%absab (taxa=Prevotella_bivia, site=CorSul, value=0);
%absab (taxa=Prevotella_buccalis, site=CorSul, value=0);
%absab (taxa=Prevotella_corporis, site=CorSul, value=0);
%absab (taxa=Prevotella_disiens, site=CorSul, value=0);
%absab (taxa=Prevotella_timonensis, site=CorSul, value=0);
%absab (taxa=Staphylococcus_aureus_0_8, site=CorSul, value=0);
%absab (taxa=Staphylococcus_epidermidis, site=CorSul, value=0);

*Cerv;
%absab (taxa=Dialister_micraerophilus, site=Cervical, value=0);
%absab (taxa=Dialister_propionicifaciens, site=Cervical, value=0);
%absab (taxa=Dialister_succinatiphilus_0_8, site=Cervical, value=0);
%absab (taxa=Finegoldia_magna, site=Cervical, value=0);
%absab (taxa=Gardnerella_vaginalis, site=Cervical, value=0);

%absab (taxa=Lactobacillus_crispatus, site=Cervical, value=0);
%absab (taxa=Lactobacillus_gasseri, site=Cervical, value=0);
%absab (taxa=Lactobacillus_iners, site=Cervical, value=0);
%absab (taxa=Lactobacillus_jensenii_0_8, site=Cervical, value=0);
%absab (taxa=Lactobacillus_reuteri, site=Cervical, value=0);
%absab (taxa=Mobiluncus_curtisii, site=Cervical, value=0);
%absab (taxa=Negativicoccus_succinicivorans, site=Cervical, value=0);

%absab (taxa=Peptoniphilus_asaccharolyticus_0, site=Cervical, value=0);
%absab (taxa=Peptoniphilus_lacrimalis, site=Cervical, value=0);
%absab (taxa=Peptostreptococcus_anaerobius, site=Cervical, value=0);
%absab (taxa=Porphyromonas_asaccharolytica, site=Cervical, value=0);
%absab (taxa=Prevotella_bivia, site=Cervical, value=0);
%absab (taxa=Prevotella_buccalis, site=Cervical, value=0);
*%absab (taxa=Prevotella_corporis, site=Cervical, value=0);
%absab (taxa=Prevotella_disiens, site=Cervical, value=0);
%absab (taxa=Prevotella_timonensis, site=Cervical, value=0);
%absab (taxa=Staphylococcus_aureus_0_8, site=Cervical, value=0);
%absab (taxa=Staphylococcus_epidermidis, site=Cervical, value=0);

*Species, by circ status among condomless;
*Species;
%macro absab (taxa= , site=, value= );
proc means data=species_long n  mean std median maxdec=4;
title "&taxa.";
	var log_T1 log_T2 log_T3 log_T4 ;
	class circumcision;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
	format circumcision circumcision.;
run;

proc univariate data=species_long ;
	var T1_2 T1_3 T1_4 ;
	class circumcision;
	where taxa = "&taxa." and site = "&site." and condom = &value.;
	format circumcision circumcision.;
run;
%mend;

%absab (taxa=Dialister_micraerophilus, site=CorSul, value=0);
%absab (taxa=Dialister_propionicifaciens, site=CorSul, value=0);
%absab (taxa=Dialister_succinatiphilus_0_8, site=CorSul, value=0);
%absab (taxa=Finegoldia_magna, site=CorSul, value=0);
%absab (taxa=Gardnerella_vaginalis, site=CorSul, value=0);

%absab (taxa=Lactobacillus_crispatus, site=CorSul, value=0);
%absab (taxa=Lactobacillus_gasseri, site=CorSul, value=0);
%absab (taxa=Lactobacillus_iners, site=CorSul, value=0);
%absab (taxa=Lactobacillus_jensenii_0_8, site=CorSul, value=0);
%absab (taxa=Lactobacillus_reuteri, site=CorSul, value=0);
%absab (taxa=Mobiluncus_curtisii, site=CorSul, value=0);
%absab (taxa=Negativicoccus_succinicivorans, site=CorSul, value=0);

%absab (taxa=Peptoniphilus_asaccharolyticus_0, site=CorSul, value=0);
%absab (taxa=Peptoniphilus_lacrimalis, site=CorSul, value=0);
%absab (taxa=Peptostreptococcus_anaerobius, site=CorSul, value=0);
%absab (taxa=Porphyromonas_asaccharolytica, site=CorSul, value=0);
%absab (taxa=Prevotella_bivia, site=CorSul, value=0);
%absab (taxa=Prevotella_buccalis, site=CorSul, value=0);
%absab (taxa=Prevotella_corporis, site=CorSul, value=0);
%absab (taxa=Prevotella_disiens, site=CorSul, value=0);
%absab (taxa=Prevotella_timonensis, site=CorSul, value=0);
%absab (taxa=Staphylococcus_aureus_0_8, site=CorSul, value=0);
%absab (taxa=Staphylococcus_epidermidis, site=CorSul, value=0);

*Cerv;
%absab (taxa=Dialister_micraerophilus, site=Cervical, value=0);
%absab (taxa=Dialister_propionicifaciens, site=Cervical, value=0);
%absab (taxa=Dialister_succinatiphilus_0_8, site=Cervical, value=0);
%absab (taxa=Finegoldia_magna, site=Cervical, value=0);
%absab (taxa=Gardnerella_vaginalis, site=Cervical, value=0);

%absab (taxa=Lactobacillus_crispatus, site=Cervical, value=0);
%absab (taxa=Lactobacillus_gasseri, site=Cervical, value=0);
%absab (taxa=Lactobacillus_iners, site=Cervical, value=0);
%absab (taxa=Lactobacillus_jensenii_0_8, site=Cervical, value=0);
%absab (taxa=Lactobacillus_reuteri, site=Cervical, value=0);
%absab (taxa=Mobiluncus_curtisii, site=Cervical, value=0);
%absab (taxa=Negativicoccus_succinicivorans, site=Cervical, value=0);

%absab (taxa=Peptoniphilus_asaccharolyticus_0, site=Cervical, value=0);
%absab (taxa=Peptoniphilus_lacrimalis, site=Cervical, value=0);
%absab (taxa=Peptostreptococcus_anaerobius, site=Cervical, value=0);
%absab (taxa=Porphyromonas_asaccharolytica, site=Cervical, value=0);
%absab (taxa=Prevotella_bivia, site=Cervical, value=0);
%absab (taxa=Prevotella_buccalis, site=Cervical, value=0);
*%absab (taxa=Prevotella_corporis, site=Cervical, value=0);
%absab (taxa=Prevotella_disiens, site=Cervical, value=0);
%absab (taxa=Prevotella_timonensis, site=Cervical, value=0);
%absab (taxa=Staphylococcus_aureus_0_8, site=Cervical, value=0);
%absab (taxa=Staphylococcus_epidermidis, site=Cervical, value=0);

*Total density by circ;
proc means data=samples_long n  mean std median maxdec=4;
title "std_qty";
	var log_T1 log_T2 log_T3 log_T4 ;
	class circumcision;
	where taxa = "std_qty" and site = "CorSul" and condom = 0;
	format circumcision circumcision.;
run;

proc univariate data=samples_long ;
	var T1_2 T1_3 T1_4 ;
	class circumcision;
	where taxa = "std_qty" and site = "CorSul" /*and condom = 0*/;
	format circumcision circumcision.;
run;

*--------------;
*looking at skew;
proc univariate data=samples ;
var log_std_qty ;
histogram log_std_qty;
class time site ;
run;

proc univariate data=samples ;
var log_prevotella ;
histogram log_prevotella;
where site = "CorSul";
run;

proc univariate data=samples ;
var log_lactobacillus ;
histogram log_lactobacillus;
where site = "Cervical";
run;

ods rtf close;

*=====================================;
*Absolute Abundance Change over Time Figures;
title;
proc sgplot data=samples;
vbox log_std_qty / group=time;
where site='CorSul';
run;

proc freq data=samples;
table site * condom * circumcision;
where time=1;
run;

proc sgpanel data=samples;
panelby condom circumcision;
vbox log_std_qty / group=time;
by site;
run;

proc sgpanel data=samples;
panelby  circumcision;
vbox log_std_qty / group=time;
by site;
where condom=0;
format circumcision circumcision.;
run;

*Sex type;
proc sgpanel data=samples;
panelby sex_type / columns=3;
vbox log_std_qty / category=time;
by site;
format sex_type sex_type.;
run;

ods graphics on / width = 11in height=6in;

proc sort data=samples; by time; run;
proc sgpanel data=samples;
panelby sex_type circumcision / rows=1 columns=6;
vbox log_std_qty / category=time;
by site;
*where condom=0;
format circumcision circumcision. sex_type sex_type.;
run;

proc means data=samples median n;
var log_std_qty;
class time;
where site='CorSul';
run;

*------------------;

proc sort data=samples_long; by site; run;

%macro diff (taxa= ,var= );
proc freq data=samples_long;
title 'CorSul';
table prev_T1 prev_T2 prev_T3 prev_T4;
where taxa = &taxa. and site = "CorSul";
run;

proc freq data=samples_long;
title 'Cervical';
table prev_T1 prev_T2 prev_T3 prev_T4;
where taxa = &taxa. and site = "Cervical";
run;

proc means data=samples_long n  q1 median q3 maxdec=0;
title '';
	var T1 T2 T3 T4 T1_2 T2_3 T3_4 ;
	class site;
	where taxa = &taxa.;
run;

proc sgplot data=samples_long;
	title 'Difference over time 1 to 2 - &taxa.';
	vbox log_T1_2 / group =  condom;
	where taxa = &taxa. ;
	by site;
run;

proc sgplot data=samples_long;
	title 'Difference over time 2 to 3 - &taxa.';
	vbox log_T2_3 / group =  condom;
	where taxa = &taxa. ;
	by site;
run;

proc sgplot data=samples_long;
	title 'Difference over time 3 to 4 - &taxa.';
	vbox log_T3_4 / group = condom;
	where taxa = &taxa. ;
	by site;
run;

proc sgplot data=samples_long;
	title 'Difference over time 1 to 2 - &taxa.';
	vbox log_T1_2 / group = circumcision;
	yaxis min=-10 max=10;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and condom = 0;
	format circumcision circumcision.;
	by site;
run;

proc sgplot data=samples_long;
	title 'Difference over time 2 to 3 - &taxa.';
	vbox log_T2_3 / group =   circumcision;
	yaxis min=-10 max=10;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and condom = 0;
	format circumcision circumcision.;
	by site;
run;

proc sgplot data=samples_long;
	title 'Difference over time 3 to 4 - &taxa.';
	vbox log_T3_4 / group =   circumcision;
	yaxis min=-10 max=10;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and condom = 0;
	format circumcision circumcision.;
	by site;
run;
%mend;

%diff (taxa="Lactobacillus");
%diff (taxa="Gardnerella");
%diff (taxa="Corynebacterium");
%diff (taxa="Prevotella");
%diff (taxa="Finegoldia");
%diff (taxa="Peptoniphilus");
%diff (taxa="Peptostreptococcus");

*---------------------;

*---------------------;
*Species;

proc sort data=species_long; by site; run;
proc sort data=species_rel_long; by site; run;

*-------------------;

%macro diff (taxa= ,var= );
proc freq data=species_long;
title 'CorSul';
table prev_T1 prev_T2 prev_T3 prev_T4;
where taxa = &taxa. and site = "CorSul";
run;

proc freq data=species_long;
title 'Cervical';
table prev_T1 prev_T2 prev_T3 prev_T4;
where taxa = &taxa. and site = "Cervical";
run;

proc means data=species_long n  q1 median q3 maxdec=0;
title '';
	var T1 T2 T3 T4 T1_2 T2_3 T3_4 ;
	class site;
	where taxa = &taxa.;
run;

proc means data=species_rel_long n  q1 mean q3 maxdec=3;
title 'Relative abundance';
	var T1 T2 T3 T4 T1_2 T2_3 T3_4 ;
	class site;
	where taxa = &taxa.;
run;

proc sgplot data=species_long;
	title 'Difference over time 1 to 2 - &taxa. ';
	vbox lr1_2 / group =  condom;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. ;
	by site;
run;

proc sgplot data=species_long;
	title 'Difference over time 2 to 3 - &taxa.';
	vbox lr2_3 / group =  condom;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. ;
	by site;
run;

proc sgplot data=species_long;
	title 'Difference over time 3 to 4 - &taxa.';
	vbox lr3_4 / group = condom;
	where taxa = &taxa. ;
	by site;
run;

proc sgplot data=species_long;
	title 'Difference over time 1 to 2 - &taxa.';
	vbox lr1_2 / group = circumcision;
	yaxis min=-10 max=10;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and condom = 0;
	format circumcision circumcision.;
	by site;
run;

proc sgplot data=species_long;
	title 'Difference over time 2 to 3 - &taxa.';
	vbox lr2_3 / group =   circumcision;
	yaxis min=-10 max=10;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and condom = 0;
	format circumcision circumcision.;
	by site;
run;

proc sgplot data=species_long;
	title 'Difference over time 3 to 4 - &taxa.';
	vbox lr3_4 / group =   circumcision;
	yaxis min=-10 max=10;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and condom = 0;
	format circumcision circumcision.;
	by site;
run;
%mend;

%diff (taxa="Gardnerella_vaginalis");
%diff (taxa="Lactobacillus_crispatus");
%diff (taxa="Lactobacillus_iners");

%diff (taxa="Prevotella_bivia");
%diff (taxa="Peptostreptococcus_anaerobius");
%diff (taxa="Dialister_micraerophilus");
%diff (taxa="Dialister_propionicifaciens");
%diff (taxa="Dialister_succinatiphilus_0_8");
%diff (taxa="Gardnerella_vaginalis"); %diff (taxa="Lactobacillus_crispatus"); %diff (taxa="Lactobacillus_iners");

*By Cycle;

ods graphics on / width=3in height=6in;

proc sort data=species_long; by cyclephase condom circumcision; run;
proc sort data=species_rel_long; by cyclephase condom circumcision; run;

%macro diff (taxa= ,var= );
proc freq data=species_long;
table cyclephase * (Prev_T1 Prev_T2 Prev_T3 Prev_T4) * (condom circumcision) / norow nocol nopercent;
	where taxa = &taxa. and site="Cervical";
run;

proc means data=species_long n  q1 median q3 maxdec=0;
title '';
	var T1 T2 T3 T4 T1_2 T2_3 T3_4 ;
	class site cyclephase;
	where taxa = &taxa. and site="Cervical";
run;

proc means data=species_rel_long n  q1 mean q3 maxdec=3;
title 'Proportional abundance';
	var T1 T2 T3 T4 T1_2 T2_3 T3_4 ;
	class site cyclephase;
	where taxa = &taxa. and site="Cervical";
run;

proc freq data=species_long;
table Prev_T1 Prev_T2 Prev_T3 Prev_T4;
where taxa = &taxa. and site="Cervical";
run;

proc sgpanel data=species_long;
	title "Difference over time 1 to 2 - &taxa.";
	panelby cyclephase condom;
	vbox lr1_2 / group=condom;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and site="Cervical" and cyclephase ^= .;
run;

proc sgpanel data=species_long;
	title "Difference over time 2 to 3 - &taxa.";
	panelby cyclephase condom;
	vbox lr2_3 / group =  condom;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and site="Cervical" and cyclephase ^= .;
run;

proc sgpanel data=species_long;
	panelby cyclephase condom;
	title "Difference over time 3 to 4 - &taxa.";
	vbox lr3_4 / group = condom ;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and site="Cervical" and cyclephase ^= .;
run;

proc sgpanel data=species_long;
	panelby cyclephase condom;
	title "Difference over time 1 to 4 - &taxa.";
	vbox lr1_4 / group = condom ;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and site="Cervical" and cyclephase ^= .;
run;

proc sgpanel data=species_long;
	panelby cyclephase circumcision;
	title "Difference over time 1 to 2 - &taxa.";
	vbox lr1_2 / group = circumcision;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and condom = 0 and site="Cervical" and cyclephase ^= .;
	format circumcision circumcision.;
run;

proc sgpanel data=species_long;
	title "Difference over time 2 to 3 - &taxa.";
	panelby cyclephase circumcision;
	vbox lr2_3 / group =   circumcision;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and condom = 0 and site="Cervical" and cyclephase ^= .;
	format circumcision circumcision.;
run;

proc sgpanel data=species_long;
	title "Difference over time 3 to 4 - &taxa.";
	panelby cyclephase circumcision;
	vbox lr3_4 / group =   circumcision;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and condom = 0 and site="Cervical" and cyclephase ^= .;
	format circumcision circumcision.;
run;

proc sgpanel data=species_long;
	title "Difference over time 1 to 4 - &taxa.";
	panelby cyclephase circumcision;
	vbox lr1_4 / group =   circumcision;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	where taxa = &taxa. and condom = 0 and site="Cervical" and cyclephase ^= .;
	format circumcision circumcision.;
run;
%mend;

proc sgpanel data=species_long;
	title "Difference over time 1 to 4 - &taxa.";
	panelby cyclephase /*circumcision*/;
	scatter x= circumcision y=log_T1_4 / group=circumcision jitter;
	vbox lr1_4 / group =   circumcision;
	   refline 0 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
	  
	where taxa = "Gardnerella_vaginalis" and condom = 0 and site="Cervical" and cyclephase ^= .;
	format circumcision circumcision.;
run;

%diff (taxa="Gardnerella_vaginalis");
%diff (taxa="Lactobacillus_crispatus");
%diff (taxa="Lactobacillus_iners");

%diff (taxa="Prevotella_bivia");
%diff (taxa="Peptostreptococcus_anaerobius");
%diff (taxa="Dialister_micraerophilus");
%diff (taxa="Dialister_propionicifaciens");
%diff (taxa="Dialister_succinatiphilus_0_8");
%diff (taxa="Gardnerella_vaginalis"); %diff (taxa="Lactobacillus_crispatus"); %diff (taxa="Lactobacillus_iners");

title;

proc sgplot data=samples;
vbox log_std_qty / category=cyclephase;
yaxis min=0;
where site = "Cervical" and time=1 and cyclephase ^= .;
run;

%macro vbox (var= );
proc sgpanel data=species;
panelby cyclephase;
vbox &var. / category=time;
where &var. > 0 and site="Cervical";
format cyclephase cyclephase.;
run;
%mend;

%vbox (var= log_std_qty);
%vbox (var= log_l_crispatus);
%vbox (var= log_g_vaginalis);
%vbox (var= log_p_bivia);
%vbox (var= log_d_micraerophilus);


proc sgpanel data=samples;
panelby cyclephase;
histogram phn ;
where site="Cervical" and time=1;
run;

*--;
*Log response ratios;
*Genus;
%macro lrr (taxa= );
proc sgplot data=samples_long;
title "&taxa.";
vbox lr1_2 / category = site;
yaxis min=-8 max=8 grid values=(-8 -6 -4 -2 0 2 4 6 8);
refline 0 / axis=y;
where taxa = &taxa.;
run;
proc sgplot data=samples_long;
vbox lr2_3 / category = site; 
yaxis min=-8 max=8 grid values=(-8 -6 -4 -2 0 2 4 6 8);
refline 0 / axis=y;
where taxa = &taxa.;
run;
proc sgplot data=samples_long;
vbox lr3_4 / category = site;
yaxis min=-8 max=8 grid values=(-8 -6 -4 -2 0 2 4 6 8);
refline 0 / axis=y;
where taxa = &taxa.;
run;
proc sgplot data=samples_long;
vbox lr1_4 / category = site;
yaxis min=-8 max=8 grid values=(-8 -6 -4 -2 0 2 4 6 8);
refline 0 / axis=y;
where taxa = &taxa.;
run;

proc means data=samples_long maxdec=2;
var lr1_2 lr2_3 lr3_4 lr1_4 ;
class site;
where taxa = &taxa.;
run;
title;
%mend;

%lrr (taxa="Corynebacterium");
%lrr (taxa="Sneathia");


*Species;
%macro lrr (taxa= );
proc sgplot data=species_long;
title "&taxa.";
vbox lr1_2 / category = site;
yaxis min=-8 max=8 grid values=(-8 -6 -4 -2 0 2 4 6 8);
refline 0 / axis=y;
where taxa = &taxa.;
run;
proc sgplot data=species_long;
vbox lr2_3 / category = site; 
yaxis min=-8 max=8 grid values=(-8 -6 -4 -2 0 2 4 6 8);
refline 0 / axis=y;
where taxa = &taxa.;
run;
proc sgplot data=species_long;
vbox lr3_4 / category = site;
yaxis min=-8 max=8 grid values=(-8 -6 -4 -2 0 2 4 6 8);
refline 0 / axis=y;
where taxa = &taxa.;
run;
proc sgplot data=species_long;
vbox lr1_4 / category = site;
yaxis min=-8 max=8 grid values=(-8 -6 -4 -2 0 2 4 6 8);
refline 0 / axis=y;
where taxa = &taxa.;
run;

proc means data=species_long maxdec=2;
var lr1_2 lr2_3 lr3_4 lr1_4 ;
class site;
where taxa = &taxa.;
run;
title;
%mend;

%lrr (taxa="Dialister_micraerophilus");
%lrr (taxa="Dialister_propionicifaciens");
%lrr (taxa="Dialister_succinatiphilus_0_8");

%lrr (taxa="Finegoldia_magna");
%lrr (taxa="Gardnerella_vaginalis");

%lrr (taxa="Lactobacillus_crispatus");
%lrr (taxa="Lactobacillus_gasseri");
%lrr (taxa="Lactobacillus_iners"); 
%lrr (taxa="Lactobacillus_reuteri");

%lrr (taxa="Mobiluncus_curtisii");

%lrr (taxa="Peptoniphilus_asaccharolyticus_0");
%lrr (taxa="Peptoniphilus_lacrimalis");
%lrr (taxa="Peptoniphilus_timonensis_JC401_0");
%lrr (taxa="Porphyromonas_asaccharolytica");

%lrr (taxa="Prevotella_bivia");
%lrr (taxa="Prevotella_buccalis");
%lrr (taxa="Prevotella_corporis");
%lrr (taxa="Prevotella_disiens");

%lrr (taxa="Peptostreptococcus_anaerobius");



*----------------------------------;

proc sort data=samples; by site time; run;

proc freq data=samples;
table condom * circumcision / norow nopercent chisq;
by site;
where time = 1 ;
format circumcision circumcision.;
run;

proc means data=samples n median;
var log_std_qty;
class site time condom ;
run;
proc means data=samples n median;
var log_std_qty;
class site time condom circumcision;
run;

ods graphics on / width=4in;
ods graphics on / height=6in;

%macro medians (var= );
proc sgplot data=samples;
	title "Difference over time - &var.";
	vbox log_&var. / group = time;
	by site;
run;

proc freq data=samples; 
table condom * site * time / norow nocol nopercent;
run;

proc sgpanel data=samples;
	panelby condom /  sort = DESCFORMAT novarname;
	title "Difference over time - &var.";
	vbox log_&var. / group = time;
	by site;
	where site ^= '';
	format circumcision circumcision.;
run;

proc freq data=samples; 
table condom * circumcision * site * time / norow nocol nopercent;
*where condom = 0;
run;

proc sgpanel data=samples;
	panelby condom circumcision / sort = DESCFORMAT  novarname;
	title "Difference over time - &var.";
	vbox log_&var. / group = time;
	by site;;
	where condom = 0 and site ^= '';
	format circumcision circumcision.;
run;

%mend;

%medians (var=lactobacillus);
%medians (var=Gardnerella);
%medians (var=Corynebacterium);
%medians (var=Prevotella);
%medians (var=Finegoldia);
%medians (var=Peptoniphilus);

*-----;
*Species;

%macro medians_sp (var= );
data species_plot; set species;
l_&var. = log10(&var. + 1);
run;

proc sort data=species_plot; by site condom; run;

proc sgplot data=species_plot;
	title "Difference over time - &var.";
	vbox l_&var. / group = time;
	by site;
run;

proc freq data=species_plot; 
table condom * site * time / norow nocol nopercent;
run;

proc sgpanel data=species_plot;
	panelby condom /  sort = DESCFORMAT novarname;
	title "Difference over time - &var.";
	vbox l_&var. / group = time;
	by site;
	where site ^= '';
	format circumcision circumcision.;
run;

proc freq data=species; 
table condom * circumcision * site * time / norow nocol nopercent;
*where condom = 0;
run;

proc sgplot data=species_plot;
   series x=time y=l_&var. / group=id  break 
        transparency=0.7 lineattrs=(pattern=solid)
        tip=(condom);
   xaxis display=(nolabel);
   keylegend / type=linecolor title="";
   by site condom;
run;

proc sort data=species_plot; by site circumcision; run;
proc sgplot data=species_plot;
   series x=time y=l_&var. / group=id  break 
        transparency=0.7 lineattrs=(pattern=solid)
        tip=(condom);
   xaxis display=(nolabel) values=(1 2 3 4);
   keylegend / type=linecolor title="";
   by site;
   where condom = 0;
   format circumcision circumcision.;
run;

proc sgpanel data=species_plot;
	panelby condom circumcision / sort = DESCFORMAT  novarname;
	title "Difference over time - &var.";
	vbox l_&var. / group = time;
	by site;;
	where condom = 0 and site ^= '';
	format circumcision circumcision.;
run;

%mend;

%medians_sp (var=prevotella_bivia);
%medians_sp (var=peptostreptococcus_anaerobius);
%medians_sp (var=dialister_micraerophilus);

%medians (var=Gardnerella);

*-----------;
*Heatmaps;
%macro rel (var=);
title "&var.";
proc means data=species_rel_long n mean;
var t1_2 t2_3 t3_4 t1_4;
class condom;
where taxa = &var. and site="Cervical";
run;
%mend;

%rel (var = "Lactobacillus_crispatus");
%rel (var = "Lactobacillus_iners");
%rel (var = "Lactobacillus_reuteri");
%rel (var = "Gardnerella_vaginalis");
%rel (var = "Dialister_propionicifaciens");
%rel (var = "Peptostreptococcus_anaerobius");
%rel (var = "Prevotella_bivia");

%macro abs (var=);
title "&var.";
proc means data=species_long n mean;
var lr1_2 lr2_3 lr3_4 lr1_4;
class condom;
where taxa = &var. and site="Cervical";
run;
%mend;

ods graphics off;
proc sgplot data=species_rel;
scatter x=time y=lactobacillus_iners / group=condom jitter ;
vbox lactobacillus_iners / category = time group=condom transparency=0.5;
where site="Cervical";
run;
proc sgplot data=species;
scatter x=time y=l_lactobacillus_iners / group=condom jitter ;
vbox l_lactobacillus_iners / category = time group=condom transparency=0.5;
where site="Cervical";
run;
proc print data=species_long;
var taxa id log_T2 log_T3 log_T4 log_T2_3 log_T3_4;
where site = "Cervical" and taxa = "Lactobacillus_iners";
run;

%abs (var = "Lactobacillus_crispatus");
%abs (var = "Lactobacillus_iners");
%abs (var = "Lactobacillus_reuteri");
%abs (var = "Gardnerella_vaginalis");
%abs (var = "Dialister_propionicifaciens");
%abs (var = "Peptostreptococcus_anaerobius");
%abs (var = "Prevotella_bivia");

*-----------------------;
*Gardnerella eval;
proc means data=samples maxdec=2;
var log_gardnerella;
class pHn site time;
where condom = 0 and site="Cervical";
run;

proc univariate data=samples_long;
var log_T1_4;
class time;
where condom = 0 and site = "Cervical" and taxa="Gardnerella";
run;

proc univariate data=samples_long;
var lr1_4;
class time;
where condom = 0 and site = "Cervical" and taxa="Gardnerella";
run;

proc sgplot data=samples;
vbox log_gardnerella / category=time;
scatter x=time y=log_gardnerella / jitter;
where condom = 0 and site = "Cervical";
run;

proc means data=samples_long;
var lr1_4;
where condom = 0 and site = "Cervical" and taxa="Gardnerella";
run;

proc means data=samples_long;
var lr1_4;
class sex_type;
where condom = 0 and site = "Cervical" and taxa="Gardnerella";
run;

proc means data=samples_long;
var lr1_4;
class sex_type;
where  site = "Cervical" and taxa="Gardnerella";
run;

proc sgplot data=samples_long;
vbox lr1_4 ;
where condom = 0 and site = "Cervical" and taxa="Gardnerella";
run;

data samples_long; set samples_long;
	*strict, among condomless;
	if Sex_Type = 1 then SType=1; else
	if Sex_Type = 2 then SType=0;

	*group in condom;
	if Sex_Type = 1 then SType2=1; else
	if Sex_Type in (2 3) then SType2=0;

	if pH1_2 < 1 then pH_incr = 0; else
	if pH1_2 >= 1 then pH_incr = 1; 

*1 = in, 2=out or condom;
run;

data species_long; set species_long;
	*strict, among condomless;
	if Sex_Type = 1 then SType=1; else
	if Sex_Type = 2 then SType=0;

	*group in condom;
	if Sex_Type = 1 then SType2=1; else
	if Sex_Type in (2 3) then SType2=0;

	if pH1_2 < 1 then pH_incr = 0; else
	if pH1_2 >= 1 then pH_incr = 1; 

*1 = in, 2=out or condom;
run;

title;
*path c;
proc reg data=species_long simple;
model log_T1_4 = SType2 / stb;
where site="Cervical" and taxa="G_vaginalis";
run;

*path a;
proc reg data=species_long simple;
model pH1_2 = SType2 / stb;
where site="Cervical" and taxa="G_vaginalis" ;
run;

proc reg data=samples_long simple;
model pH1_4 = SType / stb;
where site="Cervical" and taxa="Gardnerella";
run;

*path b;
proc reg data=species_long simple;
model log_T1_4 = pH_incr / stb;
where site="Cervical" and taxa="Gardnerella_vaginalis" ;
run;

proc sgplot data=species_long;
scatter x=log_T1_4 y=pH1_2 / jitter;
where site="Cervical" and taxa="G_vaginalis";
run;

proc sgplot data=species_long;
scatter x=log_T4 y=pH_incr / jitter;
where site="Cervical" and taxa="G_vaginalis";
run;
proc sgplot data=species_long;
scatter x=log_T4 y=pH1_4 / jitter;
where site="Cervical" and taxa="G_vaginalis";
run;

proc reg data=samples_long simple;
model log_T1_4 = pH1_2 / stb;
where site="Cervical" and taxa="Gardnerella";
run;


*path a' b';
proc reg data=species_long simple;
model log_T1_4 = pH1_2 SType / stb;
where site="Cervical" and taxa="G_vaginalis";
run;

proc reg data=species_long simple;
model lr1_4 = pH1_2 SType / stb;
where site="Cervical" and taxa="G_vaginalis";
run;

*mediation;

proc causalmed data=species_long;
model log_T1_4 =  pH1_2 SType2;
mediator pH1_2 = SType2;
*parms method=ml;
run;


proc causalmed data=species_long;
model log_T1_4 =  pH1_4 SType2;
mediator pH1_4 = SType2;
*parms method=ml;
run;

*visual;
proc means data=species_long mean std q1 median q3; 
var lr1_4 ;
class sex_type pH_incr;
where site="Cervical" and taxa="G_vaginalis" and condom=0;
run;

proc univariate data=samples_long; 
var log_T1 ;
class circumcision ;
where site="Cervical" and taxa="Gardnerella" /*and condom=0 */;
run;

proc means data=samples_long mean std c95 q1 median q3; 
var log_T1 log_T4 log_T1_4 lr1_4;
class sex_type pH_incr;
where site="Cervical" and taxa="Gardnerella" and condom=0 ;
run;

proc means data=species_long mean  stderr clm q1 median q3; 
var log_T1 log_T4 log_T1_4 lr1_4;
class stype2 pH_incr;
where site="Cervical" and taxa="G_vaginalis" /*and condom=0 */;
run;

proc means data=species_long mean  stderr clm q1 median q3; 
var log_T1 log_T4 log_T1_4 lr1_4;
class sex_type pH_incr;
where site="Cervical" and taxa="G_vaginalis" /*and condom=0 */;
run;


proc sgplot data=samples_long ; 
vbox log_T1_4 / category=pH_incr;
scatter x=pH_incr y=log_T1_4 / jitter;
where site="Cervical" and taxa="Gardnerella" and condom=0;
run;

proc sgplot data=samples_long; 
vbox lr1_4 / category=pH_incr;
scatter x=pH_incr y=lr1_4 / jitter;
yaxis min=0;
where site="Cervical" and taxa="Gardnerella" and condom=0;
run;

proc sgpanel data=samples_long; 
panelby ph_incr;
vbox lr1_4 / category=sex_type;
where site="Cervical" and taxa="Gardnerella" and condom=0;
run;

proc sgplot data=samples_long;
scatter x=pH1_2 y=log_T1_4 / jitter group=sex_type;
where site="Cervical" and taxa="Gardnerella" and condom=0;
run;

*species level;
proc means data=species_long n mean median q1 q3; 
var lr1_4 log_T1 log_T4;
class  pH_incr;
where site="Cervical" and taxa="Gardnerella_vaginalis" and condom=0;
run;

proc sgpanel data=species;
panelby pHn;
vbox l_Gardnerella_vaginalis / category=time;
where site="Cervical"  and condom=0;
run;

*regression;
proc mixed data=species;
class sex_type ID time circumcision;
model l_G_vaginalis = pHn l_Lactobacillus_crispatus l_Lactobacillus_iners  sex_type circumcision / solution;
repeated time / subject = ID;
where site="Cervical" /* and condom=0 */;
format sex_type sex_type. circumcision circumcision.;
estimate 'Sex type' sex_type 1 0 -1 ;
estimate 'Sex type' sex_type 0 1 -1 ;
estimate 'pH' pHn 1;
run;

proc genmod data=species;
class sex_type ID time circumcision;
model l_G_vaginalis = pHn l_Lactobacillus_crispatus l_Lactobacillus_iners  sex_type circumcision ;
repeated subject = ID;
where site="Cervical" /* and condom=0 */;
format sex_type sex_type. circumcision circumcision.;
estimate 'Sex type' sex_type 1 0 -1 ;
estimate 'Sex type' sex_type 0 1 -1 ;
estimate 'pH' pHn 2 ;
run;

*among  condomless;
proc genmod data=species;
class sex_type ID time circumcision;
model l_G_vaginalis = pHn l_Lactobacillus_crispatus l_Lactobacillus_iners  sex_type circumcision ;
repeated subject = ID;
where site="Cervical" /* and condom=0 */ and sex_type ^= 3;
format sex_type sex_type. circumcision circumcision.;
estimate 'Sex type' sex_type 1 -1  ;
estimate 'pH' pHn 2 ;
run;


*================================;
*pH evaluation;
data samples; set samples;
log_std_qty = log10(std_qty+1);
run;

data species; set species;
log_std_qty = log10(std_qty+1);
run;

proc freq data=samples;
table site * pHn * time / norow nocol nopercent;
run;

ods graphics / width = 12in;
proc sgpanel data=samples;
title 'Cervical Secretions - pH';
panelby  sex_type time/  rows=3 columns=4;
histogram pHn;
where site="Cervical";
format sex_type sex_type.;
run;

ods graphics / width = 6in;

proc sgpanel data=samples;
title 'Cervical Secretions - pH';
panelby  condom time/  rows=2 columns=4;
histogram pHn;
where site="Cervical";
run;

proc sort data=samples; by site time; run;

%macro medians (var= );
proc freq data=samples; 
table ph_high * site * time / norow nocol nopercent;
run;

proc sgplot data=samples noautolegend;
	title "Baseline pH - &var.";
	vbox log_&var. / category=  phn;
	scatter x=phn y= log_&var. / jitter;
	where site = "Cervical" and time = 1;
run;

proc sgplot data=samples_long noautolegend;
	title "Change in pH by change in &var., Time 1 to 2";
	scatter x=pH1_2 y=lr1_2 / jitter;
	vbox lr1_2 / category = pH1_2 transparency = 0.5;
	   refline 0 / axis=y lineattrs=(thickness=2 color=grey pattern=dash);
	   yaxis min=-10 max=10;
	where site = "Cervical" and taxa = "&var.";
run;
proc sgplot data=samples_long noautolegend;
	title "Change in pH by change in &var., Time 2 to 3";
	scatter x=pH2_3 y=lr2_3 / jitter;
	vbox lr2_3 / category = pH2_3 transparency = 0.5;
	   refline 0 / axis=y lineattrs=(thickness=2 color=grey pattern=dash);
		yaxis min=-10 max=10;
where site = "Cervical" and taxa = "&var.";
run;
proc sgplot data=samples_long noautolegend;
	title "Change in pH by change in &var., Time 3 to 4";
	scatter x=pH3_4 y=lr3_4 / jitter;
	vbox lr3_4 / category = pH3_4 transparency = 0.5;
	   refline 0 / axis=y lineattrs=(thickness=2 color=grey pattern=dash);
		yaxis min=-10 max=10;
	where site = "Cervical" and taxa = "&var.";
run;
proc sgplot data=samples_long noautolegend;
	title "Change in pH by change in &var., Time 1 to 4";
	scatter x=pH1_4 y=lr1_4 / jitter;
	vbox lr1_4 / category = pH1_4 transparency = 0.5;
	   refline 0 / axis=y lineattrs=(thickness=2 color=grey pattern=dash);
	yaxis min=-10 max=10;
	where site = "Cervical" and taxa = "&var.";
run;
%mend;

%medians (var=Lactobacillus);
%medians (var=Gardnerella);
%medians (var=Corynebacterium);
%medians (var=Prevotella);
%medians (var=Finegoldia);
%medians (var=Peptoniphilus);
%medians (var=Dialister);

%medians (var=std_qty);

proc freq data=samples;
table condomuse * sex_type;
run;

ods graphics on ;
ods graphics / width=3.5in height=6in;

%macro medians (var= );
proc freq data=species; 
table ph_high * site * time / norow nocol nopercent;
run;

proc sgplot data=species noautolegend;
	title "Baseline pH - &var.";
	vbox l_&var. / category=  phn;
	scatter x=phn y= l_&var. / jitter;
	yaxis max=10;
	where site = "Cervical" and time = 1;
run;

proc sgplot data=species_long noautolegend;
	title "Change in pH by change in &var., Time 1 to 2";
	scatter x=pH1_2 y=lr1_2 / jitter;
	vbox lr1_2 / category = pH1_2 transparency = 0.5;
		yaxis min=-10 max=10;
	   refline 0 / axis=y lineattrs=(thickness=2 color=grey pattern=dash);
	   refline 0 / axis=x lineattrs=(thickness=1 color=grey pattern=dash);
	where site = "Cervical" and taxa = "&var.";
run;
proc sgplot data=species_long noautolegend;
	title "Change in pH by change in &var., Time 2 to 3";
	scatter x=pH2_3 y=lr2_3 / jitter;
	vbox lr2_3 / category = pH2_3 transparency = 0.5;
		yaxis min=-10 max=10;
	   refline 0 / axis=y lineattrs=(thickness=2 color=grey pattern=dash);
	   refline 0 / axis=x lineattrs=(thickness=1 color=grey pattern=dash);
	where site = "Cervical" and taxa = "&var.";
run;
proc sgplot data=species_long noautolegend;
	title "Change in pH by change in &var., Time 3 to 4";
	scatter x=pH3_4 y=lr3_4 / jitter;
	vbox lr3_4 / category = pH3_4 transparency = 0.5;
		yaxis min=-10 max=10;
	   refline 0 / axis=y lineattrs=(thickness=2 color=grey pattern=dash);
	   refline 0 / axis=x lineattrs=(thickness=1 color=grey pattern=dash);
	where site = "Cervical" and taxa = "&var.";
run;
proc sgplot data=species_long noautolegend;
	title "Change in pH by change in &var., Time 1 to 4";
	scatter x=pH1_4 y=lr1_4 / jitter;
	vbox lr1_4 / category = pH1_4 transparency = 0.5;
		yaxis min=-10 max=10;
	   refline 0 / axis=y lineattrs=(thickness=2 color=grey pattern=dash);
	   refline 0 / axis=x lineattrs=(thickness=1 color=grey pattern=dash);
	where site = "Cervical" and taxa = "&var.";
run;
%mend;

%medians (var=Lactobacillus_crispatus);
%medians (var=Lactobacillus_iners);
%medians (var=Lactobacillus_reuteri);
%medians (var=Gardnerella_vaginalis);
%medians (var=Prevotella_bivia);
%medians (var=Peptostreptococcus_anaerobius);
%medians (var=Dialister_micraerophilus);

ods graphics on / attrpriority=none;

proc sgplot data=samples;
vbox log_lactobacillus / category=phn transparency=0.8;
styleattrs datasymbols=(circle triangle square asterisk);
scatter x=phn y=log_Lactobacillus / group=time jitter ;
where site="Cervical";
run;

title;
ods graphics / width=12in;
%macro scatterbox (var= );
proc sgpanel data=species noautolegend;
panelby sex_type time  / rows=3 columns=4;
vbox &var. / category=phn transparency=0.7;
styleattrs datasymbols=(circle triangle square asterisk);
scatter x=phn y=&var. / jitter markerattr=(symbol=sex_type) ;
where site="Cervical";
format sex_type sex_type.;
run;
%mend;

%scatterbox (var= l_lactobacillus_crispatus);
%scatterbox (var= l_lactobacillus_iners);
%scatterbox (var= l_lactobacillus_reuterii);
%scatterbox (var= l_gardnerella_vaginalis);
%scatterbox (var= l_dialister_micraerophilus);
%scatterbox (var= l_prevotella_bivia);

ods graphics / reset;

proc corr data=samples;
var phn log_lactobacillus;
where site="Cervical";
run;

proc glimmix data=samples;
class id;
model log_lactobacillus = phn ;
random id;
where site = "Cervical";
run;

%macro mixed (var= );
proc corr data=species spearman;
var phn l_&var.;
where site = "Cervical" and time = 1 and condom=0;
run;

proc glimmix data=species;
class id time sex_type circumcision ;
model l_&var. = phn time /*phn*time*/ sex_type circumcision ;
random id ;
where site = "Cervical" and condom=0;
estimate 'Taxa' phn 0 1 ;
run;
%mend;

%mixed (var = lactobacillus_crispatus);
%mixed (var = lactobacillus_iners);
%mixed (var = lactobacillus_reuteri);
%mixed (var = gardnerella_vaginalis);

%mixed (var = prevotella_bivia);
%mixed (var = dialister_micraerophilus);
%mixed (var = peptostreptococcus_anaerobius);

*--------------;
*how many lost BASIC;
%macro gainloss (taxa = , covar = );
proc freq data=samples_long;
table site * ( GL_T1_2 GL_T1_4) * &covar. / norow nopercent ;
where taxa = "&taxa.";
format sex_type sex_type.;
run;
%mend;

%gainloss (taxa=Prevotella, covar=sex_type);
%gainloss (taxa=Prevotella, covar=sex_type);


proc freq data=samples_long;
table site * (GL_T1_4 GL_T1_2) * sex_type / norow nopercent ;
where taxa = "Prevotella";
format sex_type sex_type.;
run;

proc freq data=species_long;
table site * (GL_T1_4 GL_T1_2) * sex_type / norow nopercent ;
where taxa = "Prevotella_bivia";
format sex_type sex_type.;
run;

proc freq data=species_long;
table site * (GL_T1_4 GL_T1_2) * sex_type / norow nopercent ;
where taxa = "Dialister_micraerophilus";
format sex_type sex_type.;
run;

proc freq data=species_long;
table site * (GL_T1_4 GL_T1_2) * sex_type / norow nopercent ;
where taxa = "Gardnerella_vaginalis";
format sex_type sex_type.;
run;


*circ;
proc freq data=species_long;
table site * (GL_T1_4 GL_T1_2) * circumcision / norow nopercent ;
where taxa = "Prevotella_bivia"  and condom=0;
format circumcision circumcision.;
run;

proc freq data=species_long;
table site * (GL_T1_4 GL_T1_2) * circumcision / norow nopercent ;
where taxa = "Dialister_micraerophilus" and condom=0;
format circumcision circumcision.;
run;

proc freq data=species_long;
table site * (GL_T1_4 GL_T1_2) * circumcision / norow nopercent ;
where taxa = "Gardnerella_vaginalis" and condom=0;
format circumcision circumcision.;
run;


proc freq data=species_long;
table site * (GL_T1_4 GL_T1_2) * circumcision / norow nopercent ;
where taxa = "Prevotella_bivia";
format sex_type sex_type. circumcision circumcision.;
run;

*------------------------------------;

*Gain/Loss;
%macro gainloss (taxa= );
proc freq data=species_long;
title "Coronal Sulcus - &taxa.";
table prev_t1 * (prev_t3 prev_t4) / norow nocol ;
where site='CorSul' and taxa = "&taxa.";
run;
proc freq data=species_long;
title "Coronal Sulcus - &taxa. - Circ Status";
table circumcision * prev_t1 * (prev_t3 prev_t4) / norow nocol ;
where site='CorSul' and taxa = "&taxa.";
format circumcision circumcision.;
run;
proc freq data=species_long;
title "Coronal Sulcus - &taxa. - Circ Status";
table condom * circumcision * prev_t1 * (prev_t3 prev_t4) / norow nocol ;
where site='CorSul' and taxa = "&taxa." and condom=0;
format circumcision circumcision.;
run;
proc freq data=species_long;
title "Cervical Secretions - &taxa.";
table prev_t1 * (prev_t3 prev_t4) / norow nocol;
where site='Cervical' and taxa = "&taxa.";
run;
%mend;

%gainloss (taxa=Peptostreptococcus_anaerobius);
%gainloss (taxa=Prevotella_bivia);
%gainloss (taxa=Dialister_micraerophilus);

*Partner data;
dm 'clear log';
proc sort data=species_long; by PID /*gender*/ condom circumcision T1 T2 T3 T4 Prev_T1 Prev_T2 Prev_T3 Prev_T4; run;
proc transpose data=species_long out=species_partner;
id taxa site;
var T1 T2 T3 T4 Prev_T1 Prev_T2 Prev_T3 Prev_T4 ;
/*keep T1 T2 T3 T4 Prev_T1 Prev_T2 Prev_T3 Prev_T4*/
by PID /*gender*/ condom circumcision ;
where taxa in ('Peptostreptococcus_anaerobius' 'Prevotella_bivia' 'Prevotella_disiens' 'Dialister_micraerophilus' 'Dialister_propionicifaciens' 'Dialister_succinatiphilus_0_8');
run; 

data species_partner; set species_partner;
	*Concordance, 1=both present, 2=male present, 3=female present, 4=neither present;

	if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' ) and 
			(Dialister_micraerophilusCorSul=1 or Dialister_propionicifaciensCorSu=1 or Peptostreptococcus_anaerobiusCor=1 or
				Dialister_succinatiphilus_0_8Cor=1 or Prevotella_disiensCorSul =1 or Prevotella_biviaCorSul=1) and 
			(Dialister_micraerophilusCervical=1 or Dialister_propionicifaciensCervi=1 or Dialister_succinatiphilus_0_8Cer=1 or Peptostreptococcus_anaerobiusCer=1 or 
				Prevotella_biviaCervical=1 or Prevotella_disiensCervical=1)
		then BASIC_P = '1'; else
			if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' ) and 
		(Dialister_micraerophilusCorSul=1 or Dialister_propionicifaciensCorSu=1 or Peptostreptococcus_anaerobiusCor=1 or
			Dialister_succinatiphilus_0_8Cor=1 or Prevotella_disiensCorSul =1 or Prevotella_biviaCorSul=1) and 
		(Dialister_micraerophilusCervical=0 and Dialister_propionicifaciensCervi=0 and Dialister_succinatiphilus_0_8Cer=0 and Peptostreptococcus_anaerobiusCer=0 and 
			Prevotella_biviaCervical=0 and Prevotella_disiensCervical=0)
		then BASIC_P = '2'; else
		if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' ) and 
			(Dialister_micraerophilusCorSul=0 and Dialister_propionicifaciensCorSu=0 and Peptostreptococcus_anaerobiusCor=0 and
				Dialister_succinatiphilus_0_8Cor=0 and Prevotella_disiensCorSul =0 and Prevotella_biviaCorSul=0) and 
			(Dialister_micraerophilusCervical=1 or Dialister_propionicifaciensCervi=1 or Dialister_succinatiphilus_0_8Cer=1 or Peptostreptococcus_anaerobiusCer=1 or 
				Prevotella_biviaCervical=1 or Prevotella_disiensCervical=1)
		then BASIC_P = '3'; else
		if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' ) and 
			(Dialister_micraerophilusCorSul=0 and Dialister_propionicifaciensCorSu=0 and Peptostreptococcus_anaerobiusCor=0 and
				Dialister_succinatiphilus_0_8Cor=0 and Prevotella_disiensCorSul =0 and Prevotella_biviaCorSul=0) and 
			(Dialister_micraerophilusCervical=0 and Dialister_propionicifaciensCervi=0 and Dialister_succinatiphilus_0_8Cer=0 and Peptostreptococcus_anaerobiusCer=0 and 
				Prevotella_biviaCervical=0 and Prevotella_disiensCervical=0)
		then BASIC_P = '4';

	if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' )
		and Dialister_micraerophilusCorSul= 1 and Dialister_micraerophilusCervical = 1 then Dialister_micraerophilus_P= '1'; else
		if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' )
			and Dialister_micraerophilusCorSul= 1 and Dialister_micraerophilusCervical = 0 then Dialister_micraerophilus_P= '2'; else
		if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' )
			and Dialister_micraerophilusCorSul= 0 and Dialister_micraerophilusCervical = 1 then Dialister_micraerophilus_P= '3'; else
		if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' )
			and Dialister_micraerophilusCorSul= 0 and Dialister_micraerophilusCervical = 0 then Dialister_micraerophilus_P= '4';

	if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' )
		and Prevotella_biviaCorSul= 1 and Prevotella_biviaCervical = 1 then Prevotella_bivia_P= '1'; else
		if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' )
			and Prevotella_biviaCorSul= 1 and Prevotella_biviaCervical = 0 then Prevotella_bivia_P= '2'; else
		if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' )
			and Prevotella_biviaCorSul= 0 and Prevotella_biviaCervical = 1 then Prevotella_bivia_P= '3'; else
		if _NAME_ in ('Prev_T1' 'Prev_T2' 'Prev_T3' 'Prev_T4' )
			and Prevotella_biviaCorSul= 0 and Prevotella_biviaCervical = 0 then Prevotella_bivia_P= '4';

run;

proc transpose data=species_partner out=species_partner;
id _NAME_;
var BASIC_p Prevotella_bivia_P Dialister_micraerophilus_P;
by PID /*gender*/ condom circumcision ;
run; 

*time 1;
proc freq data=species_partner;
table Prev_T1 / norow ;
where _NAME_='BASIC_P';
run;

proc freq data=species_partner;
table Prev_T1 / norow ;
where _NAME_='Prevotella_bivia_P';
run;

proc freq data=species_partner;
table Prev_T1 / norow ;
where _NAME_='Dialister_micraerophilus_P';
run;

*time 1;
title;
proc freq data=species_partner;
table Prev_T1 * circumcision / norow ;
where _NAME_='BASIC_P';
format circumcision circumcision.;
run;

proc freq data=species_partner;
table Prev_T1 * circumcision / norow ;
where _NAME_='Prevotella_bivia_P';
format circumcision circumcision.;
run;

proc freq data=species_partner;
table Prev_T1 * circumcision/ norow ;
where _NAME_='Dialister_micraerophilus_P';
format circumcision circumcision.;
run;

*time 2;
%macro pfreq (taxa= );
proc freq data=species_partner;
title "&taxa.";
table  Prev_T1 * Prev_T2 / nocol nopercent;
where _NAME_="&taxa.";
run;
proc freq data=species_partner;
table circumcision * Prev_T1 * Prev_T2 / nocol nopercent chisq exact;
where _NAME_="&taxa." and condom=0;
format circumcision circumcision.;
run;
title;
%mend;

%pfreq (taxa= BASIC_P);
%pfreq (taxa= Prevotella_bivia_P);
%pfreq (taxa= Dialister_micraerophilus_P);

*time 4;
%macro pfreq (taxa= );
proc freq data=species_partner;
title "&taxa.";
table  Prev_T1 * Prev_T4 / nocol nopercent;
where _NAME_="&taxa.";
run;
proc freq data=species_partner;
table circumcision * Prev_T1 * Prev_T4 / nocol nopercent chisq exact;
where _NAME_="&taxa." and condom=0;
format circumcision circumcision.;
run;
title;
%mend;

%pfreq (taxa= BASIC_P);
%pfreq (taxa= Prevotella_bivia_P);
%pfreq (taxa= Dialister_micraerophilus_P);

*==============================;
*------;
*Compare BASICs at baseline;
%macro base (taxa=);
proc means data=species_long;
var prev_T1 ;
class circumcision;
where site = "CorSul" and taxa = "&taxa.";
run;

proc means data=species_long;
var prev_T1 ;
where site = "Cervical" and taxa = "&taxa.";
run;

proc freq data=species_long ;
table prev_T1 * circumcision / norow nopercent chisq;
where site = "CorSul" and taxa = "&taxa.";
format circumcision circumcision.;
run;

proc means data=species_rel_long;
var T1 ;
class circumcision;
where site = "CorSul" and taxa = "&taxa.";
run; 

proc means data=species_rel_long;
var T1 ;
where site = "Cervical" and taxa = "&taxa.";
run; 

proc npar1way data=species_rel_long wilcoxon;
var T1 ;
class circumcision ;
where site = "CorSul" and taxa = "&taxa.";
format circumcision circumcision.;
run;
%mend;

%base (taxa=Dialister_micraerophilus);
%base (taxa=Dialister_propionicifaciens);
%base (taxa=Dialister_succinatiphilus_0_8);
%base (taxa=Peptostreptococcus_anaerobius);
%base (taxa=Prevotella_bivia);
%base (taxa=Prevotella_disiens);

%base (taxa=Lactobacillus_crispatus);
%base (taxa=Lactobacillus_gasseri);
%base (taxa=Lactobacillus_iners);
%base (taxa=Lactobacillus_jensenii_0_8);
%base (taxa=Lactobacillus_reuteri);
%base (taxa=Gardnerella_vaginalis);

proc means data=samples_rel_long mean std;
var  T1;
*class circumcision;
where site = "Cervical" and taxa = "Lactobacillus";
run;

