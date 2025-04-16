 /*============================================================================
 Program Name:  Nasal Longitudinal v2.sas 
 Author......:  Dan Park
 Date........:	28OCT2022
 Language....:  SAS 9.4
 Purpose.....;  
 Input.......:  
 Output......: 	
 Use.........: 
 Notes.......:   
===========================   REVISION LOG   ==================================
*Need to incorporate species;
============================================================================= */

libname NMbLong 'path';

dm 'clear log';

*---------------------;
*Create proportional and absolute abundance matrices;

*--------------------------------;
*Prevalence dataset;

%macro Prev (threshold=); *call all vars, divides using var_two;

%macro vname (var=);
if &var. > &threshold. then  &var. =1; else
if &var. = &threshold. then  &var. =0;
%mend;

%local i ;
%let i=1;
%do %while (%scan(&full_list, &i) ne ); 
%vname(var=%scan(&full_list, &i));
   %let i = %eval(&i + 1);
%end;

%mend;

data nasal_prev; set nasal_prop;

	%Prev (threshold=0);

run;


data prev_long; set nasal_prev;
keep visit_number visit_n weekly new_number gender count std_qty Sa_Dp_Both Dp_only Sa_only Sa_Dp_None Sa_Dp_cat Mc_Dp_Both Mc_only Mc_Dp_None 

	CST1 CST2 CST3 CST4 CST5 CST6a CST6b CST7 CST8 CST9 CST10 CST11 CST12
	Moraxella_cat_nonliq Moraxella_nonliquefaciens Staphylococcus_epidermidis_m Staphylococcus_aureus_m Dolosigranulum C_accolens C_pseudo C_segmentosum Enterobacteriaceae_m Bacillus	
	Gram_Pos Haemophilus_m Haemophilus_influenzae Propionibacterium Streptococcus_pneumoniae 

	Actinomycetales_Unclassified_Unc Anaerococcus Campylobacter Finegoldia Gemella Lactobacillus Micrococcus Peptoniphilus Prevotella Simonsiella_0_8 Streptophyta Veillonella
	C_tuberculostearicum Streptococcus_salivarius Haemophilus_parainfluenzae;

run;

data prev_long_m ; set prev_long;
*	if weekly = 1 then delete;
run;

proc sort data=prev_long; by new_number visit_n; run;
proc sort data=prev_long_m; by new_number visit_n; run;

proc transpose data=prev_long_m out=prev_long_m prefix=v;
id visit_n ;
by new_number;
var count Dp_only  Sa_Dp_Both  Sa_only Sa_Dp_None Sa_Dp_cat Mc_only Mc_Dp_Both Mc_Dp_None

	CST1 CST2 CST3 CST4 CST5 CST6a CST6b CST7 CST8 CST9 CST10 CST11 CST12
	Moraxella_cat_nonliq Moraxella_nonliquefaciens Staphylococcus_epidermidis_m Staphylococcus_aureus_m Dolosigranulum C_accolens C_pseudo C_segmentosum Enterobacteriaceae_m Bacillus	
	Gram_Pos Haemophilus_m Haemophilus_influenzae Propionibacterium Streptococcus_pneumoniae 

	Actinomycetales_Unclassified_Unc Anaerococcus Campylobacter Finegoldia Gemella Lactobacillus Micrococcus Peptoniphilus Prevotella Simonsiella_0_8 Streptophyta Veillonella
	C_tuberculostearicum Streptococcus_salivarius Haemophilus_parainfluenzae;

run;

data prev_long_m; set prev_long_m;

%macro cstzeros (var= );
	if _LABEL_ = "&var." and v1 in ('           .' '.' ) then v1='0'; 
	if _LABEL_ = "&var." and v2 in ('           .' '.' ) then v2='0'; 
	if _LABEL_ = "&var." and v3 in ('           .' '.' ) then v3='0'; 
	if _LABEL_ = "&var." and v4 in ('           .' '.' ) then v4='0'; 
	if _LABEL_ = "&var." and v5 in ('           .' '.' ) then v5='0'; 
	if _LABEL_ = "&var." and v6 in ('           .' '.' ) then v6='0'; 
	if _LABEL_ = "&var." and v7 in ('           .' '.' ) then v7='0'; 
	if _LABEL_ = "&var." and v8 in ('           .' '.' ) then v8='0'; 
	if _LABEL_ = "&var." and v9 in ('           .' '.' ) then v9='0'; 
	if _LABEL_ = "&var." and v10 in ('           .' '.' ) then v10='0'; 
	if _LABEL_ = "&var." and v11 in ('           .' '.' ) then v11='0'; 
	if _LABEL_ = "&var." and v12 in ('           .' '.' ) then v12='0'; 
	if _LABEL_ = "&var." and v13 in ('           .' '.' ) then v13='0'; 
	if _LABEL_ = "&var." and v14 in ('           .' '.' ) then v14='0'; 
	if _LABEL_ = "&var." and v15 in ('           .' '.' ) then v15='0'; 
	if _LABEL_ = "&var." and v16 in ('           .' '.' ) then v16='0'; 
	if _LABEL_ = "&var." and v17 in ('           .' '.' ) then v17='0'; 
	if _LABEL_ = "&var." and v18 in ('           .' '.' ) then v18='0'; 
	if _LABEL_ = "&var." and v19 in ('           .' '.' ) then v19='0'; 
	if _LABEL_ = "&var." and v20 in ('           .' '.' ) then v20='0'; 
	if _LABEL_ = "&var." and v21 in ('           .' '.' ) then v21='0'; 
%mend;

%cstzeros (var=CST1a);
%cstzeros (var=CST1b);
%cstzeros (var=CST2a);
%cstzeros (var=CST2b);
%cstzeros (var=CST3);
%cstzeros (var=CST4a);
%cstzeros (var=CST4b);
%cstzeros (var=CST5a);
%cstzeros (var=CST5b);
%cstzeros (var=CST6a);
%cstzeros (var=CST6b);
%cstzeros (var=CST7);
%cstzeros (var=CST8);

	if _NAME_ ^= 'Sa_Dp_cat' then 
		total_vis = count(v1, '0') + count(v1, '1') + count(v2, '0') + count(v2, '1') + count(v3, '0') + count(v3, '1') + count(v4, '0') + count(v4, '1') + count(v5, '0') + count(v5, '1') +
			count(v6, '0') + count(v6, '1') + count(v7, '0') + count(v7, '1') + count(v8, '0') + count(v8, '1') + count(v9, '0') + count(v9, '1') + count(v10, '0') + count(v10, '1') +
			count(v11, '0') + count(v11, '1') + count(v12, '0') + count(v12, '1') + count(v13, '0') + count(v13, '1') + count(v14, '0') + count(v14, '1') + count(v15, '0') + count(v15, '1') +
			count(v16, '0') + count(v16, '1') + count(v17, '0') + count(v17, '1') + count(v18, '0') + count(v18, '1') + count(v19, '0') + count(v19, '1') + count(v20, '0') + count(v20, '1') +
			count(v21, '0') + count(v21, '1');

	%macro total (vis=);
	if _NAME_ ^= 'Sa_Dp_cat' and v&vis. ^= . and total = . then total = &vis.;
	%mend;
	%total (vis=21); 	%total (vis=20); 	%total (vis=19); 	%total (vis=18); 	%total (vis=17);
	%total (vis=16); 	%total (vis=15); 	%total (vis=14); 	%total (vis=13); 	%total (vis=12);
	%total (vis=11); 	%total (vis=10); 	%total (vis=9); 	%total (vis=8); 	%total (vis=7);
	%total (vis=6); 	%total (vis=5); 	%total (vis=4); 	%total (vis=3); 	%total (vis=2);	%total (vis=1);

	if _NAME_ ^= 'Sa_Dp_cat' then 	
		total_pos = sum(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19, v20, v21);

