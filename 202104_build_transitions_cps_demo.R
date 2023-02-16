library(tidyverse)
library(lubridate)
library(RSQLite)
library(zoo)
library(dbplyr)
library(scales)
library(chunked)
library(stringr)

## legend:
## one hashtag (#) identifies silenced codes
## two hashtags (##) identifies comments

## To remove every object from the current enviroment
rm(list=ls())

#------------------------------------------------------------------------------------------------------------------------#
# Section 1: LOAD CPS RAW DATA AND IDENTIFY TRANSITIONS  ----------------------------------------------------------------
## Section 1 only needs to be ran once. If you've already ran it and saved the matched transitions sample, jump to section 2##
#------------------------------------------------------------------------------------------------------------------------#

##1.1 SIMPLE APPROACH TO DATA ----------------------------------------------
## IPUMS makes files available in two formats DAT and CSV:
## This is how you upload data in DAT. It's much easier, but you'll need some RAM to upload it. Consult ipumsr documentation for more details
# t<-Sys.time()
# library(ipumsr)
# cps_ddi <- read_ipums_ddi("raw/cps_00027.xml")
# cps_data <- read_ipums_micro(cps_ddi, verbose = FALSE)
# Sys.time()-t


##1.2 ALTERNATE APPROACH TO DATA (if you chose the approach 1.1, don't run this and jump to section 1.3)----------------------------------------------
## When we developed this code, files were available as CSV. We created a process to:
## 1. Create a local database to store raw data on a table (we call it main_table)
## 2. Clean it and match it on a month-to-month basis.
## 3. Store matched observations in another table of the same local database (we call it Transitions_CW).
## 4. Extract the whole table of matched observations and store it on a flat file.


## Unzip cps data in your working directory (if you haven't unzipped it yet - this won't load anything in your R environment)
## The file we downloaded from Ipums is called "cps_00026.csv.gz", yours will have a different name 
## if it doesn't work for any reason you can unzip it manually.
## R.utils::gunzip("raw/cps_00026.csv.gz")


## Remove cps main table (in case it exists and you want to load new data)----
con <- dbConnect(SQLite(), dbname = "cps_demo_2") 
dbRemoveTable(con, "cps_main")
dbDisconnect(con)

## Remove transitions table (in case it exists and you want to load new data)----
con <- dbConnect(SQLite(), dbname = "cps_demo_2")
dbRemoveTable(con, "Transitions_CW")
dbDisconnect(con)


## Load data into cps_main table----

t<-Sys.time()

## Load data in your R environment (Run only once after updating data)
cps_data <- read_csv_chunkwise(file = "CPS_ipums/cps_00026.csv") %>%
  mutate(date = paste0(YEAR, "-", MONTH, "-01"))%>%
  select(-VETSTAT ,-EDDIPGED,-EDCYC,-CITIZEN,-ASECFLAG )%>%
  filter(YEAR<2020) # OCC codes changed in 2020. Harmonization is available in OCC2010 column, but we think it needs to be improved. 

Sys.time()-t

t<-Sys.time()

## Create local database (Run only once after updating data)
cps_con <- src_sqlite("cps_demo_2", create = TRUE)

## Insert CPS data into your local database (Run only once after updating data)
insert_chunkwise_into(cps_data, cps_con, "cps_main", temporary = FALSE)
rm(cps_data)
Sys.time()-t

## Crate access to csp main table -----
cps <- src_sqlite("cps_demo_2", create = FALSE) %>% tbl("cps_main")


##1.3 Loop over the transitions dataset ----
months <- seq.Date(ymd("2003-01-01"),ymd("2019-12-01"), by = "month")

