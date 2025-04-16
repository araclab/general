 /*============================================================================
 Program Name:  Nasal Cx .sas 
 Author......:  Dan Park
 Date........:	18MAY2023
 Language....:  SAS 9.4
 Purpose.....;  
 Input.......:  
 Output......: 	
 Use.........: 
 Notes.......:   
===========================   REVISION LOG   ==================================
*Need to incorporate species;
============================================================================= */

libname NMb 'path';

dm 'clear log';

*---------------------;
*Import data;


*----------------------;
*Generate proportional and absolute abundance matrices;


*---------------------;

proc format ;
value CST_Prop 1='C. accolens' 2='Cutibacterium' 3='Finegoldia/Pep/Anaero' 4='M. cat/nonliq' 5='Dp/C. pseudo' 6='S. aureus' 7='S. epi' 8='C. segment' 9='M. nonliq' 10='Bacillus' 11='Entero' 12='Haemophilus';
value $CST_Prop '1'='5a C. accolens' '2'='4a Cutibacterium' '3'='4b Finegoldia/Pep/Anaero' '4'='6a M. cat/nonliq' '5'='7 Dp/C. pseudo' '6a'='1a S. aureus-high' '6b'='1b S. aureus-med' 
			'7'='3 S. epi' '8'='5b C. segment' '9'='6b M. nonliq' '10'='2b Bacillus' '11'='2a Entero' '12'='8 Haemophilus';
run;

*---------------------;
*END DATA SETUP;
*---------------------;

*Prevalence;
data nasal_prev; set nasal_prop;

%macro prev (taxa=);
	if &taxa. > 0 then &taxa. = 1; else
	if &taxa. = 0 then &taxa. = 0;
%mend;