run;

data prev_long_m; set prev_long_m;

%macro vn (vn=);
if v&vn. = '           1' then v&vn. = '1'; else
if v&vn. = '           0' then v&vn. = '0';
%mend;

%vn (vn=1);		%vn (vn=2);		%vn (vn=3);		%vn (vn=4);		%vn (vn=5);
%vn (vn=6);		%vn (vn=7);		%vn (vn=8);		%vn (vn=9);		%vn (vn=10);
%vn (vn=11);	%vn (vn=12);	%vn (vn=13);	%vn (vn=14);	%vn (vn=15);
%vn (vn=16);	%vn (vn=17);	%vn (vn=18);	%vn (vn=19);	%vn (vn=20);
%vn (vn=21);

*Handling false negatives;
%macro fn (n1=, n2=, n3=, n4=, n5=, n6= );
if v&n1.='1' and v&n2.='0' and v&n3.='1' then v&n2.='1'; else 
if v&n1.='1' and v&n2.='' and v&n3.='0' and v&n4.='1' then v&n3.='1'; else
if v&n1.='1' and v&n2.='' and v&n3.='' and v&n4.='0' and v&n5.='1' then v&n4.='1'; else
if v&n1.='1' and v&n2.='' and v&n3.='' and v&n4.='' and v&n5.='0' and v&n6.='1' then v&n5.='1'; 

if v&n1.='1' and v&n2.='0' and v&n3.='1' then v&n2.='1'; else
if v&n1.='1' and v&n2.='0' and v&n3.='' and v&n4.='1' then v&n2.='1'; else
if v&n1.='1' and v&n2.='0' and v&n3.='' and v&n4.='' and v&n5.='1' then v&n2.='1'; else
if v&n1.='1' and v&n2.='0' and v&n3.='' and v&n4.='' and v&n5.='' and v&n6.='1' then v&n2.='1';
%mend;
%fn (n1=1, n2=2, n3=3, n4=4, n5=5, n6=6);
%fn (n1=2, n2=3, n3=4, n4=5, n5=6, n6=7);
%fn (n1=3, n2=4, n3=5, n4=6, n5=7, n6=8);
%fn (n1=4, n2=5, n3=6, n4=7, n5=8, n6=9);
%fn (n1=5, n2=6, n3=7, n4=8, n5=9, n6=10);
%fn (n1=6, n2=7, n3=8, n4=9, n5=10, n6=11);
%fn (n1=7, n2=8, n3=9, n4=10, n5=11, n6=12);
%fn (n1=8, n2=9, n3=10, n4=11, n5=12, n6=13);
%fn (n1=9, n2=10, n3=11, n4=12, n5=13, n6=14);
%fn (n1=10, n2=11, n3=12, n4=13, n5=14, n6=15);
%fn (n1=11, n2=12, n3=13, n4=14, n5=15, n6=16);
%fn (n1=12, n2=13, n3=14, n4=15, n5=16, n6=17);
%fn (n1=13, n2=14, n3=15, n4=16, n5=17, n6=18);
%fn (n1=14, n2=15, n3=16, n4=17, n5=18, n6=19);
%fn (n1=15, n2=16, n3=17, n4=18, n5=19, n6=20);
%fn (n1=16, n2=17, n3=18, n4=19, n5=20, n6=21);	

run;

data prev_long_m; set prev_long_m;

length start1 8. end1 8. svn 8.;

*residence and return;
if _NAME_ ^= 'Sa_Dp_cat' then start1 = .;

%macro res (start=);

if _NAME_ ^= 'Sa_Dp_cat' and start1 = . and v&start. = 1 then start1=&start.; 

%mend;

%res (start=1); %res (start=2); %res (start=3); %res (start=4); %res (start=5); %res (start=6); %res (start=7); %res (start=8); %res (start=9); 
%res (start=10); %res (start=11); %res (start=12); %res (start=13); %res (start=14); %res (start=15); %res (start=16); %res (start=17); %res (start=18); 
%res (start=19); %res (start=20); %res (start=21); 

run;

data prev_long_m; set prev_long_m;

%macro res2 (vn=, svisit=);

if _NAME_ ^= 'Sa_Dp_cat' then svn = &svisit.;
if . < total <= svn then calc = 1;

