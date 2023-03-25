#' ---
#' title: "Preliminary Results - Question A"
#' author: "Harvard EcLabs"
#' output: pdf_document
#' ---
#' 

# Packages
library(estimatr)
library(modelsummary)
# Reading in Data
dat <- read.csv('Sub_Openings_amz.csv')
# Variable Creation
dat$EMP_RAT <- dat$emp/dat$CT_POP
dat$TOT_EMP_RAT <- dat$TOT_EMP/dat$CT_POP
# Regressions Models
lm1 <- lm_robust(EMP_RAT ~ TREAT, data = dat)
lm2 <- lm_robust(TOT_EMP_RAT ~ TREAT, data = dat)

summary(lm1)
summary(lm2)