%prev (taxa= Abiotrophia); %prev (taxa= Acinetobacter); %prev (taxa= Actinomyces); %prev (taxa= Actinomycetales_Unclassified_Unc); %prev (taxa= Aerococcus); 
%prev (taxa= Aggregatibacter); %prev (taxa= Alloiococcus); %prev (taxa= Alloprevotella); %prev (taxa= Alloprevotella_0_8); %prev (taxa= Anaerobacillus_0_8); 
%prev (taxa= Anaerococcus); %prev (taxa= Atopobium); %prev (taxa= Bacillales_Unclassified_Unclassi); %prev (taxa= Bacillus); %prev (taxa= Bacillus_0_8); 
%prev (taxa= Bifidobacterium); %prev (taxa= Blautia); %prev (taxa= Bosea); %prev (taxa= Brachybacterium); %prev (taxa= Bradyrhizobium); %prev (taxa= Brevibacterium); 
%prev (taxa= Brevundimonas); %prev (taxa= Brochothrix); %prev (taxa= Campylobacter); %prev (taxa= Capnocytophaga); %prev (taxa= Carnobacterium); 
%prev (taxa= Caulobacter); %prev (taxa= Chryseobacterium); %prev (taxa= Cloacibacterium); %prev (taxa= Clostridiales_Unclassified_Uncla); 
%prev (taxa= Clostridium_sensu_stricto); %prev (taxa= Collinsella); %prev (taxa= Comamonas); %prev (taxa= Corynebacterium); %prev (taxa= Curvibacter); %prev (taxa= Deinococcus); 
%prev (taxa= Delftia); %prev (taxa= Dermabacter); %prev (taxa= Dialister); %prev (taxa= Dietzia); %prev (taxa= Dolosigranulum); %prev (taxa= Empedobacter); 
%prev (taxa= Enhydrobacter); %prev (taxa= Enterococcus); %prev (taxa= Erwinia_0_8); %prev (taxa= Exiguobacterium); %prev (taxa= Ezakiella); %prev (taxa= Facklamia); 
%prev (taxa= Faecalibacterium); %prev (taxa= Finegoldia); %prev (taxa= Flavobacterium); %prev (taxa= Fusobacterium); %prev (taxa= Gardnerella); %prev (taxa= Gemella); 
%prev (taxa= Granulicatella); %prev (taxa= Halomonas); %prev (taxa= Herbaspirillum); %prev (taxa= Hymenobacter); %prev (taxa= Kingella); %prev (taxa= Kingella_0_8); 
%prev (taxa= Kocuria); %prev (taxa= Lachnospiracea_incertae_sedis); %prev (taxa= Lactobacillus); %prev (taxa= Lactococcus); %prev (taxa= Lautropia); 
%prev (taxa= Leptotrichia); %prev (taxa= Leuconostoc); %prev (taxa= Listeria); %prev (taxa= Macrococcus); %prev (taxa= Massilia); %prev (taxa= Megasphaera); 
%prev (taxa= Mesorhizobium); %prev (taxa= Methylobacterium); %prev (taxa= Microbacterium); %prev (taxa= Micrococcus); %prev (taxa= Micrococcus_0_8); 
%prev (taxa= Morganella); %prev (taxa= Murdochiella); %prev (taxa= Negativicoccus); %prev (taxa= Neisseria); %prev (taxa= Nocardioides); %prev (taxa= Ochrobactrum); 
%prev (taxa= Ochrobactrum_0_8); %prev (taxa= Olsenella); %prev (taxa= Pantoea); %prev (taxa= Pantoea_0_8); %prev (taxa= Paracoccus); 
%prev (taxa= Parcubacteria_genera_incertae_se); %prev (taxa= Parvimonas); %prev (taxa= Pasteurella_0_8); %prev (taxa= Peptoniphilus); %prev (taxa= Peptostreptococcus); 
%prev (taxa= Porphyromonas); %prev (taxa= Prevotella); %prev (taxa= Propionibacterium); %prev (taxa= Proteobacteria_Unclassified_Uncl); %prev (taxa= Pseudoalteromonas); 
%prev (taxa= Pseudomonas); %prev (taxa= Psychrobacter); %prev (taxa= Ralstonia); %prev (taxa= Rhizobium); %prev (taxa= Rhodococcus); %prev (taxa= Rothia); 
%prev (taxa= Ruminococcus2); %prev (taxa= Saccharibacteria_genera_incertae); %prev (taxa= Selenomonas); %prev (taxa= Serratia); %prev (taxa= Simonsiella_0_8); 
%prev (taxa= Snodgrassella); %prev (taxa= Snodgrassella_0_8); %prev (taxa= Solirubrobacter); %prev (taxa= Soonwooa_0_8); %prev (taxa= Sphingomonas); 
%prev (taxa= Stenotrophomonas); %prev (taxa= Streptophyta); %prev (taxa= Turicella); %prev (taxa= Vagococcus); %prev (taxa= Varibaculum); %prev (taxa= Veillonella); 
%prev (taxa= Vibrio); %prev (taxa= Weissella); %prev (taxa= Xanthomonas); %prev (taxa= Peptostreptococcaceae_incertae_s); %prev (taxa= Staphylococcus_aureus_m); 
%prev (taxa= Staphylococcus_epidermidis_m); %prev (taxa= Staphylococcus_hominis_0_8); %prev (taxa= Staphylococcus_nonepi); %prev (taxa= Staphylococcus_other); %prev (taxa= C_accolens); %prev (taxa= C_pseudo); 
%prev (taxa= C_tuberculostearicum); %prev (taxa= C_segmentosum); %prev (taxa= Moraxella_cat_nonliq); %prev (taxa= Moraxella_nonliquefaciens); %prev (taxa= Moraxella_lincolnii); 
%prev (taxa= Moraxella_lacunata); %prev (taxa= Streptococcus_pneumoniae); %prev (taxa= Streptococcus_parasanguinis); %prev (taxa= Streptococcus_salivarius); 
%prev (taxa= Streptococcus_agalactiae); %prev (taxa= Streptococcus_sanguinis); %prev (taxa= Haemophilus_influenzae); %prev (taxa= Haemophilus_parainfluenzae); 
%prev (taxa= Haemophilus_hemoplyticus); %prev (taxa= Enterobacteriaceae_m); %prev (taxa= Moraxella_other); %prev (taxa= Haemophilus_other); 
%prev (taxa= Haemophilus_m); %prev (taxa= Corynebacterium_other); %prev (taxa= Streptococcus_other);

run;

proc means data=nasal_prev n mean std ;
var &full_list.;
run;


