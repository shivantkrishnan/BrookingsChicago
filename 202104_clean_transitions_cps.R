  library(tidyverse)
  library(lubridate)
  library(scales)
  library(stringr)
  
  ## Here we load the dataset created in the build_transitions_cps_demo.R script (Total_Transitions_weights_26.rds)
  ## and clean it:
  ### 1. Attach SOCXX codes. These are SOC 2010 based codes compatible with OCC2010 Census codes. 
  ### 2. Attach NAICSXX codes. These are 2012 NAICS-based industry codes for the Census IND codes in the CPS and ACS columns.
  ### 3. Create a transitions dataset at the naicsxx-socxx level, another at the socxx level, and another at the naicsxx level.
  
  ## legend:
  ## one hashtag (#) identifies silenced codes
  ## two hashtags (##) identifies comments
  
  ## To remove every object from the current enviroment
  rm(list=ls())
  
  #------------------------------------------------------------------------------------------------------------------------#
  #----Creating copy of transitions dataset ---------------------------------------------
  #------------------------------------------------------------------------------------------------------------------------#
  
  ## Here we load the  raw version of job to jobs transitions.
  ## Remember we kept employed in both months and removed suspicious matches
  
  Total_Transitions_weights<-read_rds("data/Total_Transitions_weights_26.rds") %>% 
    filter(as_date(date.y)<="2019-12-01") # we remove observation from jan 2020 because it had 170 occupational codes that haven't appear before  + 20 new industry codes 
  
  
  ## matched dataset has transitions have 451 OCC coodes
  c(Total_Transitions_weights$OCC2010.x,Total_Transitions_weights$OCC2010.y) %>% 
    unique() %>%
    length()
  ## and 273 industries
  c(Total_Transitions_weights$IND.x,Total_Transitions_weights$IND.y) %>% 
    unique() %>%
    length()
  
  #------------------------------------------------------------------------------------------------------------------------#
  ## Keeping the variables of interest and creating a mark for transitions -----
  #------------------------------------------------------------------------------------------------------------------------#
  
  Clean_transitions <- Total_Transitions_weights %>%
    ## List of main filters (taking sample from 8,240,819  rows to 8,240,819  (0% decrease))
    ## keeping occupations and industries with no occupation imputations. No changes are made because we cleaned that in the ETL process
    filter(QOCC.y==0 & QOCC.x==0 )%>%   
    filter(QIND.y==0 & QIND.x==0 )%>%
    ## (DECLINED CHANGE) Remove individuals with EMPSAME "Don't know" or "Refuse to answer" in next month.
    ## This is optional. EMPSAME helps to gauge employer changes. Since we're not focusing on employment changes we don't apply the filter.
    ## As a result we're keeping records with NIU in EMPSAME variable of second MONTH
    # filter(EMPSAME.y %in% c(1,2)) %>% 
    ## create discrete age variable (optional)
    mutate_at(vars("AGE.x","AGE.y"),
              funs( "2"= case_when(.<=19~19,
                                   .>=20 & .<30~20,
                                   .>=30 & .<40~30,
                                   .>=40 & .<50~40,
                                   .>=50 & .<60~50,
                                   .>=60 & .<70~60,
                                   .>=70 ~70))) %>% 
    select(CPSIDP, date.y, weight, WTFINL.y,weight_pop, 
           OCC2010.x, OCC2010.y, IND.x, IND.y,
           LFPROXY.x,LFPROXY.y,
           EMPSAME.x, EMPSAME.y, ACTSAME.x,ACTSAME.y, 
           starts_with("UH_"),starts_with("NATIVITY"),
           starts_with("RACE"),starts_with("SEX"),
           starts_with("AGE"),starts_with("EDUC"),
           starts_with("Region"),starts_with("STATECENSUS"),
           starts_with("MET"),
           starts_with("HISPAN"),
           starts_with("CLASSWKR"),starts_with("WKSTAT"),
           starts_with("JOBCERT"),starts_with("PROFCERT"),
           drop) %>%
    mutate(keep = (1-drop), date.y=as_date(date.y)) 
  
  rm(Total_Transitions_weights)
  
  #------------------------------------------------------------------------------------------------------------------------#
  #OCC-SOC crosswalks and test merge---------------------------------------------------------------------------------------
  #------------------------------------------------------------------------------------------------------------------------#
  ## Brookings' developed  crosswalk
  ## The OCC to SOCXX crosswalk comes from an adaptation of https://usa.ipums.org/usa/volii/occtooccsoc18.shtml
  ## The SOCXX occupational classification constitutes a revised version of the SOC 2010 codes and is made up of 446 occupations in total. 
  ## In comparisson the 2010 Standard Occupation Classification System used in the OES 2018 has 808.
  Occupation_crosswalk <- read_csv("raw/Crosswalk_naicsxx_socxx/OCC-SOCXX_code_xwalk.csv") 
  Occupation_crosswalk$OCC<-as.integer(Occupation_crosswalk$OCC)
  
  Clean_transitions <- Clean_transitions %>%
    ## note that we use OCC2010 for the merge, the IPUMS' harmonized version of OCC codes across different editions 
    left_join(Occupation_crosswalk, by = c("OCC2010.x" ="OCC"))%>%
    rename(SOCXX.x=SOCXX, OCCUPATION.x=OCCUPATION)%>%
    ## note that we use OCC2010 for the merge, the IPUMS' harmonized version of OCC codes across different editions 
    left_join(Occupation_crosswalk, by = c("OCC2010.y" ="OCC"))%>%
    rename(SOCXX.y=SOCXX, OCCUPATION.y=OCCUPATION)%>%
    select(SOCXX.x, SOCXX.y, everything())
  
  
  Clean_transitions$missing <- is.na(Clean_transitions$SOCXX.x)
  Clean_transitions$missing_2 <- is.na(Clean_transitions$SOCXX.y)
  
  Clean_transitions %>% 
    filter(missing_2==TRUE) %>% 
    distinct(OCC2010.y,SOCXX.y)  # Crosswalk doesn't exclude OCC2010 occupations 
  
  
  
  #------------------------------------------------------------------------------------------------------------------------#
  # IND-NAICSXX croswalks (2020 addition)----------------------------------------------------------------------------------
  #------------------------------------------------------------------------------------------------------------------------#
  library(readxl)
  ## Brookings' developed  crosswalk
  ## This file has multiple crosswalks, including https://usa.ipums.org/usa/volii/indtoindnaics18.shtml
  ## Each of the mentioned here matches a version of the IND Census code
  
  INDXWALK <- read_excel("raw/Crosswalk_naicsxx_socxx/INDXWALK.xlsx", sheet = "INDXWALK") 
  
  IND_NAICSXX_03<-INDXWALK%>%
    group_by(CPS03,NAICSXX,INDUSTRY,SECTOR)%>%
    summarise(n=n())%>%
    ungroup()%>%
    filter(!is.na(NAICSXX) )%>%
    filter(!is.na(CPS03))%>%
    select(-n)
  
  IND_NAICSXX_09<-INDXWALK%>%
    group_by(CPS09,NAICSXX,INDUSTRY,SECTOR)%>%
    summarise(n=n()) %>%
    ungroup()%>%
    filter(!is.na(NAICSXX) )%>%
    filter(!is.na(CPS09))%>%
    select(-n)
  
  IND_NAICSXX_14<-INDXWALK%>%
    group_by(CPS14 ,NAICSXX,INDUSTRY,SECTOR)%>%
    summarise(n=n()) %>%
    ungroup()%>%
    filter(!is.na(NAICSXX) )%>%
    filter(!is.na(CPS14 ))%>%
    select(-n)
  
  
  table(unique(c(Clean_transitions$IND.x,Clean_transitions$IND.y))%in%INDXWALK$CPS03) ## Transitions data had cps03 ind codes
  table(unique(c(Clean_transitions$IND.x,Clean_transitions$IND.y))%in%INDXWALK$CPS09)
  table(unique(c(Clean_transitions$IND.x,Clean_transitions$IND.y))%in%INDXWALK$CPS14)

  Clean_transitions <- Clean_transitions %>%
    ## we drop less occupations by using the IND 2003
    left_join(IND_NAICSXX_03, by = c("IND.x" ="CPS03"))%>%
    rename(NAICSXX.x=NAICSXX, 
           INDUSTRY.x='INDUSTRY',
           SECTOR.x='SECTOR')%>%
    left_join(IND_NAICSXX_03, by = c("IND.y" ="CPS03"))%>%
    rename(NAICSXX.y=NAICSXX, 
           INDUSTRY.y='INDUSTRY',
           SECTOR.y='SECTOR') 
  
  ## we inspect the industry crosswalks        
  Clean_transitions$missing_i_x <- is.na(Clean_transitions$NAICSXX.x)
  Clean_transitions$missing_i_y <- is.na(Clean_transitions$NAICSXX.y)
  
  # The industry crosswalk can be improved
  Clean_transitions %>%
    filter(missing_i_x==TRUE) %>% 
    distinct(IND.x)                    
  
  ## Give order to the data.frame and creating the matrix
  Clean_transitions<-Clean_transitions%>%
    ## Remove records with unmatched industries
    filter(missing_i_y==FALSE & missing_i_x==FALSE) %>%
    ## Select variables you wish to include
    select(date.y, CPSIDP, starts_with("NAICSXX"), starts_with("SOCXX"),
           weight_pop, 
           starts_with("EMPSAME"), 
           starts_with("ACTSAME"), keep, drop, 
           starts_with("OCCUPATION"),
           starts_with("INDUSTRY"),
           LFPROXY.x,LFPROXY.y,
           starts_with("UH_"),starts_with("NATIVITY"),
           starts_with("RACE"),starts_with("SEX"),
           starts_with("AGE"),starts_with("EDUC"),
           starts_with("Region"),starts_with("MET"),
           starts_with("HISPAN"),starts_with("STATECENSUS"),
           starts_with("CLASSWKR"),starts_with("WKSTAT"),
           starts_with("JOBCERT"),starts_with("PROFCERT"))%>%
    mutate(SOCXX_NAICSXX.x=paste0(SOCXX.x,"-",NAICSXX.x),
           SOCXX_NAICSXX.y=paste0(SOCXX.y,"-",NAICSXX.y)) %>% 
    ## create transitions flags
    mutate(
      # flag used in WoF deliverables and reports
      transition_adj = case_when(CLASSWKR.x %in% c(13,14,26,29) ~ 0, # remove transitions of self-employed, individuals in the military and volunteers. 
                                 CLASSWKR.y %in% c(13,14,26,29) ~ 0, # idem 
                                 EDUC.x != EDUC.y ~ 0,               # remove transitions with no education change
                                 EMPSAME.y %in% c(96,97) ~ 0,        # remove transitions non-answering EMPSAME 
                                 SOCXX.x != SOCXX.y ~ 1,             #occupational transitions
                                 TRUE ~ 0),
      # raw transition measures
      transition = ifelse(SOCXX.x !=SOCXX.y,1,0), 
      transition_naicsxx=ifelse(NAICSXX.x!=NAICSXX.y,1,0),
      transition_socxx_naicsxx=ifelse(SOCXX_NAICSXX.x!=SOCXX_NAICSXX.y,1,0),
      ## flag matches where workers kept the same education level
      sameedu = ifelse(EDUC.x==EDUC.y,1,0),
      ## flag matches where workers are full-time in both the starting and ending months
      sameedu_fulltime = ifelse(EDUC.x==EDUC.y  & WKSTAT.x %in% c(10,11,12,14,15) & WKSTAT.y %in% c(10,11,12,14,15),
                                1,
                                0))
  
  
  ## Some calculations--------------
  ## transition rate with raw transitions
  sum(Clean_transitions$transition) # 277748 of 8,183,389 
  sum(Clean_transitions$transition)/nrow(Clean_transitions) # 3.4% 
  
  ## transition rates of employed workers w/o educational upgrading
  sum(Clean_transitions$transition_adj) #228366 of 8,183,389 
  sum(Clean_transitions$transition_adj)/nrow(Clean_transitions) #2.8% This is the transition rate we handle in our publications
  
  
  saveRDS(Clean_transitions, "data/Total_Transitions_weights_naicsxx_socxx_26.rds")
  
  
  #------------------------------------------------------------------------------------------------------------------------#
  # Collapsing transitions to the socxx level-------------------------------------------------------------------------------#
  #------------------------------------------------------------------------------------------------------------------------#
  Clean_transitions<-read_rds(path = "data/Total_Transitions_weights_naicsxx_socxx_26.rds")
  
  Clean_transitions_socxx<-Clean_transitions %>% 
    mutate(same_naics=(NAICSXX.x==NAICSXX.y),
           CLASSWKR_mil_vol_self= case_when(CLASSWKR.x %in% c(13,14,26,29) ~ 1,
                                            CLASSWKR.y %in% c(13,14,26,29) ~ 1,
                                            TRUE~0)) %>% 
    group_by(SOCXX.x,SOCXX.y,OCCUPATION.x,OCCUPATION.y,  
             RACE.y,SEX.y,AGE.y,EDUC.y, EMPSAME.y,sameedu,CLASSWKR_mil_vol_self) %>% 
    summarise(Records=n(),
              sum_weight_pop=sum(weight_pop),
              mean_weight_pop=mean(weight_pop)) %>% 
    ungroup()
  
  Clean_transitions_socxx_adjusted<-Clean_transitions_socxx %>% 
    mutate(transition=ifelse(SOCXX.y !=SOCXX.x ,1,0)) %>% 
    # remove those that don't match the full_time,same education, self employed wokrers, military 
    mutate(transition=ifelse(sameedu ==0 ,0,transition)) %>%       #only educational changes
    mutate(transition=ifelse(EMPSAME.y %in% c(96,97) ,0,transition)) %>%  #only good answers in EMPSAME
    mutate(transition=ifelse(CLASSWKR_mil_vol_self==1 ,0,transition) ) %>% #Not military, volunteers or self employed
    group_by(SOCXX.x,SOCXX.y,OCCUPATION.x,OCCUPATION.y,transition) %>% 
    summarise(records=sum(Records),                                     
              weight_pop=sum(sum_weight_pop)) %>% 
    ungroup() 
  
  
  # Same data, collapsed at the SOCXX level
  saveRDS(Clean_transitions_socxx_adjusted, "data/Total_Transitions_socxx_26.rds")
  
  Clean_transitions_socxx %>% 
    filter(SOCXX.y !=SOCXX.x) %>% 
    summarise(records=sum(Records))
  Clean_transitions_socxx_adjusted %>%
    filter(transition==1) %>% 
    summarise(records=sum(records))

  #------------------------------------------------------------------------------------------------------------------------#
  # Collapsing transitions to the naicsxx level-------------------------------------------------------------------------------#
  #------------------------------------------------------------------------------------------------------------------------#
  Clean_transitions<-read_rds(path = "data/Total_Transitions_weights_naicsxx_socxx_26.rds")
  
  Clean_transitions_naicsxx<-Clean_transitions %>% 
    mutate(same_naics=(NAICSXX.x==NAICSXX.y),
           CLASSWKR_mil_vol_self= case_when(CLASSWKR.x %in% c(13,14,26,29) ~ 1,
                                            CLASSWKR.y %in% c(13,14,26,29) ~ 1,
                                            TRUE~0)) %>% 
    group_by(NAICSXX.x, NAICSXX.y,INDUSTRY.x,INDUSTRY.y,  
             RACE.y,SEX.y,AGE.y,EDUC.y, EMPSAME.y,sameedu,CLASSWKR_mil_vol_self) %>% 
    summarise(Records=n(),
              sum_weight_pop=sum(weight_pop),
              mean_weight_pop=mean(weight_pop)) %>% 
    ungroup()
  
  Clean_transitions_naicsxx_adjusted<-Clean_transitions_naicsxx %>% 
    mutate(transition=ifelse(NAICSXX.y !=NAICSXX.x ,1,0)) %>% 
    # remove those that don't match the full_time,same education, self employed wokrers, military 
    mutate(transition=ifelse(sameedu ==0 ,0,transition)) %>%       #only educational changes
    mutate(transition=ifelse(EMPSAME.y %in% c(96,97) ,0,transition)) %>%  #only good answers in EMPSAME
    mutate(transition=ifelse(CLASSWKR_mil_vol_self==1 ,0,transition) ) %>% #Not military, volunteers or self employed
    group_by(NAICSXX.x, NAICSXX.y,INDUSTRY.x,INDUSTRY.y,transition) %>% 
    summarise(records=sum(Records),                                     
              weight_pop=sum(sum_weight_pop)) %>% 
    ungroup() 
  
  
  # Same data, collapsed at the NAICSXX level
  saveRDS(Clean_transitions_naicsxx_adjusted, "data/Total_Transitions_naicsxx_26.rds")
  
  ## counts are different given that we're talking about industry switches
  Clean_transitions_naicsxx %>% 
    filter(NAICSXX.x != NAICSXX.y) %>% 
    summarise(records=sum(Records))
  Clean_transitions_naicsxx_adjusted %>%
    filter(transition==1) %>% 
    summarise(records=sum(records))
  