if calc = 1 and start&vn. = 1 and v2 = 0 and end&vn. = . then end&vn. = 2; else 
if calc = 1 and start&vn. = 1 and v3 = 0 and end&vn. = . then end&vn. = 3; else  
if calc = 1 and start&vn. = 1 and v4 = 0 and end&vn. = . then end&vn. = 4; else  
if calc = 1 and start&vn. = 1 and v5 = 0 and end&vn. = . then end&vn. = 5; else  
if calc = 1 and start&vn. = 1 and v6 = 0 and end&vn. = . then end&vn. = 6; else  
if calc = 1 and start&vn. = 1 and v7 = 0 and end&vn. = . then end&vn. = 7; else  
if calc = 1 and start&vn. = 1 and v8 = 0 and end&vn. = . then end&vn. = 8; else  
if calc = 1 and start&vn. = 1 and v9 = 0 and end&vn. = . then end&vn. = 9; else  
if calc = 1 and start&vn. = 1 and v10 = 0 and end&vn. = . then end&vn. = 10; else  
if calc = 1 and start&vn. = 1 and v11 = 0 and end&vn. = . then end&vn. = 11; else  
if calc = 1 and start&vn. = 1 and v12 = 0 and end&vn. = . then end&vn. = 12; else  
if calc = 1 and start&vn. = 1 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 1 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 1 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 1 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 1 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 1 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 1 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 1 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 1 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 2 and v3 = 0 and end&vn. = . then end&vn. = 3; else  
if calc = 1 and start&vn. = 2 and v4 = 0 and end&vn. = . then end&vn. = 4; else  
if calc = 1 and start&vn. = 2 and v5 = 0 and end&vn. = . then end&vn. = 5; else  
if calc = 1 and start&vn. = 2 and v6 = 0 and end&vn. = . then end&vn. = 6; else  
if calc = 1 and start&vn. = 2 and v7 = 0 and end&vn. = . then end&vn. = 7; else  
if calc = 1 and start&vn. = 2 and v8 = 0 and end&vn. = . then end&vn. = 8; else  
if calc = 1 and start&vn. = 2 and v9 = 0 and end&vn. = . then end&vn. = 9; else  
if calc = 1 and start&vn. = 2 and v10 = 0 and end&vn. = . then end&vn. = 10; else  
if calc = 1 and start&vn. = 2 and v11 = 0 and end&vn. = . then end&vn. = 11; else  
if calc = 1 and start&vn. = 2 and v12 = 0 and end&vn. = . then end&vn. = 12; else  
if calc = 1 and start&vn. = 2 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 2 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 2 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 2 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 2 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 2 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 2 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 2 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 2 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 3 and v4 = 0 and end&vn. = . then end&vn. = 4; else  
if calc = 1 and start&vn. = 3 and v5 = 0 and end&vn. = . then end&vn. = 5; else  
if calc = 1 and start&vn. = 3 and v6 = 0 and end&vn. = . then end&vn. = 6; else  
if calc = 1 and start&vn. = 3 and v7 = 0 and end&vn. = . then end&vn. = 7; else  
if calc = 1 and start&vn. = 3 and v8 = 0 and end&vn. = . then end&vn. = 8; else  
if calc = 1 and start&vn. = 3 and v9 = 0 and end&vn. = . then end&vn. = 9; else  
if calc = 1 and start&vn. = 3 and v10 = 0 and end&vn. = . then end&vn. = 10; else  
if calc = 1 and start&vn. = 3 and v11 = 0 and end&vn. = . then end&vn. = 11; else  
if calc = 1 and start&vn. = 3 and v12 = 0 and end&vn. = . then end&vn. = 12; else  
if calc = 1 and start&vn. = 3 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 3 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 3 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 3 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 3 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 3 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 3 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 3 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 3 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 4 and v5 = 0 and end&vn. = . then end&vn. = 5; else  
if calc = 1 and start&vn. = 4 and v6 = 0 and end&vn. = . then end&vn. = 6; else  
if calc = 1 and start&vn. = 4 and v7 = 0 and end&vn. = . then end&vn. = 7; else  
if calc = 1 and start&vn. = 4 and v8 = 0 and end&vn. = . then end&vn. = 8; else  
if calc = 1 and start&vn. = 4 and v9 = 0 and end&vn. = . then end&vn. = 9; else  
if calc = 1 and start&vn. = 4 and v10 = 0 and end&vn. = . then end&vn. = 10; else  
if calc = 1 and start&vn. = 4 and v11 = 0 and end&vn. = . then end&vn. = 11; else  
if calc = 1 and start&vn. = 4 and v12 = 0 and end&vn. = . then end&vn. = 12; else  
if calc = 1 and start&vn. = 4 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 4 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 4 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 4 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 4 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 4 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 4 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 4 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 4 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 5 and v6 = 0 and end&vn. = . then end&vn. = 6; else  
if calc = 1 and start&vn. = 5 and v7 = 0 and end&vn. = . then end&vn. = 7; else  
if calc = 1 and start&vn. = 5 and v8 = 0 and end&vn. = . then end&vn. = 8; else  
if calc = 1 and start&vn. = 5 and v9 = 0 and end&vn. = . then end&vn. = 9; else  
if calc = 1 and start&vn. = 5 and v10 = 0 and end&vn. = . then end&vn. = 10; else  
if calc = 1 and start&vn. = 5 and v11 = 0 and end&vn. = . then end&vn. = 11; else  
if calc = 1 and start&vn. = 5 and v12 = 0 and end&vn. = . then end&vn. = 12; else  
if calc = 1 and start&vn. = 5 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 5 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 5 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 5 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 5 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 5 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 5 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 5 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 5 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 6 and v7 = 0 and end&vn. = . then end&vn. = 7; else  
if calc = 1 and start&vn. = 6 and v8 = 0 and end&vn. = . then end&vn. = 8; else  
if calc = 1 and start&vn. = 6 and v9 = 0 and end&vn. = . then end&vn. = 9; else  
if calc = 1 and start&vn. = 6 and v10 = 0 and end&vn. = . then end&vn. = 10; else  
if calc = 1 and start&vn. = 6 and v11 = 0 and end&vn. = . then end&vn. = 11; else  
if calc = 1 and start&vn. = 6 and v12 = 0 and end&vn. = . then end&vn. = 12; else  
if calc = 1 and start&vn. = 6 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 6 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 6 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 6 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 6 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 6 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 6 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 6 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 6 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 7 and v8 = 0 and end&vn. = . then end&vn. = 8; else  
if calc = 1 and start&vn. = 7 and v9 = 0 and end&vn. = . then end&vn. = 9; else  
if calc = 1 and start&vn. = 7 and v10 = 0 and end&vn. = . then end&vn. = 10; else  
if calc = 1 and start&vn. = 7 and v11 = 0 and end&vn. = . then end&vn. = 11; else  
if calc = 1 and start&vn. = 7 and v12 = 0 and end&vn. = . then end&vn. = 12; else  
if calc = 1 and start&vn. = 7 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 7 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 7 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 7 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 7 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 7 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 7 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 7 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 7 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 8 and v9 = 0 and end&vn. = . then end&vn. = 9; else  
if calc = 1 and start&vn. = 8 and v10 = 0 and end&vn. = . then end&vn. = 10; else  
if calc = 1 and start&vn. = 8 and v11 = 0 and end&vn. = . then end&vn. = 11; else  
if calc = 1 and start&vn. = 8 and v12 = 0 and end&vn. = . then end&vn. = 12; else  
if calc = 1 and start&vn. = 8 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 8 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 8 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 8 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 8 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 8 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 8 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 8 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 8 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 9 and v10 = 0 and end&vn. = . then end&vn. = 10; else  
if calc = 1 and start&vn. = 9 and v11 = 0 and end&vn. = . then end&vn. = 11; else  
if calc = 1 and start&vn. = 9 and v12 = 0 and end&vn. = . then end&vn. = 12; else  
if calc = 1 and start&vn. = 9 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 9 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 9 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 9 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 9 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 9 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 9 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 9 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 9 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 10 and v11 = 0 and end&vn. = . then end&vn. = 11; else  
if calc = 1 and start&vn. = 10 and v12 = 0 and end&vn. = . then end&vn. = 12; else  
if calc = 1 and start&vn. = 10 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 10 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 10 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 10 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 10 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 10 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 10 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 10 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 10 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 11 and v12 = 0 and end&vn. = . then end&vn. = 12; else  
if calc = 1 and start&vn. = 11 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 11 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 11 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 11 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 11 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 11 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 11 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 11 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 11 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 12 and v13 = 0 and end&vn. = . then end&vn. = 13; else  
if calc = 1 and start&vn. = 12 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 12 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 12 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 12 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 12 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 12 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 12 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 12 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 13 and v14 = 0 and end&vn. = . then end&vn. = 14; else  
if calc = 1 and start&vn. = 13 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 13 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 13 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 13 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 13 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 13 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 13 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 14 and v15 = 0 and end&vn. = . then end&vn. = 15; else  
if calc = 1 and start&vn. = 14 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 14 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 14 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 14 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 14 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 14 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 15 and v16 = 0 and end&vn. = . then end&vn. = 16; else  
if calc = 1 and start&vn. = 15 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 15 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 15 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 15 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 15 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 16 and v17 = 0 and end&vn. = . then end&vn. = 17; else  
if calc = 1 and start&vn. = 16 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 16 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 16 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 16 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 17 and v18 = 0 and end&vn. = . then end&vn. = 18; else  
if calc = 1 and start&vn. = 17 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 17 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 17 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 18 and v19 = 0 and end&vn. = . then end&vn. = 19; else  
if calc = 1 and start&vn. = 18 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 18 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 19 and v20 = 0 and end&vn. = . then end&vn. = 20; else  
if calc = 1 and start&vn. = 19 and v21 = 0 and end&vn. = . then end&vn. = 21;  