*--;
*CST proportions;
proc freq data=nasal_prop;
table  CST_Prop / norow    ;
format CST_Prop $CST_Prop.;
run;

*Demographics;
proc freq data=nasal_prop;
table  carrier sex smoker01 age10 / norow   missing ;
format CST_Prop $CST_Prop.;
run;
proc freq data=nasal_prop ;
table  CST_Prop_label * (carrier sex smoker01 age10) / nocol  nopercent chisq;
format CST_Prop $CST_Prop.;
run;

*Age associations;

proc logistic data=nasal_prop;
class CST_Prop_label (ref='4a Cutibacterium') sex smoker01 age10 / param=ref;
model  age10 =  CST_Prop_label sex smoker01 / link=glogit;
oddsratio CST_Prop_label;
run;

proc logistic data=nasal_prop;
class CST_Prop_label (ref='4a Cutibacterium') sex smoker01 age10 (ref='b 25-35 ') / param=ref;
model CST_Prop_label  = age10  sex smoker01 / link=glogit;
oddsratio CST_Prop_label;
run;

data nasal_prop; set nasal_prop;

if CST_Prop = '1' then CST_5a = 1; else
	CST_5a = 0;
if CST_Prop = '2' then CST_4 = 1; else
	CST_4 = 0;
if CST_Prop = '3' then CST_9a = 1; else
	CST_9a = 0;
if CST_Prop = '4' then CST_6a = 1; else
	CST_6a = 0;
if CST_Prop = '5' then CST_7 = 1; else
	CST_7 = 0;
if CST_Prop = '6a' then CST_1a = 1; else
	CST_1a = 0;
if CST_Prop = '6b' then CST_1b = 1; else
	CST_1b = 0;
if CST_Prop = '7' then CST_3 = 1; else
	CST_3 = 0;
if CST_Prop = '8' then CST_5b = 1; else
	CST_5b = 0;
if CST_Prop = '9' then CST_6b = 1; else
	CST_6b = 0;
if CST_Prop = '10' then CST_9b = 1; else
	CST_9b = 0;
if CST_Prop = '11' then CST_2 = 1; else
	CST_2 = 0;
if CST_Prop = '12' then CST_8 = 1; else
	CST_8 = 0;
run;

%macro glogit (var= );
proc freq data=nasal_prop;
table &var. * age10 / nocol ;
run;

proc logistic data=nasal_prop;
class  sex smoker01 age10 (ref='c 35-45 ') / param=ref;
model  &var. (ref='0') = age10  sex smoker01 / link=glogit;
oddsratio &var.;
run;
%mend;

%glogit (var=CST_1a);
%glogit (var=CST_1b);
%glogit (var=CST_2);
%glogit (var=CST_3);
%glogit (var=CST_4);
%glogit (var=CST_5a);
%glogit (var=CST_5b);
%glogit (var=CST_6a);
%glogit (var=CST_6b);
%glogit (var=CST_7);
%glogit (var=CST_8);
%glogit (var=CST_9a);
%glogit (var=CST_9b);


*Ordinal;
data nasal_prop; set nasal_prop;
if age10 = "a under 25" then age_n = 1; else
if age10 = "b 25-35" then age_n = 2; else
if age10 = "c 35-45" then age_n = 3; else
if age10 = "d 45-55" then age_n = 4; else
if age10 = "e over 55" then age_n = 5;
run;

%macro glogit (var= );
proc logistic data=nasal_prop;
class  sex smoker01  / param=ref;
model  &var. (ref='0') = age_n  sex smoker01 / link=glogit;
oddsratio &var.;
run;
%mend;

%glogit (var=CST_1a);
%glogit (var=CST_1b);
%glogit (var=CST_2);
%glogit (var=CST_3);
%glogit (var=CST_4);
%glogit (var=CST_5a);
%glogit (var=CST_5b);
%glogit (var=CST_6a);
%glogit (var=CST_6b);
%glogit (var=CST_7);
%glogit (var=CST_8);
%glogit (var=CST_9a);
%glogit (var=CST_9b);
*-;

proc logistic data=nasal_prop;
class  sex smoker01 age10 (ref='b 25-35 ') / param=ref;
model  CST7 (ref='0') =  age10  sex  smoker01  / link=glogit;
oddsratio CST7;
run;

