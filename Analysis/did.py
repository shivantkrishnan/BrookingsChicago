import pandas as pd
from patsy import dmatrices
import statsmodels.api as sm
import numpy as np
import sys
from os.path import dirname, join


def run_did(filename:str):
    project_root = dirname(dirname(__file__))
    output_path = join(project_root, 'Data')
    inp = join(output_path, filename)
    df = pd.read_csv(inp, sep=',')

    jl = join(output_path, 'jobs_map.txt')
    with open(jl, 'r') as f:
        s = f.read()
        jobs = s.split('\n')

    def tran0(row):
        if row['transition'] == True and row['mapped_role'] in jobs:
            return 0
        return -1

    def tran1(row):
        if row['Time_Period1'] == 1 and row['Time_Period'] == -1:
            return 1

    df['Time_Period'] = df.apply(tran0, axis=1)
    df['Time_Period1'] = np.where((df['transition'].shift(1) == 0), 1, -1)
    df['Time_Period'] = df.apply(tran1, axis=1)

    df = df[df['Time_Period'] != -1]

    df['Treated'] = np.where(((df['Time_Period'] == 0) & (df['company_cleaned'] == 'amazon')), 1, -1)
    df['Treated'] = np.where(((df['Treated'] != 1) & (df['Time_Period'] == 1) & (df['company_cleaned'].shift(1) == 'amazon')), 1, 0)

    reg_exp = 'salary ~ Time_Period + Treated + Time_Period*Treated'
    y_train, X_train = dmatrices(reg_exp, df, return_type='dataframe')

    did_model = sm.OLS(endog=y_train, exog=X_train)
    did_model_results = did_model.fit()

    print(did_model_results.summary())

def main():
    run_did(sys.argv[1])

main()
