import pandas as pd
import sys
from os.path import dirname, join

# Creates smaller csv with the data we care about and
# in specific location.
def group(state:str):
    project_root = dirname(dirname(__file__))
    output_path = join(project_root, 'Data')
    inp = join(output_path, 'cleaned_pos_educ_amazon.csv')
    op = join(output_path, 'small_amz.csv')
    df = pd.read_csv(inp, sep=',')
    ndf = df[df["state"] == state]
    ndf = ndf[ndf["job_category"] == "Operations"]
    ndf.to_csv(op)

def main():
    group(sys.argv[1])

main()
