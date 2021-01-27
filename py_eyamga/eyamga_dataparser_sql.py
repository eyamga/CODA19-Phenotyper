"""

@author : Eric Yamga

Objective of this script is to parse the CODA19 database into meaningful and potentially analyzable data
In terms of formatting, the script will be divided using the ipynb syntax for esthetic purposes
    re : %% for code cells and %% md for markdown cells/comments

First : we load all SQL query scripts from the SQL directory
Second : we connect to the CODA19 SQLITE db_connect
Third : we query and export the data as CSV in the CSV directory
NB all those directories are located on the local eyamga folder but script can be modified for other purposes
"""


#%% Libraries
import os, csv, sqlite3
from sqlite_utils import sql_fetch_all, sql_fetch_one

import pandas as pd
import numpy as np
from matplotlib import pyplot as plt

import json

#%% Connection to the database
SQLITE_DIRECTORY = '/data8/projets/Mila_covid19/output/covidb_full/sqlite'
DEFAULT_PATH = db_file_name = os.path.join(SQLITE_DIRECTORY, 'covidb_version-1.0.0.db')

def db_connect(db_path=DEFAULT_PATH):
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    return con, cur

con = db_connect()[0]
cur = db_connect()[1]

#%% Reading and querying

# function to read sql queries

def create_query_string(sql_full_path):
    with open(sql_full_path, 'r') as f_in:
        lines = f_in.read()
        # remove any common leading whitespace from every line
        query_string = textwrap.dedent("""{}""".format(lines))

    return query_string

def db_to_df(query):
    """
    This function reads table from the db and saves it into a pandas dataframe
    :param query: refers to the SQL query, must be string surrounded by triple single quotes '''
    :return: df
    toy example
    df = db_to_df('''SELECT * FROM  "episode_data" LIMIT 300 OFFSET 0''')
    """
    # reading sql query using pandas
    return pd.read_sql_query(str(query), con)
    # saving SQL table in a df

# Loading all the necessary Queries and Returning all the corresonpinding dataframes

SQLPATH = '/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/py_eyamga/sql/'
CSVPATH = '/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/py_eyamga/csv/'
for filename in os.listdir(SQLPATH):
    i = 0
    if filename.endswith(".sql"):
        query = create_query_string(SQLPATH+filename)
        # Assiging adequate dataframe name to the corresponding query
        globals()[os.path.splitext(filename)[0]] = db_to_df(query)
        # Exporting as CSV
        globals()[os.path.splitext(filename)[0]].to_csv(index=False, path_or_buf = str(CSVPATH+os.path.splitext(filename)[0]+'.csv'))
        continue
    else:
        continue

