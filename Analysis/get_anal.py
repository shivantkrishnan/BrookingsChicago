import pandas as pd
import sys
from os.path import dirname, join

def print_anal(filename:str):

    project_root = dirname(dirname(__file__))
    output_path = join(project_root, 'Data')
    inp = join(output_path, filename)
    df = pd.read_csv(inp, sep=',')

    mean = df.loc[(df['transition'] == True) & (df['company_cleaned'] == 'amazon'), 'delta'].mean()

    message = 'Mean salary change upon transition: ' + str(mean)

    print(message)


def main():

    print_anal(sys.argv[1])

main()
