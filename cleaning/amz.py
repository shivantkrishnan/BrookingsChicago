import pandas as pd
import sys
from os.path import dirname, join

# Creates smaller csv with the data we care about and
# in specific location.
def group(state:str):
    project_root = dirname(dirname(__file__))
    output_path = join(project_root, 'Data')
    inp = join(output_path, 'cleaned_pos_educ_amazon.csv')
    output = state + 'small_amz.csv'
    op = join(output_path, output)
    df = pd.read_csv(inp, sep=',')
    ndf = df[df["state"] == state]
    ndf = ndf[ndf["job_category"] == "Operations"]

    jl = join(output_path, 'jobs_map.txt')
    with open(jl, 'r') as f:
        s = f.read()
        jobs = s.split('\n')

    ndf = ndf[ndf["mapped_role"].isin(jobs)]
    ndf.to_csv(op)


def main():
    group(sys.argv[1])

main()