if calc = 1 and start&vn. = 20 and v21 = 0 and end&vn. = . then end&vn. = 21;  
%mend;

%res2 (vn=1,  svisit=2); %res2 (vn=1,  svisit=3); %res2 (vn=1,  svisit=4); %res2 (vn=1,  svisit=5); %res2 (vn=1,  svisit=6); %res2 (vn=1,  svisit=7); 
%res2 (vn=1,  svisit=8); %res2 (vn=1,  svisit=9); %res2 (vn=1,  svisit=10); %res2 (vn=1,  svisit=11); %res2 (vn=1,  svisit=12); 
%res2 (vn=1,  svisit=13); %res2 (vn=1,  svisit=14); %res2 (vn=1,  svisit=15); %res2 (vn=1,  svisit=16); %res2 (vn=1,  svisit=17); 
%res2 (vn=1,  svisit=18); %res2 (vn=1,  svisit=19); %res2 (vn=1,  svisit=20); %res2 (vn=1,  svisit=21);

if start1 ^= . and  end1 = . and total_pos = total_vis then end1 = total;

run;

data prev_long_m; set prev_long_m;

length return1 8. start2 8. end2 8. svn 8.;

*residence and return;
if _NAME_ ^= 'Sa_Dp_cat' then start2 = .;

%macro res (start=);
vn = &start.;

if _NAME_ ^= 'Sa_Dp_cat' and start2 = . and v&start. = 1 and vn > end1 and end1 ^= . and end1 ^= total then start2=&start.; 

%mend;

%res (start=1); %res (start=2); %res (start=3); %res (start=4); %res (start=5); %res (start=6); %res (start=7); %res (start=8); %res (start=9); 
%res (start=10); %res (start=11); %res (start=12); %res (start=13); %res (start=14); %res (start=15); %res (start=16); %res (start=17); %res (start=18); 
%res (start=19); %res (start=20); %res (start=21); 

%res2 (vn=2,  svisit=2); %res2 (vn=2,  svisit=3); %res2 (vn=2,  svisit=4); %res2 (vn=2,  svisit=5); %res2 (vn=2,  svisit=6); %res2 (vn=2,  svisit=7); 
%res2 (vn=2,  svisit=8); %res2 (vn=2,  svisit=9); %res2 (vn=2,  svisit=10); %res2 (vn=2,  svisit=11); %res2 (vn=2,  svisit=12); 
%res2 (vn=2,  svisit=13); %res2 (vn=2,  svisit=14); %res2 (vn=2,  svisit=15); %res2 (vn=2,  svisit=16); %res2 (vn=2,  svisit=17); 
%res2 (vn=2,  svisit=18); %res2 (vn=2,  svisit=19); %res2 (vn=2,  svisit=20); %res2 (vn=2,  svisit=21);

if start2 ^= . and  end2 = . and total_pos = total_vis then end2 = total;

run;

data prev_long_m; set prev_long_m;

length return2 8. start3 8. end3 8. svn 8.;

*residence and return;
if _NAME_ ^= 'Sa_Dp_cat' then start3 = .;

%macro res (start=);
vn = &start.;

if _NAME_ ^= 'Sa_Dp_cat' and start3 = . and v&start. = 1 and vn > end2 and end2 ^= . and end2 ^= total then start3=&start.; 

%mend;

%res (start=1); %res (start=2); %res (start=3); %res (start=4); %res (start=5); %res (start=6); %res (start=7); %res (start=8); %res (start=9); 
%res (start=10); %res (start=11); %res (start=12); %res (start=13); %res (start=14); %res (start=15); %res (start=16); %res (start=17); %res (start=18); 
%res (start=19); %res (start=20); %res (start=21); 


%res2 (vn=3,  svisit=2); %res2 (vn=3,  svisit=3); %res2 (vn=3,  svisit=4); %res2 (vn=3,  svisit=5); %res2 (vn=3,  svisit=6); %res2 (vn=3,  svisit=7); 
%res2 (vn=3,  svisit=8); %res2 (vn=3,  svisit=9); %res2 (vn=3,  svisit=10); %res2 (vn=3,  svisit=11); %res2 (vn=3,  svisit=12); 
%res2 (vn=3,  svisit=13); %res2 (vn=3,  svisit=14); %res2 (vn=3,  svisit=15); %res2 (vn=3,  svisit=16); %res2 (vn=3,  svisit=17); 
%res2 (vn=3,  svisit=18); %res2 (vn=3,  svisit=19); %res2 (vn=3,  svisit=20); %res2 (vn=3,  svisit=21);

if start3 ^= . and  end3 = . and total_pos = total_vis then end3 = total;

run;

data prev_long_m; set prev_long_m;

length return3 8. start4 8. end4 8. svn 8.;

*residence and return;
if _NAME_ ^= 'Sa_Dp_cat' then start4 = .;

%macro res (start=);
vn = &start.;

if _NAME_ ^= 'Sa_Dp_cat' and start4 = . and v&start. = 1 and vn > end3 and end3 ^= . and end3 ^= total then start4=&start.; 

%mend;

