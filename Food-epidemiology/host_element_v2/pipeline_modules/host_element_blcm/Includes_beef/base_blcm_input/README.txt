Decision made Aug 21 2024 (Dan+Maliha+team) see slack for details
retain only 49 FZEC from BigFUTI and 1 from DCFUTI as Test (training=0). Delete the rest of the FZEC from BigFUT and DCFUTI
it has 7 contaminated meats as Test (training=0) ok-ed by Dan
BIGFUT-DCFUTI (reduced FZEC) is here -> ref_file/070924_any_element_presence_input_bigfuti_dcfuti.xlsx

Update 08/20/25 -- Edward Sung
082025_any_element_presence_input_bigfuti_dcfuti.csv
	This updates the columns to be Host labels with kmodes clustering [1 or 2]
	Updates the Presence Absence of the N=17 Elements based on mmseq2 results and Olivia's CE presentation rule sets

Update 10/21/25 -- Edward Sung
102125_any_element_presence_input_bigfuti_dcfuti_ExcludesBeef.csv
	This version created does not include beef catagory in training, thus cannot predict for beef class.
	R Code base will reflect this as well.
