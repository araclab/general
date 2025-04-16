# analysis for host elements study
# Zhenke Wu | zhenkewu@umich.edu
# November 18th, 2019
# Modified by Daniel Park | danpark@gwu.edu
# Modified by Maliha Aziz | mlaziz@gwu.edu
# Modified by Edward Sung | edward.sung@gwu.edu
# Modified for cgmlst Kmodes clustering

# Notes by Edward Sung | edward.sung@gwu.edu
# The bugs model takes in the entire csv file as training.
# The "training" column is only used to call which ones to create ouputs/predictions for.
# training==1 means no pred output is generated, training==0 pred outputs are generated.
# This means that a baseline training set needs to be included along with all "new datasets"
# For example, this means when running SB27 samples... dcFUTI and bigFUTI: 011723_any_element_presence_input_bigfuti_dcfuti.csv is included along with the SB27 dataset.


# Additional modifications for reproducibility - Edward (March, 31, 2024)
# Added set.seed(123) to the start
# Modified:
# in_init <- function(){
#   list(a=rep(0,M_fit-1), .RNG.name = "base::Wichmann-Hill", .RNG.seed = 123)
# } 

# Reverted back to no setseed. Kept the setseed as a comment, but moving forward we want the varability that comes from repetition with blcm. - Edward (June, 21, 2024)

# Converted for Cluster2 Usage, changed the column names. - Edward (July 10, 2024)

# Edward (August 6, 2024)
# Added Beef Column as a class 


suppressPackageStartupMessages(library(optparse,lib="/GWSPH/groups/liu_price_lab/pegasus_bin/LIBS/R/x86_64-pc-linux-gnu-library/4.1"))
suppressPackageStartupMessages(library(coda,lib="/GWSPH/groups/liu_price_lab/pegasus_bin/LIBS/R/x86_64-pc-linux-gnu-library/4.1"))
suppressPackageStartupMessages(library(rjags,lib="/GWSPH/groups/liu_price_lab/pegasus_bin/LIBS/R/x86_64-pc-linux-gnu-library/4.1"))
suppressPackageStartupMessages(library(R2jags,lib="/GWSPH/groups/liu_price_lab/pegasus_bin/LIBS/R/x86_64-pc-linux-gnu-library/4.1"))



rm(list=ls())

## command line options
opt_lst <- list(
  make_option(c("-i","--input_file"),
              help = "Input file name"),
  make_option(c("-o","--output_folder"),
              help = "Output folder name")
)
parser <- OptionParser(option_list = opt_lst,
                       description = "HBLCM\n TO run on pegasus: \nmodule load R/gcc/10.2.0/4.1.1;conda activate jags;sbatch -J blcm -t 1-00:00:00 -p short -N 1 --wrap=\"Rscript hostelement_blca.R -i INPUT_FILE.csv -o OUTPUT_FOLDER\"")
arguments <- parse_args(parser,
                        positional_arguments = TRUE)
opts <- arguments$options

curr_dir <-  getwd() 
dir.create(file.path(curr_dir, opts$o), showWarnings = FALSE)


# read in data:

dat <- read.csv(opts$i)
head(dat)

class_label <- rep(NA,nrow(dat))
for (i in 1:nrow(dat)){
    if (dat$training[i] ==1){
        if (!is.na(datHuman_CL1[i]) && datHuman_CL1[i]) && datHuman_CL1[i] ==1) class_label[i]=1
        if (!is.na(datHuman_CL2[i]) && datHuman_CL2[i]) && datHuman_CL2[i] ==1) class_label[i]=2
        if (!is.na(datChicken_CL1[i]) && datChicken_CL1[i]) && datChicken_CL1[i] ==1) class_label[i]=3
        if (!is.na(datChicken_CL2[i]) && datChicken_CL2[i]) && datChicken_CL2[i] ==1) class_label[i]=4
        if (!is.na(datTurkey_CL1[i]) && datTurkey_CL1[i]) && datTurkey_CL1[i] ==1) class_label[i]=5
        if (!is.na(datTurkey_CL2[i]) && datTurkey_CL2[i]) && datTurkey_CL2[i] ==1) class_label[i]=6
        if (!is.na(datPork[i]) && datPork[i]) && datPork[i] ==1) class_label[i]=7
	if (!is.na(datBeef[i]) && datBeef[i]) && datBeef[i] ==1) class_label[i]=8}
}
# set.seed(123)
ntrain = nrow(dat)
test_id <- which(dat[1:ntrain,]$training==0)
Y <- as.matrix(dat[1:ntrain,-(1:11)])

result_folder <- file.path(curr_dir, opts$o)

