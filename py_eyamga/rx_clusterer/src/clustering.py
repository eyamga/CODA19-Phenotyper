#%% Loading the libraries


from sklearn.cluster import KMeans
import h5py
import numpy as np
import matplotlib.pyplot as plt

# from rxbatch_ey import minibatch_train
from imp import load_source
rxbatch = load_source('rxbatch', '/Users/eyamga/Documents/Médecine/Recherche/CODA19/git/CODA19-Phenotyper/py_eyamga/rx_clusterer/src/rxbatch_ey.py')

#%% Creating batch

batch, ids = rxbatch.minibatch_train(25,5)
batch2 = batch.reshape((batch.shape[0], -1))

#%% Clustering

# number of clusters
n_clusters = 3
kmeans = KMeans(n_clusters=n_clusters, n_init=20, n_jobs=4)
y_pred_kmeans = kmeans.fit_predict(batch2)
