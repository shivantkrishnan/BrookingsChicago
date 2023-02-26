import pandas as pd
import numpy as np
import statsmodels.api as sm
import datetime as dt

# Section 1: LOAD CPS RAW DATA AND IDENTIFY TRANSITIONS

# 1.1 SIMPLE APPROACH TO DATA
cps_ddi = pd.read_csv('raw/cps_00027.xml')
cps_data = pd.read_csv('raw/cps_data.csv')

# convert date column to datetime
cps_data['date'] = pd.to_datetime(cps_data['date'], format='%Y%m%d')

# 1.3 Loop over the transitions dataset

start_date = dt.datetime(2000, 1, 1)
end_date = dt.datetime(2022, 12, 1)

months = pd.date_range(start=start_date, end=end_date, freq='MS')

for i in range(len(months)-1):
    date1 = months[i]
    date2 = months[i+1]
    dates = [
        f"{date1.year}-{date1.month}-01",
        f"{date2.year}-{date2.month}-01"
    ]
    years = [date1.year, date2.year]
    
    t = datetime.now()
    
    w = cps_data[
        (cps_data["YEAR"].isin(years)) & 
        (cps_data["date"].isin(dates)) &
        (cps_data["WTFINL"] > 0)
    ]
    w["date"] = pd.to_datetime(w["date"])
    
    print(datetime.now() - t, "duration")
    
    # Split by months and merge
    TransitionsW = pd.merge(
        w[w["date"] == date1],
        w[w["date"] == date2],
        on="CPSIDP",
        how="inner"
    )
    
    # Drop the unemployed
    TransitionsW = TransitionsW.assign(
        EMPLOYED_x = np.where(TransitionsW["EMPSTAT_x"].isin([10, 12]), 1, 0),
        EMPLOYED_y = np.where(TransitionsW["EMPSTAT_y"].isin([10, 12]), 1, 0),
    ).query("EMPLOYED_x == 1 & EMPLOYED_y == 1")
    
    # Inform when loop gets to the last period so we're sure that's where the error came from
    if TransitionsW.empty:
        print(f"FAIL: {date1}")
        continue
    
    TransitionsW = TransitionsW.loc[:, [
        "OCC_x", "OCC_y", "SEX_x", "SEX_y", "RACE_x", "RACE_y", "AGE_x", "AGE_y",
        "IND_x", "IND_y", "LFPROXY_x", "LFPROXY_y", "EMPSAME_x", "EMPSAME_y",
        "QOCC_x", "QOCC_y", "QIND_x", "QIND_y", "ACTSAME_x", "ACTSAME_y",
        "EDUC_x", "EDUC_y", "WTFINL_x", "WTFINL_y", "date_x", "date_y", "MISH_x",
        "MISH_y", "OCC2010_x", "OCC2010_y", "CPSIDP"
    ] + [col for col in TransitionsW.columns if col.startswith("UH_")]
    + [col for col in TransitionsW.columns if col.startswith("NATIVITY")]
    + [col for col in TransitionsW.columns if col.startswith("REGION")]
    + [col for col in TransitionsW.columns if col.startswith("STATECENSUS")]
    + [col for col in TransitionsW.columns if col.startswith("METFIPS")]
    + [col for col in TransitionsW.columns if col.startswith("METAREA")]
    + [col for col in TransitionsW.columns if col.startswith("HISPAN")]
    + [col for col in TransitionsW.columns if col.startswith("CLASSWKR")]
    + [col for col in TransitionsW.columns if col.startswith("WKSTAT")]
    + [col for col in TransitionsW.columns if col.startswith("JOBCERT")]
    + [col for col in TransitionsW.columns if col.startswith("PROFCERT")]]

    # Flag possible drops
    TransitionsW = TransitionsW.assign(bad_match = np.where((TransitionsW['SEX.x'] == TransitionsW['SEX.y']) & (TransitionsW['RACE.x'] == TransitionsW['RACE.y']) & (TransitionsW['AGE.y'] >= TransitionsW['AGE.x']) & (TransitionsW['AGE.y'] < (TransitionsW['AGE.x'] + 3)), 0, 1))
    TransitionsW = TransitionsW.assign(impO = np.where((TransitionsW['QOCC.y'].isin([1, 2, 3, 4, 5, 6, 7, 8])) | (TransitionsW['QOCC.x'].isin([1, 2, 3, 4, 5, 6, 7, 8])), 1, 0))
    TransitionsW = TransitionsW.assign(impI = np.where((TransitionsW['QIND.y'].isin([1, 2, 3, 4, 5, 6, 7, 8])) | (TransitionsW['QIND.x'].isin([1, 2, 3, 4, 5, 6, 7, 8])), 1, 0))

    # Flag all possible drops and mark keeps
    TransitionsW = TransitionsW.assign(drop = np.where((TransitionsW['impO'] == 1) | (TransitionsW['impI'] == 1) | (TransitionsW['bad_match'] == 1), 1, 0))
    TransitionsW = TransitionsW.assign(keep = 1 - TransitionsW['drop'])
    # Factor variables for logistic regression
    TransitionsW['SEX.y'] = pd.factorize(TransitionsW['SEX.y'])[0]
    TransitionsW['RACE.y'] = pd.factorize(TransitionsW['RACE.y'])[0]
    TransitionsW['EDUC.y'] = pd.factorize(TransitionsW['EDUC.y'])[0]
    TransitionsW['SEX.x'] = pd.factorize(TransitionsW['SEX.x'])[0]
    TransitionsW['RACE.x'] = pd.factorize(TransitionsW['RACE.x'])[0]
    TransitionsW['EDUC.x'] = pd.factorize(TransitionsW['EDUC.x'])[0]

    # Get weights from drops
    logit_x = sm.GLM(TransitionsW['keep'], sm.add_constant(TransitionsW[['AGE.x', 'RACE.x', 'SEX.x', 'EDUC.x']]),
                    family=sm.families.Binomial(), data=TransitionsW)
    result = logit_x.fit()

    # Create dataset of kept observations and attach the probability of being kept for each record
    TransitionsW_kept = TransitionsW.loc[TransitionsW['keep'] == 1]
    predictions_1 = result.predict(TransitionsW_kept)

    # Calculate the overall labor force size
    total_weights_date_1 = (
    w.query("MONTH == @date2.month")
    .query("EMPSTAT in [10, 12, 21, 22]")
    .query("OCC != 0")
    .agg({"WTFINL": "sum"})
    .item())
    
    kept_weights_date_1 = TransitionsW["WTFINL.x"].sum()
    
    adj = 1 / (kept_weights_date_1 / total_weights_date_1)  # adjustment factor
    
    TransitionsW_kept = TransitionsW_kept.assign(
    weight_pop=lambda x: x["WTFINL.x"] * (1 / predictions_1) * adj)

    # print unadjusted and adjusted weights
    # print(TransitionsW_kept["WTFINL.x"].sum())
    # print(TransitionsW_kept["weight_pop"].sum())

    # append matched records (already weighted) to the Transitions_CW table
    con = pd.io.sql.get_schema(TransitionsW_kept, "Transitions_CW", con=engine).create()
    TransitionsW_kept.to_sql("Transitions_CW", con=con, if_exists="append", index=False)
    con.close()

    del TransitionsW_kept, logit_x, predictions_1

    print(months[i])