*Check density by age;
proc npar1way data=nasal_prop wilcoxon;
var l_std_qty;
class age10;
run;

*Stacked barplot;

%macro dem (var= );
proc sort data=nasal_prop out=nasal_prop;
by &var.;                     /* sort X categories */
run;
 
proc freq data=nasal_prop noprint;
by &var.;                    /* X categories on BY statement */
tables CST_Prop / out=FreqOut;    /* Y (stacked groups) on TABLES statement */
run;
 
title;
proc sgplot data=FreqOut;
vbar &var. / response=Percent group=CST_Prop groupdisplay=stack;
xaxis discreteorder=data;
yaxis grid values=(0 to 100 by 10) label="Percentage of Total with CST";
format CST_Prop $CST_Prop.;
run;

proc freq data=nasal_prop;
table &var. * CST_Prop / norow nopercent chisq;
format CST_Prop $CST_Prop.;
run;

%mend;

%dem (var=age10);
%dem (var=sex);
%dem (var=smoker01);
%dem (var=carrier);

*-------------------;
*Correlations;

proc means data=nasal_prev;
var &full_list;
run;

proc corr data=prop spearman outs=corrouts;
var &full_list;
run;

*at least 10% prevalence;
proc corr data=nasal_prop fisher spearman;
var Streptococcus_sanguinis Lactococcus  Alloprevotella Leptotrichia Paracoccus C_segmentosum  Fusobacterium Flavobacterium Moraxella_nonliquefaciens
Sphingomonas Saccharibacteria_genera_incertae Negativicoccus Pseudomonas Staphylococcus_other Porphyromonas Haemophilus_other Dialister
Microbacterium Granulicatella Haemophilus_parainfluenzae Snodgrassella_0_8 Curvibacter Ochrobactrum Streptophyta Streptococcus_other
Streptococcus_salivarius Actinomyces Enhydrobacter Moraxella_cat_nonliq Neisseria Gemella Lactobacillus Bacillus
Rothia Campylobacter Simonsiella_0_8 Acinetobacter Prevotella Enterobacteriaceae_m /*Haemophilus_m*/ Veillonella Micrococcus
Bacillus_0_8 Delftia Staphylococcus_aureus_m C_pseudo C_tuberculostearicum Streptococcus_pneumoniae Corynebacterium_other Dolosigranulum Finegoldia
Actinomycetales_Unclassified_Unc Peptoniphilus Anaerococcus C_accolens Propionibacterium Staphylococcus_epidermidis_m
Haemophilus_influenzae; *manually adding H.influenzae;
ods output fisherspearmancorr = SpearmanCorrs;
run;

data spearman_p; set SpearmanCorrs;
RAW_P = pValue;
keep var withvar Corr Lcl Ucl RAW_P;
run;

proc multtest inpvalues=spearman_p  hoc fdr out=ahoc;
run;

proc export data=ahoc
	outfile = "path.xlsx"
	dbms=xlsx replace;
run;


*-;
*Table of pos and negative;

data spearman_p; 
	merge spearman_p ahoc;
run;

data spearman_p; set spearman_p;
if Corr < 0 then Pos = 0; else 
if Corr > 0 then Pos = 1; 

if 0 <= hoc_p < 0.05 then Sig = 1; else
Sig = 0;
run;

proc freq data=spearman_p;
table sig;
run;

data speaman_p1; set spearman_p;
if sig = 0 then delete;
keep Var Pos;
run;

data speaman_p2; set spearman_p;
Var = WithVar;
keep Var Pos;
run;

proc append base=speaman_p1 data=speaman_p2;
run;

proc freq data=speaman_p1;
table Var * Pos / nopercent nocol norow;
run;

*-----------;

*Supp table S1;
proc means data=nasal_prop n mean std;
var &full_list.;
run;

%macro abs (var= );
proc means data=nasal_abs n median q1 q3;
var &var.;
where &var. > 0  ;
run;
%mend;

%abs (var=Haemophilus_influenzae );


*Supp table S3, characteristics of indicator taxa by nasal CST;
%macro prop_abs (var= );
proc means data=nasal_prop n mean std;
var &var.;
class cst_prop;
format CST_Prop $CST_Prop.;
run;

