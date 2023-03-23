import pandas as pd
import sys
from os.path import dirname, join

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

    ndf.to_csv(op)


def main():
    group(sys.argv[1], sys.argv[2])

main()
