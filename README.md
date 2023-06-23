# BrookingsChicago
Repository for all code relevant to [Harvard Economics Labs -- UChicago -- Brookings] Spring 2023
(For us) Optional README that can be developed later in case we want to save details for project. Ideally we'd have Shivant largely write it as it relates a lot to overarching goals and purpose of the project but I (Ian) will start by just outlining the general structure and then  we can add more documentation later.

What to include:

Key Question: How does the presence of Amazon Fulfillment Centers affect regional employment (labor shortages) and economic mobility outcomes for warehouse workers?
Project Title
Project Description
  - Describe what the code does in relation to research
  - Why we used given technologies
  - Challenges we have to help any future development
Table of contents (If project gets large - I don't expect it will be needed)
How to install and run
How to use the code
Credits for team members
License if you want to be fancy

A vast body of literature suggests that investments in the warehousing industry for the purpose of jobs and providing opportunities are not achieving what they are supposed to. Warehouse jobs tend to be very attractive in low-income areas that contain job-hungry workers in search of better opportunities, but this comes at a significant cost. In particular, when policymakers discuss the mobility potential of warehouse/logistics sector jobs, they often lump together blue-collar roles with managerial and other high wage positions (De Lara, 2013). Broadly, we hope to disaggregate these roles and understand that the industry wage models are not representative of the average blue-collar warehouse worker and his mobility potential. We construct two models to answer both relevant questions. When examining regional employment, we use county-level employment to population ratio as the variable of interest, along with a difference-in-differences approach to estimate whether employment in some counties is significantly different from others that do not have Amazon Fulfillment Centers. We use a similar approach for economic mobility, but we substitute the variable of interest as workers’ movement between quintiles of the income distribution. Such methods may uncover which sectors tend to suffer labor shortages as a result of Fulfillment Centers opening. Further, the findings will indicate the extent to which warehouses are responsible for an increase in worker mobility outcomes. Ultimately, our findings will address the mobility outcomes and market inefficiencies that result from an increase in warehousing employment. 
HOW TO RUN

In order to run the project's scripts, you need to reproduce the virtual environment on your local machine. Create a virtual environment, activate it, and then install the requirements to the virtual environment. (Will not be on your global machine) Should look like:

```
~ % python3 -m venv EcLabs/env
~ % source EcLabs/env/bin/activate
(env) ~ % pip install -r requirements.txt
```

Work should be done in the virtual environment. To go back to base status run the command:









Phase 1. Introduction
Week of January 30th (Week 0)
Analyst training
Analysts read through full “Moving Up” report.
Analysts review full background rsch document.

Week of February 6th (Week 1)
Data transfer from Brookings to EcLabs, around or before February 10th 
Introductory data session with team and {Brookings RA - will find out name} to provide the team with an overview of the databases used. Will begin to consider possible analysis techniques at this time – TBD on February 17
Review CPS monthly occupational data, Brookings internal “Transitions Dataset,” resumes scraped from LinkedIn
Familiarization with different aspects of the dataset(s) 
CPS monthly occupational data (smaller sample)
CPS IPUMS data
Worker Transitions
Full team meeting (Feb 17)

Phase 2. Literature Review and Initial Analysis
Weeks 2-3
Literature review: Collect information from public reports and recent literature in these topics
Regional unemployment
Warehouse employment
Economic insecurity
Economic mobility
Labor shortages
How the Warehouse Boom Devoured America's Workforce
Unfulfilled Promises: AFCs do NOT create employment growth
Complete any data cleaning that would be necessary – mapping workers to different warehouse roles, creating bins based on tenures at Amazon, and such.
Cleaning processes adapted from ​​Measuring the Economics of a Pandemic: How People Mobility depict Economics? An Evidence of People's Mobility Data towards Economic Activities.
Decide county/region organization

Phase 3. Updating Analysis from Initial Reports/Literature
Weeks 4-7
Distribution of counties, controlling for population differences
Percent change in regional employment pre- and post- Amazon Fullfillment Centers (AFC)s
Differences in regional income distributions 
Presence of large/competing industries that may “steal” eager workers
Time horizon of data


Tasks:
Finalize modeling/analysis method, weigh the following options
Difference-in-differences style
Outcome variable: county-level employment/population ratio
Treatment variable: Presence or absence of AFC
Heterogeneity across counties: Account for by including county-fixed effects. Consider the relevant controls, e.g. county-level demographic characteristics, regional economic conditions.
Time-fixed effects regression
Random effects regression 
Finalize method for mobility model: Tentatively, set outcome variable as movement between income quintiles 
Finalize key variables
Consider methodological improvements of this approach over existing ones

Phase 4. Final Analysis and Relevance (2 steps – A) labor markets B) mobility)
Weeks 8-10
Complete model
A: How did regional employment change as a result of AFC presence?
B: How did workers’ mobility outcomes change as a result of AFC?
Collect these findings into more general conclusions on the overall economic impact of warehouse employment 

Phase 5. Loose Ends and Conclusion
Finish any additional analysis, complete writing the report
Format into LaTeX
