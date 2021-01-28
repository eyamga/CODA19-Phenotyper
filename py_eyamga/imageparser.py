''' This code is based on @Louis Mullies' initial script generate_slices. py
The purpose of this code is to
1) generate a CSV file with all the RX from COVID positive patient
2) loading the images for a deep learning model
'''

#%% Libraries
import os, csv, sqlite3
from imp import load_source
import parser_fun
from sqlite_utils import sql_fetch_all, sql_fetch_one
import pandas as pd
import numpy as np
from matplotlib import pyplot as plt

load_source('parser_fun', '/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/py_eyamga/parser_fun.py')

con = db_connect()[0]
cur = db_connect()[1]

#%% Reading and querying

# function to read sql queries

# Loading all the necessary Queries and Returning all the corresonpinding dataframes
SQLPATH = '/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/py_eyamga/sql/'

query = create_query_string(SQLPATH+filename)
        # Assiging adequate dataframe name to the corresponding query
        globals()[os.path.splitext(filename)[0]] = db_to_df(query)
        # Exporting as CSV
        globals()[os.path.splitext(filename)[0]].to_csv(index=False, path_or_buf = str(CSVPATH+os.path.splitext(filename)[0]+'.csv'))
        continue
    else:
        continue

