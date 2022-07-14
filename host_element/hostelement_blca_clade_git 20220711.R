# analysis for host elements study
# Zhenke Wu | zhenkewu@umich.edu
# November 18th, 2019
# Modified by Daniel Park | danpark@gwu.edu

# read in data:

rm(list=ls())
dat <- read.csv("PATH_TO_YOUR_FILE")

head(dat)

class_label <- rep(NA,nrow(dat))
for (i in 1:nrow(dat)){
    if (dat$training[i] ==1){
        if (!is.na(dat$human_CM1[i]) && dat$human_CM1[i] ==1) class_label[i]=1
        if (!is.na(dat$human_CH1[i]) && dat$human_CH1[i] ==1) class_label[i]=2
        if (!is.na(dat$human_CH2[i]) && dat$human_CH2[i] ==1) class_label[i]=3
        if (!is.na(dat$chicken_CM1[i]) && dat$chicken_CM1[i] ==1) class_label[i]=4
        if (!is.na(dat$chicken_CH1[i]) && dat$chicken_CH1[i] ==1) class_label[i]=5
        if (!is.na(dat$chicken_CH2[i]) && dat$chicken_CH2[i] ==1) class_label[i]=6
        if (!is.na(dat$turkey_CM1[i]) && dat$turkey_CM1[i] ==1) class_label[i]=7
        if (!is.na(dat$turkey_CH1[i]) && dat$turkey_CH1[i] ==1) class_label[i]=8
        if (!is.na(dat$turkey_CH2[i]) && dat$turkey_CH2[i] ==1) class_label[i]=9
        if (!is.na(dat$pork[i]) && dat$pork[i] ==1) class_label[i]=10}
}

ntrain = nrow(dat)
test_id <- which(dat[1:ntrain,]$training==0)
Y <- as.matrix(dat[1:ntrain,-(1:13)])

result_folder <- "RESULTS_PATH_HERE"

# fit Bayesian model:
mcmc_options <- list(debugstatus= TRUE,
                     n.chains   = 1,
                     n.itermcmc = 10000, #10000
                     n.burnin   = 5000, #5000
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
  Y[i,k] ~ dbern(p[eta[i],k])
  }
  eta[i] ~ dcat(pi[1:M_fit])
  }
  
  for (j in 1:(M_fit-1)){
  exp0[j] <- exp(a[j])
  a[j] ~ dnorm(0,4/9)
  }
  exp0[M_fit] <- 1
  exp_sorted <- sort(exp0[1:M_fit])
  
  for (j in 1:M_fit){
  pi[j] <- exp_sorted[j]/sum(exp_sorted[1:M_fit])
  for (k in 1:K){
  p[j,k] <- 1/(1+exp(-g[j,k]))
  g[j,k] ~ dnorm(0,4/9)
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

M_fit <- 10 # this equals the number of all possible categories
N <- nrow(Y)
K <- ncol(Y)
eta <- class_label

in_data       <- c("Y","M_fit","N","K","eta")
out_parameter <- c("pi","p","eta")

in_init <- function(){
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
v9 <- apply(mat_test,2,function(v) mean(v==9))
v10 <- apply(mat_test,2,function(v) mean(v==10))


res_dat <- cbind(v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,dat[test_id,1:16])
colnames(res_dat)[1:10] <- c("pred_human_CM1","pred_human_CH1","pred_human_CH2",
                            "pred_chicken_CM1","pred_chicken_CH1","pred_chicken_CH2",
                            "pred_turkey_CM1","pred_turkey_CH1","pred_turkey_CH2",
                            "pred_pork")

write.csv(res_dat,"pred_scores.csv")