%res (start=1); %res (start=2); %res (start=3); %res (start=4); %res (start=5); %res (start=6); %res (start=7); %res (start=8); %res (start=9); 
%res (start=10); %res (start=11); %res (start=12); %res (start=13); %res (start=14); %res (start=15); %res (start=16); %res (start=17); %res (start=18); 
%res (start=19); %res (start=20); %res (start=21); 

%res2 (vn=4,  svisit=3); %res2 (vn=4,  svisit=4); %res2 (vn=4,  svisit=5); %res2 (vn=4,  svisit=6); %res2 (vn=4,  svisit=7); 
%res2 (vn=4,  svisit=8); %res2 (vn=4,  svisit=9); %res2 (vn=4,  svisit=10); %res2 (vn=4,  svisit=11); %res2 (vn=4,  svisit=12); 
%res2 (vn=4,  svisit=13); %res2 (vn=4,  svisit=14); %res2 (vn=4,  svisit=15); %res2 (vn=4,  svisit=16); %res2 (vn=4,  svisit=17); 
%res2 (vn=4,  svisit=18); %res2 (vn=4,  svisit=19); %res2 (vn=4,  svisit=20); %res2 (vn=4,  svisit=21);

if start4 ^= . and end4 = . and total_pos = total_vis then end4 = total;

run;

data prev_long_m; 
	merge prev_long_m (in=a) timing_long;
	by new_number;
	if a;
	drop svn vn calc;
run;

data prev_long_m; set prev_long_m;

*Generate start and end dates for residence and return times using duration data;


	*Average res / return;
	avg_res_w = mean(res_w_1, res_w_2, res_w_3, res_w_4);

	avg_ret_w = mean(ret_w_1, ret_w_2, ret_w_3);

	max_res_w = MAX(res_w_1, res_w_2, res_w_3, res_w_4);

	max_ret_w = MAX(ret_w_1, ret_w_2, ret_w_3);

	*Proportion of visits;
	prop_pos = total_pos / total_vis;

	*Put end date for missing;
	if start1 ^= . and end1 = . then end1 = total; else
	if start2 ^= . and end2 = . then end2 = total; else
	if start3 ^= . and end3 = . then end3 = total; else
	if start4 ^= . and end4 = . then end4 = total;

run;

* Long dataset with metrics ;
data metrics; set prev_long_m;

keep taxa new_number avg_res_w avg_ret_w prop_pos;
run;

proc sort data=nasal_prop_long; by new_number taxa; run;
proc sort data=metrics; by new_number taxa; run;
	
data nasal_prop_long;
	merge nasal_prop_long (in=a) metrics;
	if a;
	by new_number taxa;
run;

proc sort data=nasal_abs_long; by new_number taxa; run;
proc sort data=metrics; by new_number taxa; run;
	
data nasal_abs_long;
	merge nasal_abs_long (in=a) metrics;
	if a;
	by new_number taxa;
run;


*Dominant CSTs;
data prev_long_m_cst; set prev_long_m;

	%macro sumcst (var= );
	if _LABEL_ = "&var." then sum_&var. = sum (v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19, v20, v21);
	%mend;

%sumcst (var=CST1a);
%sumcst (var=CST1b);
%sumcst (var=CST2a);
%sumcst (var=CST2b);
%sumcst (var=CST3);
%sumcst (var=CST4a);
%sumcst (var=CST4b); *4b = 9a , 6a = 9b;
%sumcst (var=CST5a);
%sumcst (var=CST5b);
%sumcst (var=CST6a);
%sumcst (var=CST6b);
%sumcst (var=CST7);
%sumcst (var=CST8);

%macro domcst (var=);
	prop_&var. =  sum_&var. / total_vis ;
	if prop_&var. >= 0.5 then dom_&var. = 1;
%mend;

%domcst (var=CST7);
%domcst (var=CST1a);
%domcst (var=CST1b);
%domcst (var=CST2a);
%domcst (var=CST2b);
%domcst (var=CST3);
%domcst (var=CST4a);
%domcst (var=CST4b);
%domcst (var=CST5a);
%domcst (var=CST5b);
%domcst (var=CST6a);
%domcst (var=CST6b);
%domcst (var=CST8);

	prop_CST1 = sum(prop_CST1a, prop_CST1b);
	if prop_CST1 >= 0.5 then dom_CST1 = 1;

	prop_CST5 = sum(prop_CST5a, prop_CST5b);
	if prop_CST5 >= 0.5 then dom_CST5 = 1;

keep new_number dom_CST1 dom_CST1a dom_CST1b dom_CST2a dom_CST2b dom_CST3 dom_CST4a dom_CST4b dom_CST5 dom_CST5a dom_CST5b dom_CST6a dom_CST6b dom_CST7 dom_CST8
	prop_CST1 prop_CST1a prop_CST1b prop_CST2a prop_CST2b prop_CST3 prop_CST4a prop_CST4b prop_CST5 prop_CST5a prop_CST5b prop_CST6a prop_CST6b prop_CST7 prop_CST8;
run;

*-;
*Update dominant CSTs here;

data prev_long_m_cst; set prev_long_m_cst;

length dom_CST $7.;

if dom_CST1 = 1 then delete = 0; else
if dom_CST1a = 1 then delete = 0; else
if dom_CST1b = 1 then delete = 0; else
if dom_CST5 = 1 then delete = 0; else
if dom_CST4a = 1 then delete = 0; else
if dom_CST7 = 1 then delete = 0; else
delete = 1;

if delete = 1 then delete;

if dom_CST1 = 1 then dom_CST = 'CST1'; else
if dom_CST1a = 1 then dom_CST = 'CST1a'; else
if dom_CST1b = 1 then dom_CST = 'CST1b'; else
if dom_CST4a = 1 then dom_CST = 'CST4'; else
if dom_CST5 = 1 then dom_CST = 'CST5'; else
if dom_CST7 = 1 then dom_CST = 'CST7'; 

keep new_number dom_CST ;
run;

data prev_long_m;
	merge prev_long_m prev_long_m_cst;
	by new_number;
run;
*-------------;

proc format ;
value p_cat 0='Not detected' 1='0-25%' 2='25-50%' 3='50-75%' 4='75-100%';
value p_cat_two 1='0-25%' 2='25-75%' 3='75-100%';
value $CST_Prop '1'='C. accolens' '2'='Cutibacterium' '3'='Finegoldia/Pep/Anaero' '4'='M. cat/nonliq' '5'='Dp/C. pseudo' '6a'='S. aureus-high' '6b'='S. aureus-med' '7'='S. epi' 
			'8'='C. segment' '9'='M. nonliq' '10'='Bacillus' '11'='Entero' '12'='Haemophilus';
