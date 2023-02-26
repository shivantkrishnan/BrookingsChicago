import pandas as pd
import sys
from os.path import dirname, join


# System input is file to parse. Directly prints to command line.
def main():
    project_root = dirname(dirname(__file__))
    output_path = join(project_root, 'Data')
    inp = join(output_path, sys.argv[1])
    df = pd.read_csv(inp, sep=',')

    dic = {}
    for elem in df["mapped_role"]:
        if elem in dic:
            dic[elem] += 1
        else:
            dic[elem] = 1

    for keys,values in dic.items():
        print(keys)
        print(values)

main()
