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
dat$WH_RAT <- dat$emp/dat$TOT_EMP
# Regressions Models with State-Fixed Effects
lm1 <- lm_robust(EMP_RAT ~ TREAT + factor(fipstate) - 1, data = dat)
lm2 <- lm_robust(TOT_EMP_RAT ~ TREAT + factor(fipstate) - 1, data = dat)
lm3 <- lm_robust(WH_RAT ~ TREAT + factor(fipstate) - 1, data = dat)
# Regression Models without State-Fixed Effects
lm5 <- lm_robust(EMP_RAT ~ TREAT, data = dat)
lm6 <- lm_robust(TOT_EMP_RAT ~ TREAT, data = dat)
lm7 <- lm_robust(WH_RAT ~ TREAT, data = dat)
# Summaries for Warehouse Employment over County Population
summary(lm1)
summary(lm5)
# Summaries for Total Employment over County Population
summary(lm2)
summary(lm6)
# Summaries for Warehouse Employment over Total Employment
summary(lm3)
summary(lm7)