# fit Bayesian model:
mcmc_options <- list(debugstatus= TRUE,
                     n.chains   = 1,
                     n.itermcmc = 10000, #Default: 10000
                     n.burnin   = 5000, #Default: 5000
                     n.thin     = 1,
                     result.folder = result_folder,
                     bugsmodel.dir = result_folder
)

# write .bug model file:
model_bugfile_name <- "model.bug"
filename   <- file.path(mcmc_options$bugsmodel.dir, model_bugfile_name)

model_text <- "model{#BEGIN OF MODEL:
  for (i in 1:N){
  for (k in 1:K){
  Y[i,k] ~ dbern(p[eta[i],k]) #observed data
  }
  eta[i] ~ dcat(pi[1:M_fit]) #Latent class assignment
  }
  
  for (j in 1:(M_fit-1)){
  exp0[j] <- exp(a[j]) #Class probabilities derived
  a[j] ~ dnorm(0,4/9) #Hyperpriors
  }
  exp0[M_fit] <- 1
  exp_sorted <- sort(exp0[1:M_fit])
  
  for (j in 1:M_fit){
  pi[j] <- exp_sorted[j]/sum(exp_sorted[1:M_fit]) #Class probabilities normalized
  for (k in 1:K){
  p[j,k] <- 1/(1+exp(-g[j,k])) # logistic , Response probabilities
  g[j,k] ~ dnorm(0,4/9)#Hyperpriors
  }
}


# # generate new data:
# for (i in 1:N){
# for (k in 1:K){
# new_Y[i,k] ~ dbern(p[new_eta[i],k])
# }
# new_eta[i] ~ dcat(pi[1:M_fit])
#}


} #END OF MODEL."

writeLines(model_text, filename)

# run jags:
library(rjags)
load.module("glm")

M_fit <- 8 # this equals the number of all possible categories
N <- nrow(Y)
K <- ncol(Y)
eta <- class_label

in_data       <- c("Y","M_fit","N","K","eta")
out_parameter <- c("pi","p","eta")

in_init <- function(){
  # list(a=rep(0,M_fit-1), .RNG.name = "base::Wichmann-Hill", .RNG.seed = 123)
  list(a=rep(0,M_fit-1))
}

curr_data_txt_file <- file.path(mcmc_options$result.folder,"jagsdata.txt")
if(file.exists(curr_data_txt_file)){file.remove(curr_data_txt_file)}

out <- R2jags::jags2(data   = in_data,
                     inits  = in_init,
                     parameters.to.save = out_parameter,
                     model.file = filename,
                     working.directory = mcmc_options$result.folder,
                     n.iter         = as.integer(mcmc_options$n.itermcmc),
                     n.burnin       = as.integer(mcmc_options$n.burnin),
                     n.thin         = as.integer(mcmc_options$n.thin),
                     n.chains       = as.integer(mcmc_options$n.chains),
                     DIC            = FALSE,
                     clearWD        = FALSE)


#Obtain the posterior samples from JAGS output:
  
#Obtain the chain histories:
res <- coda::read.coda(file.path(result_folder,"CODAchain1.txt"),
                       file.path(result_folder,"CODAindex.txt"),
                       quiet=TRUE)
print_res <- function(x,coda_res) plot(coda_res[,grep(x,colnames(coda_res))])
get_res   <- function(x,coda_res) coda_res[,grep(x,colnames(coda_res))]

print_res("eta",res)

# 
# 
# 
# ind_ord <- order(pi_vec) 
# retain_ind <- grep("^p",rownames(out$summary))
# posterior_table <- cbind(c(pi_vec[ind_ord],p_mat[ind_ord,]),round(out$summary[retain_ind,],3))
# colnames(posterior_table)[1] <- "truth"

mat_test <- as.matrix(get_res("eta",res))[,test_id]

v1 <- apply(mat_test,2,function(v) mean(v==1))
v2 <- apply(mat_test,2,function(v) mean(v==2))
v3 <- apply(mat_test,2,function(v) mean(v==3))
v4 <- apply(mat_test,2,function(v) mean(v==4))
v5 <- apply(mat_test,2,function(v) mean(v==5))
v6 <- apply(mat_test,2,function(v) mean(v==6))
v7 <- apply(mat_test,2,function(v) mean(v==7))
v8 <- apply(mat_test,2,function(v) mean(v==8))


res_dat <- cbind(v1,v2,v3,v4,v5,v6,v7,v8,dat[test_id,1:14])
colnames(res_dat)[1:8] <- c("pred_Human_CL1","pred_Human_CL2",
                            "pred_Chicken_CL1","pred_Chicken_CL2",
                            "pred_Turkey_CL1","pred_Turkey_CL2",
                            "pred_Pork","pred_Beef")

filename_pred <- paste(opts$o, "_pred_scores.csv", sep="")
write.csv(res_dat, filename_pred)