value $CST_Prop_two '1a'='S. aureus-high' '1b'='S. aureus-med' '2b'='Entero' '2a'='Bacillus' '3'='S. epi' '4a'='Cutibacterium' '4b'='Finegoldia/Pep/Anaero' 
			'5a' = 'C. accolens' '5b'='C. segment'  '6a'='M. cat/nonliq' '6b'='M. nonliq' '7'='Dp/C. pseudo'  '8'='Haemophilus';
run;

*-------------;


*Analysis of covariates;
proc freq data=nasal_prev;
table longitudinal * visit_n / missing;
run;

proc freq data=nasal_prev;
title 'At baseline';
table age10 season gender household dog cat ;
where visit_n = 1 and longitudinal = 1;
run;

*median follow-up and IQR;
proc means data=prev_long_m n median q1 q3;
var res_m_1;
where taxa = "Count";
run;

*--------------------------;
*CSTs;

proc freq data=nasal_prop;
table CST_Prop;
format CST_Prop $CST_Prop.;
run;

proc freq data=nasal_prop;
table CST_Prop;
format CST_Prop $CST_Prop.;
where visit_n = 1 ;
run;

*------------------------;
*Proportional abundance;
proc means data=nasal_prop maxdec=4;;
var &full_list;
where visit_number = 'v1';
run;

*Absolute abundance;
%macro absab (taxa= );
proc means data=nasal_abs maxdec=0 median q1 q3;
var &taxa.;
where visit_number = 'v1' and &taxa. > 0;
run;
%mend;

%absab (taxa=Haemophilus_influenzae);

*--------------------------;
*Residence and Return Times;

proc means data=prev_long_m n mean std maxdec=1;
var avg_res_w avg_res_m;
where taxa = 'Count';
run;

%macro taxa (taxa= );
proc means data=prev_long_m n mean std maxdec=1;
title "&taxa.";
var avg_res_w avg_ret_w;
where taxa = &taxa.;
run;

proc sgplot data=prev_long_m;
title "&taxa.";
histogram avg_res_w;
where taxa = &taxa.;
run;

proc sgplot data=prev_long_m;
title "&taxa.";
histogram avg_ret_w;
where taxa = &taxa.;
run;
title;
%mend;

%taxa (taxa='Staphylococcus_epidermidis_m');
%taxa (taxa='Staphylococcus_aureus_m'); 
%taxa (taxa='Dolosigranulum');
%taxa (taxa='C_accolens');
%taxa (taxa='Haemophilus_influenzae');
%taxa (taxa='Propionibacterium');
%taxa (taxa='Streptococcus_pneumoniae');

%taxa (taxa='CST1'); %taxa (taxa='CST2'); %taxa (taxa='CST3');
%taxa (taxa='CST4'); %taxa (taxa='CST5'); %taxa (taxa='CST6a'); %taxa (taxa='CST6b');
%taxa (taxa='CST7'); %taxa (taxa='CST8'); %taxa (taxa='CST9');
%taxa (taxa='CST10'); %taxa (taxa='CST11'); %taxa (taxa='CST12');

%taxa (taxa='Sa_Dp_Both'); 

proc reg data=prev_long_m;
model avg_res_w =avg_ret_w ;
where total_vis > 1;
run;

proc sort data=prev_long_m; by taxa; run; 

proc loess data=prev_long_m;
by taxa;
model avg_res_w =avg_ret_w ;
run;

proc nlin data=prev_long_m;
parms alpha=.45 beta=.05 gamma=-.0025;
avg_ret_w0 = -.5*beta / gamma;

   if (avg_ret_w < avg_ret_w0) then
        avg_ret_w = alpha + beta*avg_ret_w  + gamma*avg_ret_w*avg_ret_w;
   else avg_ret_w = alpha + beta*avg_ret_w0 + gamma*avg_ret_w0*avg_ret_w0;
   model avg_res_w = avg_ret_w;

   if _obs_=1 and _iter_ =.  then do;
      plateau =alpha + beta*avg_ret_w0 + gamma*avg_ret_w0*avg_ret_w0;
      put /  avg_ret_w0= plateau=  ;
   end;
   output out=b predicted=avg_res_wp;
where taxa notin ('Count' 'Sa_Dp_cat' 'Dp_only' 'Sa_Dp_Both' 'Sa_only' 'Sa_Dp_None') and total_vis > 1;
run;

proc sgplot data=b noautolegend;
   yaxis label='Observed or Predicted';
   refline 0.0  / axis=y label="Plateau"    labelpos=min;
   scatter y=avg_res_w  x=avg_ret_w;
   reg  y=avg_res_wp x=avg_ret_w;
run;

title;

*Indicator Taxa;
proc means data=prev_long_m mean median std q1 q3 clm maxdec=3;
var prop_pos  ;
class taxa;
where _NAME_ notin ('Count' 'Sa_Dp_cat' 'Dp_only' 'Sa_Dp_Both' 'Sa_only' 'Sa_Dp_None') and total_vis > 1;
run;

proc sgplot data=prev_long_m noautolegend;
hbox avg_res_w / category=taxa nooutliers;
scatter x=avg_res_w y=taxa / jitter markerattrs=(size=4);
refline 68.9 / axis=x label='Mean total duration';
xaxis label = 'Residence time (weeks)';
yaxis label = 'Taxa';
where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphyloccus_aureus_m' 'Staphylococcus_epidermidis_m'
			'Streptococcus_pneumoniae')  and total_vis>1;
run;

proc sgplot data=prev_long_m noautolegend;
hbox avg_ret_w / category=taxa nooutliers fillattrs=(color=tan);
scatter x=avg_ret_w y=taxa / jitter markerattrs=(size=4 color=darktan);
refline 68.9 / axis=x label='Mean total duration';
xaxis label = 'Return time (weeks)';
yaxis label = 'Taxa';
where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphyloccus_aureus_m' 'Staphylococcus_epidermidis_m'
			'Streptococcus_pneumoniae')  and total_vis>1;
run;

*by CST;

proc freq data=prev_long_m;
table dom_cst * _NAME_;
where  total_vis>1 and _NAME_ = "Count";
run;

proc freq data=prev_long_m;
table dom_CST;
where total_vis>1 and _NAME_ = 'Count';
run;

