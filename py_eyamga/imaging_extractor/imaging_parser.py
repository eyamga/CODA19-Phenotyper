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
import numpy as np
import matplotlib.pyplot as plt
import parser_fun
# from imp import load_source
#parser_fun = load_source('parser_fun', '/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/py_eyamga/imaging_extractor/parser_fun.py')

#%% Connection to the database and loading images URL using SQL script
# Loading database
SQLPATH = '/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/py_eyamga/imaging_extractor/sql/covid_imaging_72h_url.sql' #path of SQL script
con = parser_fun.database_connection()[0]
query = parser_fun.create_query_string(SQLPATH) #reformatting query string
imaging_uri = parser_fun.db_to_df(query, con) #loading URI as dataframe containing all URI

# Alternatively load already exported CSV
uri = pd.read_csv("/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/py_eyamga/imaging_extractor/csv/covid72huri.csv")

#%% Loading images in HD5 format into a np.array batch

# dir of images
# the real dir is covidb_full, will change eventually
LOCALPATH = '/data8/projets/Mila_covid19/output/covidb_mila/blob'

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
  url_complete = LOCALPATH + url
  #url_complete = j # alternative if using the dev_scratch_space
  if os.path.isfile(url_complete):
    with h5py.File(url_complete, 'r') as data_file:
      img = data_file['dicom'][:]
    plt.imshow(img)
    plt.show()
    OTHER_uri_dict[j] = input("Enter 'AP' or 'LA':")
  else:
    continue

# Converting dict into DF
classified = pd.DataFrame.from_dict(OTHER_uri_dict)

# All AP images
classified_PA = classified[classified[0]=='AP']
PA_URI = classified_PA[:,0]
uri[uri['slice_data_uri'].isin(PA_URI)]['slice_view_position']='AP'


# All LA images
classified_LA = classified[classified[1]=='LA']
LA_URI = classified_LA[:,0]
uri[uri['slice_data_uri'].isin(LA_URI)]['slice_view_position']='LA'


# Original uri dataframe now adequately classified

#%% Loading images in HD5 format into a np.array batch

# Re-updating the PA variable and selecting slice data uri & patient_site_iod
PA = uri[uri['slice_view_position']=='PA']
PA_URI = PA['patient_site_uid', 'slice_data_uri']

# feel free to adjust
image_size = (96,96)

# reading all PA images
train_images = []
train_files = PA_URI['slice_data_uri']
for f in train_files:
  url = f.split('BLOB_export')[1]
  url_complete = LOCALPATH + url
  with h5py.File(url_complete, 'r') as data_file:
    img = data_file['dicom'][:]
  img = img.resize(image_size)
  img_arr = np.array(img)
  train_images.append(img_arr)

X = np.array(train_images)
X.shape, train_y.shape
y = np.array(PA_URI['Id', 'Genre'],axis=1))


# Before batch, h, w -  Must add channel
#train_X = train_X.reshape(1750, 96, 96, 1)

#X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=42, test_size=0.1)
### Make sure to keep user id


#%% Deep Learning Application starts here




#%% Other

#sample image uri
url = "/0ac19c1b2fa4d2ad7749fed5ff018f3b4e7af00916701a4bd3677bb387ae99ec0d384bfa6c283a57844d607bd433cb3c442d90f1670ae3dbf680f3e989ceeb42/6bb25b93358fa717d3b7ff72f3c8e630049bf2b2f06c0a280744b29ff846aa7c622eb75453cb818060821a4be5b2bd5bb61b7abd1713228975a185740f53933e/1a0337123357d3b032cce26a6a84171381b9c975a04dbbcfd4f23bf07e9902dac9b47514cd87b2894ebe91d88e89a2b50b09f99ae7e979e3d7705caeb94f09ec/slice_0.h5"
url1 = "/0ac19c1b2fa4d2ad7749fed5ff018f3b4e7af00916701a4bd3677bb387ae99ec0d384bfa6c283a57844d607bd433cb3c442d90f1670ae3dbf680f3e989ceeb42/6bb25b93358fa717d3b7ff72f3c8e630049bf2b2f06c0a280744b29ff846aa7c622eb75453cb818060821a4be5b2bd5bb61b7abd1713228975a185740f53933e/435aae84c112a86fced9426644e80571dd86688c70cd58f57f83ce98692c026349af567e2c7474b5a83079acb246e77ff6efe0886eef211c0d4ede693bbb76ec/slice_0.h5"
url2 = "/0c66e57af6b1ce4a1d31085efbcac15c361ff956370786ede964872b68d276146256f56c8b1644f77ca76d858090a1d8ea1e0bd4b3d9974ed64112756184ec93/59657a2c00aeaff57d0291322ea58a52809059946524e1578f916880a414b6cfeebe5229d3d53ed7935be0188721c0965e6f8338d81df9931eecaa75514e72dd/59f5cea828a36086626c6ecb24429d95a5a380a77adfb2e6dba9f8ac3fa5451e9383fbd1d134aa41339b935c1d00281bae507a27aa59d85cf9a48943e5df7ed8/slice_0.h5"
url3 = "/0c66e57af6b1ce4a1d31085efbcac15c361ff956370786ede964872b68d276146256f56c8b1644f77ca76d858090a1d8ea1e0bd4b3d9974ed64112756184ec93/59657a2c00aeaff57d0291322ea58a52809059946524e1578f916880a414b6cfeebe5229d3d53ed7935be0188721c0965e6f8338d81df9931eecaa75514e72dd/3f977d45c68ce34c90314ed92284f792acb5ab756e19fa6fd03a59fc2bd96a2d35ba90495fcfde4024bc2c3824a9da603c6719f6aa1fecddad6dd07fee549a71/slice_0.h5"
