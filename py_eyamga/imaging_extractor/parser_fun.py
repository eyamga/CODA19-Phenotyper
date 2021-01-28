""" functions and libraries necessary to run the imaging parser"""

#import pyodbc
import os
import textwrap
import sqlite3

#%% Connection to the database

SQLITE_DIRECTORY = '/data8/projets/Mila_covid19/output/covidb_full/sqlite/'
db_file_name = os.path.join(SQLITE_DIRECTORY, 'covidb_version-1.0.0.db')
DEFAULT_PATH = db_file_name

def database_connection(db_path=DEFAULT_PATH):
    """
    This function loads the database and returns a connection and cursor as a tuple
    """
    con = sqlite3.connect(db_file_name)
    cur = con.cursor()

    return con, cursor

def db_to_df(query, engine):
    """
    This function reads table from the db and saves it into a pandas dataframe
    :param query: refers to the SQL query, must be string surrounded by triple single quotes '''
    :return: df
    toy example
    df = db_to_df('''SELECT * FROM  "episode_data" LIMIT 300 OFFSET 0''')
    """
    # reading sql query using pandas
    return pd.read_sql_query(str(query), engine)
    # saving SQL table in a df

# function to read sql queries
def create_query_string(sql_full_path):
    with open(sql_full_path, 'r') as f_in:
        lines = f_in.read()
        # remove any common leading whitespace from every line
        query_string = textwrap.dedent("""{}""".format(lines))

    return query_string