proc means data=prev_long_m mean std maxdec=1;
var  avg_res_w;
class taxa;
where _NAME_ in ('C_accolens' 'C_tuberculostearicum' 'Micrococcus' 'Dolosigranulum' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m')  and total_vis>1;
run;

%macro wilcox (var= );
proc npar1way data=prev_long_m ;
var  avg_res_w;
class dom_CST;
where _NAME_ = &var.;
run;
%mend;
%wilcox (var='Micrococcus');
%wilcox (var='Dolosigranulum' );
%wilcox (var='Staphylococcus_aureus_m' );
%wilcox (var='Staphylococcus_epidermidis_m');

proc ttest data=prev_long_m ;
var  avg_res_w;
class dom_CST;
where _NAME_ = 'Staphylococcus_epidermidis_m' and dom_CST in ("CST1" "CST5");
run;

proc sgpanel data=prev_long_m noautolegend;
panelby dom_CST / columns=1;
hbox avg_ret_w / category=taxa  nooutliers;
scatter x=avg_ret_w y=taxa / jitter markerattrs=(size=4);
refline 68.9 / axis=x /* label='Mean total duration' */;
where _NAME_ in (/* 'C_accolens' */ 'C_pseudo'  'Dolosigranulum' /* 'Haemophilus_influenzae' */ 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
			'Streptococcus_pneumoniae')  and total_vis>1;
format dom_CST $CST_prop.;
run;

proc means data=prev_long_m mean std maxdec=1;
var  avg_ret_w;
class taxa;
where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
			'Streptococcus_pneumoniae')  and total_vis>1;
run;

proc npar1way data=prev_long_m wilcoxon;
var  avg_ret_w;
class taxa;
where _NAME_ in (/* 'C_accolens' */ 'C_pseudo' /* 'Dolosigranulum' 'Haemophilus_influenzae' */ 'Moraxella_cat_nonliq' /* 'Propionibacterium' 'Staphylococcus_aureus_m' */ /* 'Staphylococcus_epidermidis_m' */
			/* 'Streptococcus_pneumoniae' */)  and total_vis>1;
run;

*-----;
*CSTs;
proc means data=prev_long_m mean median std q1 q3 clm maxdec=3 ;
var prop_pos  ;
class _LABEL_;
where _LABEL_ in ('CST1a' 'CST1b' 'CST2a' 'CST2b' 'CST3' 'CST4a' 'CST4b' 'CST5a' 'CST5b' 'CST6a' 'CST6b' 'CST7' 'CST8') and total_vis > 1;
run;

proc sgplot data=prev_long_m noautolegend;
hbox avg_res_w / category=_LABEL_ nooutliers;
scatter x=avg_res_w y=_LABEL_ / jitter markerattrs=(size=4);
refline 68.9 / axis=x label='Mean total duration';
xaxis label = 'Residence time (weeks)';
yaxis label = 'CST';
where _LABEL_ in ('CST1a' 'CST1b' 'CST2a' 'CST2b' 'CST3' 'CST4a' 'CST4b' 'CST5a' 'CST5b' 'CST6a' 'CST6b' 'CST7' 'CST8') and total_vis > 1;
run;

proc sgplot data=prev_long_m noautolegend;
hbox avg_ret_w / category=_LABEL_ nooutliers fillattrs=(color=tan);
scatter x=avg_ret_w y=_LABEL_ / jitter markerattrs=(size=4 color=darktan);
refline 68.9 / axis=x label='Mean total duration';
xaxis label = 'Return time (weeks)';
yaxis label = 'Taxa';
where _LABEL_ in ('CST1a' 'CST1b' 'CST2a' 'CST2b' 'CST3' 'CST4a' 'CST4b' 'CST5a' 'CST5b' 'CST6a' 'CST6b' 'CST7' 'CST8') and total_vis > 1;
run;

proc means data=prev_long_m mean std maxdec=1;
var  avg_res_w;
class _LABEL_ ;
where _LABEL_ in ('CST1a' 'CST1b' 'CST2a' 'CST2b' 'CST3' 'CST4a' 'CST4b' 'CST5a' 'CST5b' 'CST6a' 'CST6b' 'CST7' 'CST8') and total_vis > 1  ;
run;

proc npar1way data=prev_long_m wilcoxon;
var  avg_res_w;
class _LABEL_;
where _LABEL_ in ('CST1a' 'CST1b' 'CST2a' /* 'CST2b' */ 'CST3' 'CST4a' 'CST4b' 'CST5a' 'CST5b' 'CST6a' 'CST6b' 'CST7' /* 'CST8' */) and total_vis > 1;
run;


*Avg res / ret by abundance;
*Indicator taxa;
proc means data=nasal_prop_long;
var avg_res_w mean_prop_ab ;
class taxa;
where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
'Streptococcus_pneumoniae');
run;

*all;
proc means data=nasal_prop_long;
var avg_res_w mean_prop_ab ;
class taxa;
where _NAME_ notin ('Count' 'count' 'season' 'Sa_Dp_cat' 'Dp_only' 'Sa_Dp_Both' 'Sa_only' 'Sa_Dp_None' 'Mc_Dp_Both' 'Mc_Dp_None' 'Mc_only');

run;

proc mixed data=nasal_prop_long;
class new_number taxa ;
model avg_res_w = mean_prop_ab ;
repeated new_number / subject = taxa ;
where _NAME_ notin ('CST1' 'CST2' 'CST3' 'CST4' 'CST5' 'CST6a' 'CST6b' 'CST7' 'CST8' 'CST9' 'CST10' 'CST11' 'CST12');
*where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
'Streptococcus_pneumoniae');
run;

proc mixed data=nasal_prop_long;
class new_number taxa ;
model avg_res_w = mean_prop_ab taxa;
repeated new_number / subject = taxa ;
where _NAME_ notin ('CST1' 'CST2' 'CST3' 'CST4' 'CST5' 'CST6a' 'CST6b' 'CST7' 'CST8' 'CST9' 'CST10' 'CST11' 'CST12');
*where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
'Streptococcus_pneumoniae');
run;

*Prop ab;
proc glm data=nasal_prop_long;
class new_number taxa ;
model avg_res_w = mean_prop_ab taxa;
where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
'Streptococcus_pneumoniae');
run;

*Prop ab with taxa;
proc glm data=nasal_prop_long;
class new_number taxa ;
model avg_res_w = mean_prop_ab taxa;
where _NAME_ notin ('CST1' 'CST2' 'CST3' 'CST4' 'CST5' 'CST6a' 'CST6b' 'CST7' 'CST8' 'CST9' 'CST10' 'CST11' 'CST12');
*where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
'Streptococcus_pneumoniae');
run;

*also by gender;
proc sort data=nasal_prop_long; by new_number; run;
proc sort data=cov; by new_number; run;

data nasal_prop_long;
merge nasal_prop_long cov (keep = new_number gender);
by new_number;
run;

proc glm data=nasal_prop_long;
class new_number taxa gender;
model avg_res_w =  mean_prop_ab taxa gender taxa*gender;
*where _NAME_ notin ('CST1' 'CST2' 'CST3' 'CST4' 'CST5' 'CST6a' 'CST6b' 'CST7' 'CST8' 'CST9' 'CST10' 'CST11' 'CST12');
where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
'Streptococcus_pneumoniae');
run;

proc sort data=nasal_prop_long; by new_number; run;
proc sort data=nasal_abs; by new_number; run;

data nasal_prop_long;
merge nasal_prop_long nasal_abs (keep = new_number gender l_std_qty);
by new_number;
run;

