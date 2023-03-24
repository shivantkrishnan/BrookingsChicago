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

    reg_exp = 'salary ~ Time_Period + Treated + Time_Period*Treated'
    y_train, X_train = dmatrices(reg_exp, df, return_type='dataframe')

    did_model = sm.OLS(endog=y_train, exog=X_train)
    did_model_results = did_model.fit()

    print(did_model_results.summary())

def main():
    run_did(sys.argv[1])

main()
