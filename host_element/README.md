A  Bayesian latent class model (BLCM) to systematically integrate multiple accessory elements for probabilistic assignment of host-origins.

### Introduction
 
Detection of mobile genetic elements in conjunction with core-genome phylogenetics may identify zoonotic spillover and host switch events. We applied Bayesian latent class model approach that assumes the host-origin for each isolate is in an unobserved class of human, turkey, pork and chicken, with further stratification into three major clades based on core phylogeny. 

BLCM uses multivariate binary responses that indicate presence or absence of 18 host-associated accessory elements, identified previously, to infer the latent host-origins. The latent classes and model parameters can be learned in an unsupervised fashion or using a training set. Markov chain Monte Carlo algorithms are used to iteratively produce samples from the posterior distribution of the unobserved host-origins, based on which we calculate posterior probabilities of host-origins for each isolate.

### Requirement
- R => v.3.3.1
- JAGS => v.4.2.0

### Input format
| Command | Description |
| --- | --- |
| git status | List all new or modified files |
| git diff | Show file differences that haven't been staged |
### Output format
| Command | Description |
| --- | --- |
| git status | List all new or modified files |
| git diff | Show file differences that haven't been staged |
 
### Usage

### Citation
If you use BLCM - Host Elements, please cite:

[Using source-associated mobile genetic elements to identify zoonotic extraintestinal E.coli infections](https:ADD LINK)

```
Cindy M. Liu, Maliha Aziz, Daniel E. Park, Zhenke Wu, Marc Stegger, Mengbing Li, Yashan Wang, Kara Schmidlin, Timothy J. Johnson, Benjamin J. Koch, Bruce A. Hungate, Lora Nordstrom, Lori Gauld, Brett Weaver, Diana Rolland,  Sally Statham, Brantley Hall, Sanjeev Sariya, Gregg S. Davis, Paul S. Keim, James R. Johnson, Lance B. Price.
Using source-associated mobile genetic elements to identify zoonotic extraintestinal E.
coli infections
ADD CITATION
```