for (i in 1:length(months)) {
  date1 <-  months[i]
  date2 <- months[i+1]
  dates <- c(paste0(year(date1), "-", as.numeric(month(date1)), "-01"),
             paste0(year(date2), "-", as.numeric(month(date2)), "-01"))
  
  years<-c(year(date1),year(date2))
  
  t<-Sys.time()
  
  ## run if you choose approach 1.1 
  # w <- cps_data %>% 
  #   filter(YEAR %in%  years & date %in% dates & WTFINL > 0) %>% 
  #   mutate(date = ymd(date))
  
  ## run if you choosed approach 1.2
  w <- cps %>% 
    filter(YEAR %in%  years & date %in% dates & WTFINL > 0) %>% 
    collect() %>% 
    mutate(date = ymd(date))
  
  print(paste(Sys.time()-t,"duration"))
  
  
  ## Split by months and merge
  TransitionsW <- w %>% filter(date == date1)
  TransitionsW <- TransitionsW %>% 
    ## From this point, origin attributes are identified by X and destinations are identified by Y  
    inner_join(w %>% filter(date == date2) , by = "CPSIDP")     
  
  ## Drop the unemployed
  
  TransitionsW <- TransitionsW  %>%
    mutate(EMPLOYED.x=ifelse(EMPSTAT.x %in% c(10,12),1,0)) %>%
    mutate(EMPLOYED.y=ifelse(EMPSTAT.y %in% c(10,12),1,0)) %>% 
    filter(EMPLOYED.x == 1 & EMPLOYED.y==1)
  
  
  ## Inform when loop gets to the last period so we're sure that's where the error came from
  if (nrow(TransitionsW) == 0) {
    print(paste0("FAIL: ", date1))
    next} else
      
  TransitionsW <- TransitionsW  %>% 
    select(OCC.x, OCC.y, SEX.x, SEX.y,RACE.x,RACE.y,AGE.x,AGE.y, 
           IND.x,IND.y, LFPROXY.x,LFPROXY.y, EMPSAME.x,EMPSAME.y,QOCC.x,QOCC.y,QIND.x,QIND.y, 
           ACTSAME.x,ACTSAME.y, EDUC.x,EDUC.y, WTFINL.x ,WTFINL.y,
           date.x,date.y, MISH.x, MISH.y, OCC2010.x, OCC2010.y,CPSIDP,
           starts_with("UH_"),starts_with("NATIVITY"),
           starts_with("REGION"),starts_with("STATECENSUS"),
           starts_with("METFIPS"),starts_with("METAREA"),
           starts_with("HISPAN"),
           starts_with("CLASSWKR"),starts_with("WKSTAT"),
           starts_with("JOBCERT"),starts_with("PROFCERT")) 
  
  ## Flag possible drops
  TransitionsW <- TransitionsW %>% 
    ## Flag matches for demographics (Sex, Race and Age ~ if someone is more than 3 years older from one month to the next, then something is wrong)
    mutate(bad_match = ifelse(((SEX.x == SEX.y) & (RACE.x == RACE.y) & (AGE.y >= AGE.x) & (AGE.y < (AGE.x +3))),0,1))%>%
    ## Flag matches where we cant see if the worker still works for the same employer (for a discussion see Fujija, S., Moscarini, G., & Postel-vinay, F. (2020). Measuring Employer-to-Employer Reallocation. IZA Discussion Paper Series, 13472.) 
    ## there are big sample size losses here (as much as in the other filters together), this condition invalidates many transitions. 
    ## You can choose to apply it or not.
    # mutate(norespond_E = ifelse((EMPSAME.y %in% c(96,97)),1,0)) %>% 
    ## Similar to as norespond_E. If norespond_E was applied, this will have no consecuences.
    # mutate(norespond_A = ifelse(ACTSAME.x %in% c(96,97)| ACTSAME.y %in% c(96,97),1,0)) %>%       
    ## Flag imputed industry and occupation codes
    ## Keep only 0	(No change) and 3	(Value to value)
    mutate(impO = ifelse(QOCC.y %in% c(1:3,4:8) |QOCC.x %in% c(1:3,4:8) ,1,0))%>%
    mutate(impI = ifelse(QIND.y %in% c(1:3,4:8) |QIND.x %in% c(1:3,4:8) ,1,0))
  
  ## Flag all possible drops and mark keeps
  ### We'll estimate the probability of being kept in the sample based on demographic attributes
  ### For a discussion of this method look at Bollinger and Hirsch (2006), Match Bias from Earnings Imputation in the Current Population Survey: The Case of Imperfect Matching, JSTOR
  TransitionsW <- TransitionsW %>% 
    mutate(drop = ifelse(impO==1|impI==1|bad_match==1 ,1,0),
           keep=1-drop)   
  
  ## Factor variables for logistic regression
  TransitionsW$SEX.y<-factor(TransitionsW$SEX.y)
  TransitionsW$RACE.y<-factor(TransitionsW$RACE.y)
  TransitionsW$EDUC.y<-factor(TransitionsW$EDUC.y)
  TransitionsW$SEX.x<-factor(TransitionsW$SEX.x)
  TransitionsW$RACE.x<-factor(TransitionsW$RACE.x)
  TransitionsW$EDUC.x<-factor(TransitionsW$EDUC.x)
  
  ## Get weights from drops
  logit.x<- glm(keep ~AGE.x +RACE.x +SEX.x +EDUC.x, data = as.data.frame(TransitionsW), family = binomial)
  summary(logit.x)
  
  ## Create dataset of kept observations and attach the probability of being kept for each record.
  TransitionsW_kept<-TransitionsW[TransitionsW$keep==1,]
  predictions_1 <- predict(logit.x, newdata = TransitionsW_kept, type="response")  
  
  ## Calculate the overall labor force size
  total_weigths_date_1<- w %>% 
    filter(MONTH == month(date2))%>% 
    # keep employed or unemployed
    filter(EMPSTAT %in% c(10,12,21,22)) %>% 
    # drop unemployed seeking for first job (they don't have an occupation)
    filter(OCC!=0) %>%
    summarise(sum(WTFINL)) %>%
    as.numeric()
  
  kept_weigths_date_1<-sum(TransitionsW$WTFINL.x)
  
  adj<-1/(kept_weigths_date_1/total_weigths_date_1) # adjustment factor
  
  
  TransitionsW_kept <- TransitionsW_kept %>% mutate(weight_pop = WTFINL.x* (1/predictions_1)*adj)
  
  #sum(TransitionsW_kept$WTFINL.x)  # look at unadjusted weigths 
  #sum(TransitionsW_kept$weight_pop)    # look adjusted weigths. Sum equals kept_weigths_date_1
  #kept_weigths_date_1
  
  ## append matched records (already weigthed) to the Transitions_CW table
  con <- dbConnect(SQLite(), dbname = "cps_demo_2")
  dbWriteTable(con, "Transitions_CW", TransitionsW_kept, append = TRUE)
  dbDisconnect(con)
  
  
  rm(TransitionsW_kept, logit.x, predictions_1)
  
  print(months[i])
  
}
#------------------------------------------------------------------------------------------------------------------------#
# Section 2: SAVE IDENTIFIED TRANSITIONS IN rds  ----------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------#

## Saving weigthed transitions into a dataframe----
Total_Transitions_weights <-src_sqlite("cps_demo_2", create = FALSE) %>% tbl("Transitions_CW")
Total_Transitions_weights <- Total_Transitions_weights  %>% 
  collect() 

saveRDS(Total_Transitions_weights,"data/Total_Transitions_weights_26.rds")

