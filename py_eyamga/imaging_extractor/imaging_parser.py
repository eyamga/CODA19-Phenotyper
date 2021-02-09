"""
@author Eric Yamga
This script was heavily based on @Louis Mullie script
The objective is this script is to load all the imaging data file and ready for analysis
The following steps are taken
1) Querying SQL script that returns imaging URI
* the SQL script is provided in this folder
* the first SQL script returns imaging data for first 72h, the second SQL script returns imaging data for all COVID patients
2) Classifying PA from LA images
3) Converting images into batches to ready analysis in PyTorch
"""
#%% Loading the libraries
import os
import pandas as pd
import json
import h5py
import cv2
import numpy as np
from matplotlib import pyplot as plt
#import parser_fun
from imp import load_source
parser_fun = load_source('parser_fun', '/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/py_eyamga/imaging_extractor/parser_fun.py')

#%% Connection to the database and loading images URL using SQL script
# Loading database
#SQLPATH = '/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/py_eyamga/imaging_extractor/sql/covid_imaging_72h_url.sql' #path of SQL script
#con = parser_fun.database_connection()[0]
#query = parser_fun.create_query_string(SQLPATH) #reformatting query string
#imaging_uri = parser_fun.db_to_df(query, con) #loading URI as dataframe containing all URI

# Alternatively load already exported CSV
# lm based uris
#%% Loading images in HD5 format into a np.array batch

# dir of images
# the real dir is covidb_full, will change eventually
#LOCALPATH = '/data8/projets/Mila_covid19/output/covidb_mila/blob' #new version
#LOCALPATH = '/data8/projets/dev_scratch_space/lmullie/scratch/BLOB_export' #old version
LOCALPATH = '/Users/eyamga/Documents/Médecine/Recherche/CODA19/data/blob'
#ERICPATH = '/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/py_eyamga/imaging_extractor/'
ERICPATH = '/Users/eyamga/Documents/Médecine/Recherche/CODA19/git/CODA19-Phenotyper/py_eyamga/imaging_extractor'
#EXPORTPATH = '/data8/projets/Mila_covid19/data/covidphenotyper/'
EXPORTPATH = '/Users/eyamga/Documents/Médecine/Recherche/CODA19/git/images'

# Loading images data
#uri = pd.read_csv("/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/py_eyamga/imaging_extractor/csv/covid_all_uri_lm.csv")
uri = pd.read_csv(ERICPATH + "/csv/covidalluri_new.csv")




# Filtering unknown view positions
PA = uri[uri['slice_view_position']=='AP']
OTHER = uri[uri['slice_view_position']!='AP']
OTHER_uri = OTHER['slice_data_uri']
# Manual labeling of incidence images
# This for loop iterates over the images and takes the user input as a label
OTHER_uri_dict = dict.fromkeys(OTHER_uri, None)
for i,j in enumerate(OTHER_uri_dict):
  # Visualize the image
  print('This is the, {}th image'.format(i))
  #url = j.split('BLOB_export')[1]
  url = j.split('blob')[1]
  url_complete = LOCALPATH + url
  #url_complete = j # alternative if using the dev_scratch_space
  if os.path.isfile(url_complete):
    with h5py.File(url_complete, 'r') as data_file:
      img = data_file['dicom'][:]
    plt.imshow(img)
    plt.show()
    OTHER_uri_dict[j] = str(input("Enter 'AP' or 'LA':"))
  else:
    continue

# Converting dict into DF
classified = pd.DataFrame.from_dict(OTHER_uri_dict, orient = 'index')
classified['slice_data_uri'] = classified.index
classified.reset_index(drop=True)


# All AP images
classified_AP = classified[classified[0]=='AP']
AP_URI = classified_AP.iloc[:,1]
uri.loc[uri['slice_data_uri'].isin(AP_URI), 'slice_view_position']='AP'


