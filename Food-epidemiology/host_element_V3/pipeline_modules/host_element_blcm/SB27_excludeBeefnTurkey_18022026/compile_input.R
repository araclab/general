suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library())

## command line options
opt_lst <- list(
  make_option(c("-s","--SB27"),
              help = "Base SB27 input as a CSV file"),
  make_option(c("-k","--kmodes"),
              help = "kmodes predictions: CSV with Sample_ID and predictions"),
  make_option(c("-m","--mlst"),
              help = "mlst predictions: CSV with sample_ID and ST"),
  make_option(c("-e", "--elements"),
              help = "elements: TSV with Sample_ID and element presence/absence"),
  make_option(c("-t","--host"),
              help = "Host labels: TSV with sample_ID and Host"),
  make_option(c("-o","--output"),
              help = "this is the output location of the input")
)
# build the argument parser
parser <- OptionParser(option_list = opt_lst,
                       description = "script to create input for Bayesian latent class analysis")
# Read command line arguments
arguments <- parse_args(parser,
                        positional_arguments = TRUE)
#store the parsed option values
opts <- arguments$options

#get arguements
sb27_file <- opts$SB27
kmodes_file <- opts$kmodes
mlst_file <- opts$mlst
elements_file <- opts$elements
host_file <- opts$host
output_dir <- opts$output

#test cmd
#Rscript compile_input.R -s base_blcm_input/SB27_raw_input_26022026.csv -k testing_input_generation/test_cgmlst_kmodes_ready_inputfile__Cluster_2__kmodes_cgmlst_clustering_predictions.csv -m testing_input_generation/results_compiled.txt -e testing_input_generation/test_element_presence.tsv -t testing_input_generation/sample_host.tsv -o .
#read data
sb27_df <- read_csv(sb27_file)
kmodes_df <- read_csv(kmodes_file)
mlst_df <- read_tsv(mlst_file)
elements_df <- read_tsv(elements_file)
host_df <- read_tsv(host_file)


#testing
#sb27_df <- read_csv("/Users/B328695/Documents/GitHub/general_JonThesis/Food-epidemiology/host_element_V3/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/base_blcm_input/SB27_raw_input_26022026.csv")
#kmodes_df <- read_csv("/Users/B328695/Documents/GitHub/general_JonThesis/Food-epidemiology/host_element_V3/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/testing_input_generation/test_cgmlst_kmodes_ready_inputfile__Cluster_2__kmodes_cgmlst_clustering_predictions.csv")
#mlst_df <- read_tsv("/Users/B328695/Documents/GitHub/general_JonThesis/Food-epidemiology/host_element_V3/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/testing_input_generation/results_compiled.txt")
#elements_df <- read_tsv("/Users/B328695/Documents/GitHub/general_JonThesis/Food-epidemiology/host_element_V3/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/testing_input_generation/test_element_presence.tsv")
#host_df <- read_tsv("/Users/B328695/Documents/GitHub/general_JonThesis/Food-epidemiology/host_element_V3/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/testing_input_generation/sample_host.tsv")
# expected output cols
output_column_names <- colnames(sb27_df)

#standardizing id cols (should always be the first col)
colnames(kmodes_df)[1] <- "Sample_Name"
colnames(mlst_df)[1] <- "Sample_Name"
colnames(elements_df)[1] <- "Sample_Name"
colnames(host_df)[1] <- "Sample_Name"

#create an empty data frame that matches the SB27 input schema.
#ids via element_df
output_df <- elements_df %>%
  select("Sample_Name")
output_df <- output_df %>% 
  mutate(training = 0) %>%
  left_join(mlst_df, by = "Sample_Name") 

#creating Class representation based on kmodes and host
colnames(sb27_df)
head(kmodes_df,5)
head(host_df,5)
kmodes_host_df <- host_df %>%
  left_join(kmodes_df, by = "Sample_Name")
kmodes_host_df$Human_CL1 <- ifelse(kmodes_host_df$cluster_2 == 1 & kmodes_host_df$Host == "Human", 1, 0)
kmodes_host_df$Human_CL2 <- ifelse(kmodes_host_df$cluster_2 == 2 & kmodes_host_df$Host == "Human", 1, 0)
kmodes_host_df$Chicken_CL1 <- ifelse(kmodes_host_df$cluster_2 == 1 & kmodes_host_df$Host == "Chicken", 1, 0)
kmodes_host_df$Chicken_CL2 <- ifelse(kmodes_host_df$cluster_2 == 2 & kmodes_host_df$Host == "Chicken", 1, 0)
kmodes_host_df$Pork <- ifelse(kmodes_host_df$Host == "Pork", 1, 0)
kmodes_host_df$CL1 <- ifelse(kmodes_host_df$cluster_2 == 1, 1, 0)
kmodes_host_df$CL2 <- ifelse(kmodes_host_df$cluster_2 == 2, 1, 0)
#removing 2 cols not to be included in join
kmodes_host_df[2] <- NULL
kmodes_host_df[2] <- NULL

#adding Class source to output_df
output_df <- output_df %>%
  left_join(kmodes_host_df, by = "Sample_Name") %>%
  left_join(elements_df, by = "Sample_Name")

final_output_df <- bind_rows(sb27_df,output_df)

write.csv(
  final_output_df,
  file = file.path(output_dir, "final_blcm_input.csv"),
  row.names = F,
  quote = T
)


