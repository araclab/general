suppressPackageStartupMessages(library(readxl))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(optparse))

required_element_columns <- c(
  "EL18", "EL19", "EL2", "EL3", "EL35", "EL36", "EL37", "EL38",
  "EL39", "EL40", "EL41", "EL42", "EL43", "EL44", "EL45", "EL46",
  "EL50"
)

expected_output_columns <- c(
  "Sample_Name", "training", "MLST", "Human_CL1", "Human_CL2",
  "Chicken_CL1", "Chicken_CL2", "Pork", "CL1", "CL2",
  required_element_columns
)

stop_if_missing <- function(value, option_name) {
  if (is.null(value) == TRUE) {
    stop(paste0("Missing required option: ", option_name), call. = FALSE)
  }
}

find_first_matching_column <- function(data_frame, candidate_names, object_name) {
  matching_names <- intersect(candidate_names, colnames(data_frame))

  if (length(matching_names) == 0) {
    stop(
      paste0(
        "Could not find any of these columns in ", object_name, ": ",
        paste(candidate_names, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  return(matching_names[[1]])
}

normalize_sample_column <- function(data_frame, object_name) {
  sample_column_name <- find_first_matching_column(
    data_frame = data_frame,
    candidate_names = c("Sample_Name", "Sample_ID", "sample_ID", "Genome_Ref", "GenomeID", "Genome"),
    object_name = object_name
  )

  normalized_data_frame <- data_frame
  normalized_data_frame <- dplyr::rename(
    normalized_data_frame,
    Sample_Name = dplyr::all_of(sample_column_name)
  )

  normalized_data_frame$Sample_Name <- as.character(normalized_data_frame$Sample_Name)

  return(normalized_data_frame)
}

normalize_host_value <- function(host_value) {
  if (is.na(host_value) == TRUE) {
    return(NA_character_)
  }

  normalized_host_value <- stringr::str_to_lower(host_value)
  normalized_host_value <- stringr::str_trim(normalized_host_value)

  if (normalized_host_value %in% c("human", "humans")) {
    return("Human")
  }

  if (normalized_host_value %in% c("chicken", "broiler", "poultry_chicken")) {
    return("Chicken")
  }

  if (normalized_host_value %in% c("pork", "swine", "pig", "porcine")) {
    return("Pork")
  }

  if (normalized_host_value %in% c("turkey")) {
    return("Turkey")
  }

  if (normalized_host_value %in% c("beef", "bovine", "cow", "cattle")) {
    return("Beef")
  }

  return(stringr::str_to_title(normalized_host_value))
}

normalize_binary_column <- function(vector_input) {
  vector_as_character <- as.character(vector_input)
  vector_as_character <- stringr::str_trim(vector_as_character)
  vector_as_character <- stringr::str_to_lower(vector_as_character)

  true_values <- c("1", "true", "t", "yes", "y", "present")
  false_values <- c("0", "false", "f", "no", "n", "absent")

  normalized_vector <- rep(0L, length(vector_as_character))

  normalized_vector[vector_as_character %in% true_values] <- 1L
  normalized_vector[vector_as_character %in% false_values] <- 0L

  numeric_values <- suppressWarnings(as.numeric(vector_as_character))
  numeric_indices <- is.na(numeric_values) == FALSE

  if (sum(numeric_indices) > 0) {
    numeric_binary_values <- ifelse(numeric_values[numeric_indices] > 0, 1L, 0L)
    normalized_vector[numeric_indices] <- numeric_binary_values
  }

  missing_indices <- is.na(vector_input) == TRUE

  if (sum(missing_indices) > 0) {
    normalized_vector[missing_indices] <- 0L
  }

  return(as.integer(normalized_vector))
}

coerce_cluster_column <- function(vector_input) {
  vector_as_character <- as.character(vector_input)
  extracted_cluster <- stringr::str_extract(vector_as_character, "[12]")
  cluster_as_integer <- suppressWarnings(as.integer(extracted_cluster))

  if (all(is.na(cluster_as_integer)) == TRUE) {
    stop("Unable to parse cluster assignments. Expected values such as 1, 2, CL1, or CL2.", call. = FALSE)
  }

  invalid_cluster_indices <- is.na(cluster_as_integer) == FALSE & cluster_as_integer %in% c(1L, 2L) == FALSE

  if (sum(invalid_cluster_indices) > 0) {
    stop("Cluster assignments must resolve to 1 or 2.", call. = FALSE)
  }

  return(cluster_as_integer)
}

validate_required_columns <- function(data_frame, required_columns, object_name) {
  missing_columns <- setdiff(required_columns, colnames(data_frame))

  if (length(missing_columns) > 0) {
    stop(
      paste0(
        "Missing required columns in ", object_name, ": ",
        paste(missing_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }
}

## command line options
# Define the command line inputs
opt_lst <- list(
  make_option(c("-s","--SB27"),
              help = "Base SB27 input as a CSV file"),
  make_option(c("-k","--kmodes"),
              help = "kmodes predictions: CSV with Sample_ID and predictions"),
  make_option(c("-m","--mlst"),
              help = "mlst predictions: CSV with sample_ID and ST"),
  make_option(c("-e", "--elements"),
              help = "elements: TSV with Sample_ID and element presence/absence"),
  make_option(c("h","--host"),
              help = "Host labels: TSV with sample_ID and Host"),
  make_option(c("-o","--output"),
              help = "this is the output location of the input")
)
# Build the argument parser
parser <- OptionParser(option_list = opt_lst,
                       description = "script to create input Bayesian latent class analysis")
# Read command line arguments
arguments <- parse_args(parser,
                        positional_arguments = TRUE)
# Store the parsed option values
opts <- arguments$options

curr_dir <- getwd()

#get arguements
sb27_file <- opts$SB27
kmodes_file <- opts$kmodes
mlst_file <- opts$mlst
elements_file <- opts$elements
host_file <- opts$host
output_dir <- opts$output

stop_if_missing(sb27_file, "--SB27")
stop_if_missing(kmodes_file, "--kmodes")
stop_if_missing(mlst_file, "--mlst")
stop_if_missing(elements_file, "--elements")
stop_if_missing(host_file, "--host")
stop_if_missing(output_dir, "--output")

#read data
sb27_df <- read_csv(sb27_file)
kmodes_df <- read_csv(kmodes_file)
mlst_df <- read_csv(mlst_file)
elements_df <- read_tsv(elements_file)
host_df <- read_tsv(host_file)

# normalize sample identifier columns
sb27_df <- normalize_sample_column(sb27_df, "SB27 base input")
kmodes_df <- normalize_sample_column(kmodes_df, "kmodes predictions")
mlst_df <- normalize_sample_column(mlst_df, "MLST predictions")
elements_df <- normalize_sample_column(elements_df, "element presence file")
host_df <- normalize_sample_column(host_df, "host labels")

# normalize training data to the reduced no-beef-no-turkey schema
validate_required_columns(sb27_df, expected_output_columns, "SB27 base input")

sb27_df <- dplyr::select(sb27_df, dplyr::all_of(expected_output_columns))

sb27_df$Sample_Name <- as.character(sb27_df$Sample_Name)

# normalize kmodes predictions
kmodes_cluster_column <- find_first_matching_column(
  data_frame = kmodes_df,
  candidate_names = c("cluster_2", "Cluster_2", "cluster", "Cluster", "prediction", "predictions"),
  object_name = "kmodes predictions"
)

kmodes_df <- dplyr::select(kmodes_df, Sample_Name, dplyr::all_of(kmodes_cluster_column))
kmodes_df <- dplyr::rename(kmodes_df, kmodes_cluster = dplyr::all_of(kmodes_cluster_column))

kmodes_df$kmodes_cluster <- coerce_cluster_column(kmodes_df$kmodes_cluster)

# normalize MLST predictions
mlst_value_column <- find_first_matching_column(
  data_frame = mlst_df,
  candidate_names = c("ST", "st", "MLST", "mlst"),
  object_name = "MLST predictions"
)

mlst_df <- dplyr::select(mlst_df, Sample_Name, dplyr::all_of(mlst_value_column))
mlst_df <- dplyr::rename(mlst_df, MLST = dplyr::all_of(mlst_value_column))

mlst_df$MLST <- as.character(mlst_df$MLST)

# normalize host labels
host_value_column <- find_first_matching_column(
  data_frame = host_df,
  candidate_names = c("Host", "host", "Source", "source"),
  object_name = "host labels"
)

host_df <- dplyr::select(host_df, Sample_Name, dplyr::all_of(host_value_column))
host_df <- dplyr::rename(host_df, Host = dplyr::all_of(host_value_column))

host_df$Host <- vapply(host_df$Host, normalize_host_value, character(1))

# normalize element presence data
elements_df <- dplyr::select(elements_df, dplyr::any_of(c("Sample_Name", required_element_columns)))

missing_element_columns <- setdiff(required_element_columns, colnames(elements_df))

if (length(missing_element_columns) > 0) {
  for (missing_element_column in missing_element_columns) {
    elements_df[[missing_element_column]] <- 0L
  }
}

elements_df <- dplyr::select(elements_df, Sample_Name, dplyr::all_of(required_element_columns))

for (element_column_name in required_element_columns) {
  elements_df[[element_column_name]] <- normalize_binary_column(elements_df[[element_column_name]])
}

# verify that prediction inputs have unique sample identifiers
duplicated_kmodes_samples <- kmodes_df$Sample_Name[duplicated(kmodes_df$Sample_Name)]
duplicated_mlst_samples <- mlst_df$Sample_Name[duplicated(mlst_df$Sample_Name)]
duplicated_host_samples <- host_df$Sample_Name[duplicated(host_df$Sample_Name)]
duplicated_element_samples <- elements_df$Sample_Name[duplicated(elements_df$Sample_Name)]

if (length(duplicated_kmodes_samples) > 0) {
  stop("Duplicate sample names detected in kmodes predictions.", call. = FALSE)
}

if (length(duplicated_mlst_samples) > 0) {
  stop("Duplicate sample names detected in MLST predictions.", call. = FALSE)
}

if (length(duplicated_host_samples) > 0) {
  stop("Duplicate sample names detected in host labels.", call. = FALSE)
}

if (length(duplicated_element_samples) > 0) {
  stop("Duplicate sample names detected in element presence data.", call. = FALSE)
}

# compile the new prediction rows and bind to the SB27 training base input
compiled_prediction_df <- dplyr::left_join(kmodes_df, mlst_df, by = "Sample_Name")
compiled_prediction_df <- dplyr::left_join(compiled_prediction_df, host_df, by = "Sample_Name")
compiled_prediction_df <- dplyr::left_join(compiled_prediction_df, elements_df, by = "Sample_Name")

missing_mlst_samples <- compiled_prediction_df$Sample_Name[is.na(compiled_prediction_df$MLST) == TRUE]
missing_host_samples <- compiled_prediction_df$Sample_Name[is.na(compiled_prediction_df$Host) == TRUE]

if (length(missing_mlst_samples) > 0) {
  stop("Some kmodes samples are missing MLST calls.", call. = FALSE)
}

if (length(missing_host_samples) > 0) {
  stop("Some kmodes samples are missing host labels.", call. = FALSE)
}

compiled_prediction_df$training <- 0L
compiled_prediction_df$Human_CL1 <- 0L
compiled_prediction_df$Human_CL2 <- 0L
compiled_prediction_df$Chicken_CL1 <- 0L
compiled_prediction_df$Chicken_CL2 <- 0L
compiled_prediction_df$Pork <- 0L
compiled_prediction_df$CL1 <- 0L
compiled_prediction_df$CL2 <- 0L

human_cluster_1_index <- compiled_prediction_df$Host == "Human" & compiled_prediction_df$kmodes_cluster == 1L
human_cluster_2_index <- compiled_prediction_df$Host == "Human" & compiled_prediction_df$kmodes_cluster == 2L
chicken_cluster_1_index <- compiled_prediction_df$Host == "Chicken" & compiled_prediction_df$kmodes_cluster == 1L
chicken_cluster_2_index <- compiled_prediction_df$Host == "Chicken" & compiled_prediction_df$kmodes_cluster == 2L
pork_index <- compiled_prediction_df$Host == "Pork"
cluster_1_index <- compiled_prediction_df$kmodes_cluster == 1L
cluster_2_index <- compiled_prediction_df$kmodes_cluster == 2L

compiled_prediction_df$Human_CL1[human_cluster_1_index] <- 1L
compiled_prediction_df$Human_CL2[human_cluster_2_index] <- 1L
compiled_prediction_df$Chicken_CL1[chicken_cluster_1_index] <- 1L
compiled_prediction_df$Chicken_CL2[chicken_cluster_2_index] <- 1L
compiled_prediction_df$Pork[pork_index] <- 1L
compiled_prediction_df$CL1[cluster_1_index] <- 1L
compiled_prediction_df$CL2[cluster_2_index] <- 1L

unsupported_host_values <- setdiff(unique(compiled_prediction_df$Host), c("Human", "Chicken", "Pork"))

if (length(unsupported_host_values) > 0) {
  stop(
    paste0(
      "This compiler expects only Human, Chicken, and Pork host labels. Unsupported values: ",
      paste(unsupported_host_values, collapse = ", ")
    ),
    call. = FALSE
  )
}

compiled_prediction_df <- dplyr::select(compiled_prediction_df, dplyr::all_of(expected_output_columns))

compiled_output_df <- bind_rows(sb27_df, compiled_prediction_df)

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

output_file_path <- file.path(output_dir, "SB27_noBeefnoTurkey_blcm_input_compiled.csv")

write_csv(compiled_output_df, output_file_path)

message("Compiled BLCM input written to: ", output_file_path)


