import pandas as pd
import sys
from os.path import dirname, join
import numpy as np

def addDelta(input:str):

    project_root = dirname(dirname(__file__))
    output_path = join(project_root, 'Data')
    inp = join(output_path, input)
    output = 'delta' + input
    op = join(output_path, output)
    df = pd.read_csv(inp, sep=',')

    df['delta'] = -1 * df['salary'].diff(periods=-1)
    df['transition'] = np.where(df['user_id'] == df['user_id'].shift(-1), True, False)

    df.to_csv(op)


def main():

    addDelta(sys.argv[1])

main()
