import pandas as pd
import sys
from os.path import dirname, join
import numpy as np

# Creates smaller csv with the data we care about and
# in specific location.
def group(state:str, file:str):
    project_root = dirname(dirname(__file__))
    output_path = join(project_root, 'Data')
    inp = join(output_path, file)
    output = state + 'small_' + file
    op = join(output_path, output)
    df = pd.read_csv(inp, sep=',')
    ndf = df[df["state"] == state]

    jl = join(output_path, 'jobs_map.txt')
    with open(jl, 'r') as f:
        s = f.read()
        jobs = s.split('\n')

    if file == 'cleaned_pos_educ_amazon.csv':
        ids = ndf.loc[(ndf['mapped_role'].isin(jobs)) & (ndf['company_cleaned'] == 'amazon'), ['user_id']]
        ndf = ndf[ndf['user_id'].isin(ids['user_id'].to_list())]

    ndf = ndf.sort_values(by=['user_id', 'startdate', 'enddate'])

    ndf['transition'] = np.where(ndf['user_id'] == ndf['user_id'].shift(-1), 1, 0)
    ndf['transition'] = np.where((ndf['transition'] == 1) & (ndf['mapped_role'].isin(jobs)), 1, 0)
    ndf['Time_Period'] = ndf['transition'].shift(1)
    ndf['Time_Period'] = ndf['Time_Period'] + ndf['transition']
    ndf = ndf[ndf['Time_Period'] == 1]
    ndf['Time_Period'] = ndf['Time_Period'] - ndf['transition']
    
    ndf['Treated'] = np.where((ndf['Time_Period'] == 0) & (ndf['company_cleaned'] == 'amazon'), 1, 0)
    ndf['Treated'] = ndf['Treated'] + ndf['Treated'].shift(1)

    ndf.to_csv(op)


def main():
    group(sys.argv[1], sys.argv[2])

main()
