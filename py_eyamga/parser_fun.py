''' Functions necessary sto run SQL lite queries '''
import os

SQLITE_DIRECTORY = '/data8/projets/Mila_covid19/output/covidb_full/sqlite'
DEFAULT_PATH = db_files_name = os.path.join(SQLITE_DIRECTORY, 'covidb_version-1.0.0.db')

def db_connect(db_path=DEFAULT_PATH):
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    return con, cur

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