proc means data=nasal_abs n median q1 q3;
var &var.;
class cst_prop;
format CST_Prop $CST_Prop.;
run;

proc means data=nasal_prop n mean std;
var &var.;
run;

proc means data=nasal_abs n median q1 q3;
var &var.;
where &var. > 0  ;
run;
%mend;

%prop_abs (var=Staphylococcus_aureus_m);
%prop_abs (var=Enterobacteriaceae_m);
%prop_abs (var=Staphylococcus_epidermidis_m);
%prop_abs (var=Propionibacterium);
%prop_abs (var=C_accolens);
%prop_abs (var=C_segmentosum);

%prop_abs (var=Moraxella_cat_nonliq);
%prop_abs (var=Moraxella_nonliquefaciens);
%prop_abs (var=Dolosigranulum);
%prop_abs (var=C_Pseudo);

%prop_abs (var=Haemophilus_m);
%prop_abs (var=Finegoldia);
%prop_abs (var=Peptoniphilus);
%prop_abs (var=Bacillus);

*outside CST;
data nasal_prop_cst; set nasal_prop;
if CST_Prop_label in ('1a S. aureus-high' '1b S. aureus-med') then CST_Saur = 1; else
	CST_Saur = 0;
if CST_Prop_label = '2a Entero' then CST_Entero = 1; else
	CST_Entero = 0;
if CST_Prop_label = '3 S. epi' then CST_Sepi = 1; else
	CST_Sepi = 0;
if CST_Prop_label = '4a Cutibacterium' then CST_Cuti = 1; else
	CST_Cuti = 0;
if CST_Prop_label = '5a C. accolens' then CST_Cacc = 1; else
	CST_Cacc = 0;
if CST_Prop_label = '5b C. segment' then CST_Cseg = 1; else
	CST_Cseg = 0;
if CST_Prop_label = '6a M. cat/nonliq' then CST_Mcat = 1; else
	CST_Mcat = 0;
if CST_Prop_label = '6b M. nonliq' then CST_Mnon = 1; else
	CST_Mnon = 0;
if CST_Prop_label = '7 Dp/C. pseudo' then CST_DpCp = 1; else
	CST_DpCp = 0;
if CST_Prop_label = '8 Haemophilus' then CST_Hinf = 1; else
	CST_Hinf = 0;
if CST_Prop_label = '4b Finegoldia/Pep/Anaero' then CST_Anae = 1; else
	CST_Anae = 0;
if CST_Prop_label = '2b Bacillus' then CST_Bacil = 1; else
	CST_Bacil = 0;
run;

data nasal_abs_cst; set nasal_abs;
if CST_Prop_label in ('1a S. aureus-high' '1b S. aureus-med') then CST_Saur = 1; else
	CST_Saur = 0;
if CST_Prop_label = '2a Entero' then CST_Entero = 1; else
	CST_Entero = 0;
if CST_Prop_label = '3 S. epi' then CST_Sepi = 1; else
	CST_Sepi = 0;
if CST_Prop_label = '4a Cutibacterium' then CST_Cuti = 1; else
	CST_Cuti = 0;
if CST_Prop_label = '5a C. accolens' then CST_Cacc = 1; else
	CST_Cacc = 0;
if CST_Prop_label = '5b C. segment' then CST_Cseg = 1; else
	CST_Cseg = 0;
if CST_Prop_label = '6a M. cat/nonliq' then CST_Mcat = 1; else
	CST_Mcat = 0;
if CST_Prop_label = '6b M. nonliq' then CST_Mnon = 1; else
	CST_Mnon = 0;
if CST_Prop_label = '7 Dp/C. pseudo' then CST_DpCp = 1; else
	CST_DpCp = 0;
if CST_Prop_label = '8 Haemophilus' then CST_Hinf = 1; else
	CST_Hinf = 0;
if CST_Prop_label = '4b Finegoldia/Pep/Anaero' then CST_Anae = 1; else
	CST_Anae = 0;
if CST_Prop_label = '2b Bacillus' then CST_Bacil = 1; else
	CST_Bacil = 0;
run;

*--;