# All LA images
classified_LA = classified[classified[0]=='LA']
LA_URI = classified_LA.iloc[:,1]
uri.loc[uri['slice_data_uri'].isin(LA_URI), 'slice_view_position']='LA'


# Original uri dataframe now adequately classified

#%% Loading images in HD5 format into a np.array batch

# Re-updating the PA variable and selecting slice data uri & patient_site_iod
AP = uri[uri['slice_view_position']=='AP']
AP_URI = AP.loc[:,['patient_site_uid', 'slice_data_uri']]




# Creating a HDF5 dataset
# reading all PA images
train_images = []
train_files = AP_URI['slice_data_uri']

# Data Size
HEIGHT = 2500
WIDTH = 2500
CHANNELS = 1
SHAPE = (HEIGHT, WIDTH, CHANNELS)


# First version of dataset creation

def savingset():
    with h5py.File(EXPORTPATH + '/data.h5', 'w') as hf:
        j = 1
        for i, f in enumerate(train_files):
            # Visualize the image
            # url = f.split('BLOB_export')[1]
            url = f.split('blob')[1]
            url_complete = LOCALPATH + url
            # url_complete = f # alternative if using the dev_scratch_space
            if os.path.isfile(url_complete):
                with h5py.File(url_complete, 'r') as data_file:
                    img = data_file['dicom'][:]
                    img = cv2.equalizeHist(img)
                    img = cv2.resize(img, (WIDTH, HEIGHT), interpolation=cv2.INTER_CUBIC)
                    plt.imshow(img, cmap='gray')
                    plt.show()
                    # img_arr = np.array(img)
                    # train_images.append(img_arr)
                    Xset = hf.create_dataset(
                        name='X' + str(j),
                        data=img,
                        # shape = SHAPE,
                        # maxshape = SHAPE,
                        compression=None)
                    print("A total of " + str(j) + " images were recorded in the set")
                    # Labels (here simply PID)
                    pid = AP_URI.loc[AP_URI['slice_data_uri'] == f].patient_site_uid
                    yset = hf.create_dataset(
                        name='y' + str(j),
                        shape=(1,),
                        data=pid)
                    # maxshape = (None,),
                    # compression = None)
                    print(pid)
                    j = j + 1



# Second version of dataset creation

def savingset_2 (NIMAGES):
    train_shape = (NIMAGES, 2500, 2500)
    f = h5py.File(EXPORTPATH + '/data2.h5', mode='w')
    f.create_dataset("train_img", train_shape, np.uint8)
    f.create_dataset("train_labels", (NIMAGES,), np.uint8)
    count = 1
    for i, j in enumerate(train_files):
        # Visualize the image
        # url = f.split('BLOB_export')[1]
        url = j.split('blob')[1]
        url_complete = LOCALPATH + url
        # url_complete = f # alternative if using the dev_scratch_space
        if os.path.isfile(url_complete):
            with h5py.File(url_complete, 'r') as data_file:
                img = data_file['dicom'][:]
                img = cv2.equalizeHist(img)
                img = cv2.resize(img, (WIDTH, HEIGHT), interpolation=cv2.INTER_CUBIC)
                #img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
                plt.imshow(img, cmap='gray')
                plt.show()
                pid = AP_URI.loc[AP_URI['slice_data_uri'] == j].patient_site_uid
                f["train_img"][count, ...] = img[None]
                f["train_labels"][count, ...] = pid
                count = count + 1
                print("A total of " + str(count) + " images were recorded in the set")
    f.close()


#%% Testing the dataset
with h5py.File(EXPORTPATH + '/data.h5', 'r') as hf:
    plt.imshow(hf['X28'], cmap='gray')
    plt.show()
    print(hf['y28'].value)

dataset = h5py.File(EXPORTPATH + '/data2.h5', 'r')

#%%  Deep Learning Application starts here
def show_image(x):
    x.astype('float32') / 255.0 - 0.5
    #plt.imshow(np.clip(x + 0.5, 0, 1))
    plt.imshow(x)
    plt.show()