*total density and gender;
proc glm data=nasal_prop_long;
class new_number taxa gender;
model avg_res_w = taxa  l_std_qty gender mean_prop_ab;
where _NAME_ notin ('CST1' 'CST2' 'CST3' 'CST4' 'CST5' 'CST6a' 'CST6b' 'CST7' 'CST8' 'CST9' 'CST10' 'CST11' 'CST12');
*where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
'Streptococcus_pneumoniae');
run;

*Abs ab - abundance;
proc glm data=nasal_abs_long;
class new_number taxa ;
model avg_res_w = mean_abs_ab ;
*where _NAME_ notin ('CST1' 'CST2' 'CST3' 'CST4' 'CST5' 'CST6a' 'CST6b' 'CST7' 'CST8' 'CST9' 'CST10' 'CST11' 'CST12');
where _NAME_ in ('C_accolens' 'C_pseudo' 'Dolosigranulum' 'Haemophilus_influenzae' 'Moraxella_cat_nonliq' 'Propionibacterium' 'Staphylococcus_aureus_m' 'Staphylococcus_epidermidis_m'
'Streptococcus_pneumoniae');
run;

proc glm data=nasal_abs_long;
class new_number taxa ;
model avg_res_w = mean_abs_ab  taxa mean_abs_ab * taxa;
where _NAME_ notin ('CST1' 'CST2' 'CST3' 'CST4' 'CST5' 'CST6a' 'CST6b' 'CST7' 'CST8' 'CST9' 'CST10' 'CST11' 'CST12');
run;

*also by gender;
proc sort data=nasal_abs_long; by new_number; run;
proc sort data=nasal_abs; by new_number; run;

data nasal_abs_long;
merge nasal_abs_long nasal_abs (keep = new_number gender l_std_qty);
by new_number;
run;
*total density and gender;
proc glm data=nasal_abs_long;
class new_number taxa gender;
model avg_res_w = taxa  l_std_qty gender;
where _NAME_ notin ('CST1' 'CST2' 'CST3' 'CST4' 'CST5' 'CST6a' 'CST6b' 'CST7' 'CST8' 'CST9' 'CST10' 'CST11' 'CST12');
run;

*Prevalence as predictor;
proc glm data=nasal_prop_long;
class new_number taxa ;
model avg_res_w = prop_pos taxa ;
where _NAME_ notin ('CST1' 'CST2' 'CST3' 'CST4' 'CST5' 'CST6a' 'CST6b' 'CST7' 'CST8' 'CST9' 'CST10' 'CST11' 'CST12');
run;

*Prevalence as outcome;
proc glm data=nasal_prop_long;
class new_number taxa ;
model prop_pos  = avg_res_w avg_ret_w taxa;
where _NAME_ notin ('CST1' 'CST2' 'CST3' 'CST4' 'CST5' 'CST6a' 'CST6b' 'CST7' 'CST8' 'CST9' 'CST10' 'CST11' 'CST12');
run;
quit;


*--------------------------------------------;

*============================================;
*Short Term Dynamics;
*============================================;

*Overall prop ab;
proc means data=nasal_prop_long mean std; 
var p_2_1 p_3_2 p_4_3 p_5_4 p_6_5 p_7_6 p_8_7 p_9_8 p_10_9 p_11_10 p_12_11 p_13_12 p_14_13 p_15_14 p_16_15 p_17_16 p_18_17 p_19_18 p_20_19 p_21_20;
where taxa notin ('count' 'season');
run;

proc sgplot data=nasal_prop_long;
histogram p_2_1 / transparency=0.5 binwidth=0.5;
histogram p_3_2 / transparency=0.55 binwidth=0.5;
histogram p_4_3 / transparency=0.6 binwidth=0.5;
histogram p_5_4 / transparency=0.65 binwidth=0.5;
histogram p_6_5 / transparency=0.7 binwidth=0.5;
histogram p_7_6 / transparency=0.75 binwidth=0.5;
histogram p_8_7 / transparency=0.8 binwidth=0.5;
histogram p_9_8 / transparency=0.85 binwidth=0.5;
histogram p_10_9 / transparency=0.9 binwidth=0.5;
where taxa notin ('count' 'season');
run;

proc sgpanel data=nasal_prop_long;
panelby taxa / rows=3 columns=3;
histogram mean_prop_change / transparency=0.5 binwidth=0.5;
where taxa notin ('count' 'season' );
run;

proc sgplot data=nasal_prop_long;
histogram mean_prop_change /  binwidth=0.25;
where taxa notin ('count' 'season');
run;

*-;
*Relationship b/w SD and daily ab changes;
proc means data=nasal_prop_long mean std;
var mean_prop_change mean_prop ;
class taxa;
where taxa notin ('count' 'season');
run;


*Taylor's Power Law and Taxa associated with Perturbations;
proc means data=nasal_prop mean std ;
var &full_list.;

*class taxa;
output out=means;
run;

data means; set means;
if _STAT_ in ('N' 'MIN' 'MAX') then delete;
drop _TYPE_ _FREQ_;
run;

proc transpose data=means out=means;
id  _stat_;
run;

data means ; set means;
if _NAME_ in ('Staphylococcus_aureus_m' 'Moraxella_cat_nonliq' 'Haemophilus_influenzae' 'Streptococcus_pneumoniae') then TaxaCat=1; else
if _NAME_ in ('Dolosigranulum' 'C_accolens' 'C_pseudo' 'Corynebacterium_other' 'C_tuberculostearicum' 'C_segmentosum') then TaxaCat=2; else
if _NAME_ in ('Staphylococcus_epidermidis_m' 'Propionibacterium') then TaxaCat=3; else
if _NAME_ in ('Peptoniphilus' 'Anaerococcus' 'Finegoldia') then TaxaCat=4;
run;

proc format ;
value TaxaCat 1='Bad: Sa/Mc/Hi/Sp' 2='NasalMb: Dp/Ca/Cp/Ct/Cs' 3='Skin:Sepi/Propioni' 4='Anaerobes: Pepton/Anaer/FineG';
run;

proc sgplot data=means;
scatter x=mean y=std / group=TaxaCat markerattrs=(size=10 symbol=circlefilled) transparency=0.2;
reg y= std x=mean / nomarkers;
where mean > 0.001;
format TaxaCat TaxaCat.;
run;

proc sgplot data=means;
scatter x=mean y=std / group=TaxaCat markerchar=_NAME_ markerattrs=(size=10 symbol=circlefilled) transparency=0.2;
reg y= std x=mean / nomarkers;
where mean > 0.001;
format TaxaCat TaxaCat.;
run;

proc sgplot data=means;
reg y= std x=mean / group=TaxaCat /*nomarkers*/;
where mean > 0.001;
format TaxaCat TaxaCat.;
run;

*--------------------------------;