*Variance partitioning;
data nasal_prev_varp; set nasal_prev;
length CST_Prop_Cat $15.;
if CST_Prop_label in ('5a C. accolens' '5b C. segment') then CST_Prop_Cat = '5'; else
if CST_Prop_label in ('1a S. aureus-high' '1b S. aureus-med') then CST_Prop_Cat = '1'; else
if CST_Prop_label in ('6a M. cat/nonliq' '6b M. nonliq') then CST_Prop_Cat = '6'; else
CST_Prop_Cat = CST_Prop_label;

if CST_Prop_label in ('1a S. aureus-high' '1b S. aureus-med') then CST_Saur = 1; else
	CST_Saur = 0;
if CST_Prop_label = '2a Entero' then CST_Entero = 1; else
	CST_Entero = 0;
if CST_Prop_label = '3 S. epi' then CST_Sepi = 1; else
	CST_Sepi = 0;
if CST_Prop_label = '4a Cutibacterium' then CST_Cuti = 1; else
	CST_Cuti = 0;
if CST_Prop_label = '5a C. accolens' then CST_Cacc = 1; else
	CST_Cacc = 0;
if CST_Prop_label = '5b C. segment' then CST_Cseg = 1; else
	CST_Cseg = 0;
if CST_Prop_label = '6a M. cat/nonliq' then CST_Mcat = 1; else
	CST_Mcat = 0;
if CST_Prop_label = '6b M. nonliq' then CST_Mnon = 1; else
	CST_Mnon = 0;
if CST_Prop_label = '7 Dp/C. pseudo' then CST_DpCp = 1; else
	CST_DpCp = 0;
if CST_Prop_label = '8 Haemophilus' then CST_Hinf = 1; else
	CST_Hinf = 0;
if CST_Prop_label = '4b Finegoldia/Pep/Anaero' then CST_Anae = 1; else
	CST_Anae = 0;
if CST_Prop_label = '2b Bacillus' then CST_Bacil = 1; else
	CST_Bacil = 0;

drop carrier gwu_id run_id sample_id run_id_2 gwu_id_2 std_qty l_std_qty age5 p_contam Cellulomonas Pseudoxanthomonas contaminated2
	/*CST1 CST2 CST3 CST4 CST5 CST6a CST6b CST7 CST8 CST9 CST10 CST11 CST12*/ CST_Tier1 CST_Tier2 CSTMulti studyname /*CST_Prop*/ CST_Prop_label total_reads;
run;

PROC GLM data=nasal_prev_varp;
model CST_Saur = C_accolens C_pseudo /*C_segmentosum*/ Dolosigranulum Haemophilus_influenzae Moraxella_cat_nonliq Moraxella_nonliquefaciens Propionibacterium 
	Staphylococcus_aureus_m Staphylococcus_epidermidis_m
	/*Streptococcus_pneumoniae*/ Finegoldia Anaerococcus Peptoniphilus Bacillus  female agen;
run;

PROC CATMOD data=nasal_prev_varp;
*class individual _NAME_ smoker01 sex age10;
model CST_Prop_Cat  = C_accolens C_pseudo /*C_segmentosum*/ Dolosigranulum Haemophilus_influenzae Moraxella_cat_nonliq Moraxella_nonliquefaciens Propionibacterium 
	Staphylococcus_aureus_m Staphylococcus_epidermidis_m
	/*Streptococcus_pneumoniae*/ Finegoldia Anaerococcus Peptoniphilus Bacillus smoker01 sex age10 / freq design;
run;
quit;


*by CST;
PROC logistic data=nasal_prev_varp_t;
class individual _NAME_ smoker01 sex age10;
model CST_Prop_n  = _NAME_ COL1 sex age10 / link=glogit ;
where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Moraxella_nonliquefaciens' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
'Finegoldia' 'Anaerococcus' 'Peptoniphilus' 'Bacillus');
run;

PROC glimmix data=nasal_prev_varp_t;
class individual _NAME_ smoker01 sex age10;
model CST_Prop_n  = _NAME_ COL1 sex age10 / link=logit solution;
where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Moraxella_nonliquefaciens' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
'Finegoldia' 'Anaerococcus' 'Peptoniphilus' 'Bacillus');
random intercept / subject = individual;
run;
quit;
