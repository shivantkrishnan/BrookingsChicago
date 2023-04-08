#' ---
#' title: "Question A"
#' author: "Harvard EcLabs"
#' output: pdf_document
#' ---

#' Packages
#' 
library(estimatr)
library(modelsummary)
library(ggplot2)

#' Reading in Data
#' 
dat <- read.csv('agg_cbp_single.csv')
dat_TOTALEMP <- dat[which(dat$naics == '------'),]
dat_WHEMP <- dat[which(dat$naics == '493///'),]
#' Variable Creation
#' 
dat_WHEMP$EMP_RAT <- dat_WHEMP$emp/dat_WHEMP$CT_POP
dat_WHEMP$TOT_EMP_RAT <- dat_WHEMP$TOT_EMP/dat_WHEMP$CT_POP
dat_WHEMP$WH_RAT <- dat_WHEMP$emp/dat_WHEMP$TOT_EMP
dat_TOTALEMP$CT_RAT <- dat_TOTALEMP$emp/dat_TOTALEMP$CT_POP
#' Regressions Models
#' 
lm1 <- lm_robust(EMP_RAT ~ TREAT, data = dat_WHEMP[which(dat_WHEMP$emp > 0),])
lm2 <- lm_robust(WH_RAT ~ TREAT, data = dat_WHEMP[which(dat_WHEMP$emp > 0),])
lm3 <- lm_robust(CT_RAT ~ TREAT, data = dat_TOTALEMP)

#' Summary Warehouse Employment to County Ratio
#' 
summary(lm1)
#' Summary Warehouse Employment to Total Employment Ratio
#' 
summary(lm2)
#' Summary Total Employment to County Ratio
#' 
summary(lm3)

ggplot(dat_WHEMP[which(dat_WHEMP$emp > 0),], aes(x = TREAT, y = emp)) +
  geom_bar(position = "dodge", stat = "summary", fun = "mean") +
  stat_summary(aes(label=round(after_stat(y), 5)), fun = 'mean', geom ="text", size = 3,
               vjust = -0.5) +
  xlab('Treatment Period') + ylab('Average Warehouse Employment') + 
  ggtitle(' Warehouse Employment Before and After') + theme_bw()

ggplot(dat_WHEMP[which(dat_WHEMP$emp > 0),], aes(x = TREAT, y = EMP_RAT)) +
  geom_bar(position = "dodge", stat = "summary", fun = "mean") +
  stat_summary(aes(label=round(after_stat(y), 5)), fun = 'mean', geom ="text", size = 3,
               vjust = -0.5) +
  xlab('Treatment Period') + ylab('Average Warehouse Employment to County Ratio') + 
  ggtitle('Warehouse to County Ratio Before and After') + theme_bw()

ggplot(dat_WHEMP[which(dat_WHEMP$emp > 0),], aes(x = TREAT, y = WH_RAT)) +
  geom_bar(position = "dodge", stat = "summary", fun = "mean") +
  stat_summary(aes(label=round(after_stat(y), 5)), fun = 'mean', geom ="text", size = 3,
               vjust = -0.5) +
  xlab('Treatment Period') + ylab('Average Warehouse to Total Employment Ratio') + 
  ggtitle('Warehouse to Total Employment Before and After') + theme_bw()

ggplot(dat_TOTALEMP, aes(x = TREAT, y = CT_RAT)) +
  geom_bar(position = "dodge", stat = "summary", fun = "mean") +
  stat_summary(aes(label=round(after_stat(y), 5)), fun = 'mean', geom ="text", size = 3,
               vjust = -0.5) +
  xlab('Treatment Period') + ylab('Average Total Employment to County Ratio') + 
  ggtitle('Total Employment to County Ratio Before and After') + theme_bw()

