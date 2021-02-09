#%% Loading the libraries

from PIL import Image
from sklearn.cluster import KMeans
import h5py
import numpy as np
import matplotlib.pyplot as plt
from time import time
import numpy as np
import keras.backend as K

from sklearn.model_selection import train_test_split
from keras.engine.topology import Layer, InputSpec
from keras.layers import Dense, Input
from keras.models import Model
from keras.optimizers import SGD
from keras import callbacks
from keras.initializers import VarianceScaling
from sklearn.cluster import KMeans
# import metrics
from tqdm import tqdm
from keras_tqdm import TQDMCallback
from imp import load_source


#%% Loading modules

# Batch creation module
# from rxbatch_ey import minibatch_train
rxbatch = load_source('rxbatch', '/Users/eyamga/Documents/Médecine/Recherche/CODA19/git/CODA19-Phenotyper/py_eyamga/rx_clusterer/src/rxbatch_ey.py')
# Models
clustering_utils = load_source('clustering_utils', '/Users/eyamga/Documents/Médecine/Recherche/CODA19/git/CODA19-Phenotyper/py_eyamga/rx_clusterer/src/clustering_utils.py')


CLUSTERPATH = '/Users/eyamga/Documents/Médecine/Recherche/CODA19/git/CODA19-Phenotyper/py_eyamga/rx_clusterer/output/clusters/'

#%% Creating batch

batch, ids = rxbatch.minibatch_train(25,5)

# Creating another batch set in from 3D to 2d to apply Kmeans
#batch2 = batch.reshape((batch.shape[0], -1))

#%%  K-Means Clustering
# number of clusters
n_clusters = 3
kmeans = KMeans(n_clusters=n_clusters, n_init=20, n_jobs=4)
y_pred_kmeans = kmeans.fit_predict(batch2)

# Verifying the clusters
for i in range(n_clusters):
    print("This is the " + str(i) + "th cluster")
    n_cluster_images = sum(y_pred_kmeans==[i])
    cluster_bool_index = y_pred_kmeans==[i]
    print("There are " + str(n_cluster_images) + " images in this cluster : ")
    #input("Press Enter to continue...")
    for j in range(n_cluster_images):
        tmp = batch[cluster_bool_index][j]
        #plt.imshow(tmp, cmap='gray')
        #plt.show()
        im = Image.fromarray(tmp)
        im.save(CLUSTERPATH + str(i) + "/" + "rx_" + str(j) + ".jpeg")


#%%  Auto-encoder based clustering (V1)

dims = [batch2.shape[-1], 500, 500, 2000, 10]
init = VarianceScaling(scale=1. / 3., mode='fan_in',
                           distribution='uniform')
pretrain_optimizer = SGD(lr=1, momentum=0.9)
pretrain_epochs = 300
batch_size = 25
save_dir = './results'

autoencoder, encoder = clustering_utils.autoencoder(dims)
autoencoder.compile(optimizer=pretrain_optimizer, loss='mse')
autoencoder.fit(batch, batch, batch_size=batch_size, epochs=pretrain_epochs) #, callbacks=cb)
autoencoder.save_weights(save_dir + '/ae_weights.h5')




#%%  TSNE based clustering (V2)

X_train, X_test = train_test_split(batch, test_size=0.1, random_state=42)
tmp = batch[1]

IMG_SHAPE = batch.shape[1:] #since index 2,3 = image shape and index 1 = image index
encoder, decoder = clustering_utils.build_autoencoder(IMG_SHAPE, 2500)

input = Input(IMG_SHAPE)
code = encoder(input)
reconstruction = decoder(code) #input is the output of the encoder

autoencoder = Model(input,reconstruction)
autoencoder.compile(optimizer='adamax', loss='mse')

print(autoencoder.summary())

history = autoencoder.fit(x=X_train, y=X_train, epochs=20,
                validation_data=[X_test, X_test], verbose=0, callbacks=[TQDMCallback()])

print ("batch_shape:",batch.shape)
print ("feature_vectors_shape:",feature_vectors.shape)
print ("size of individual feature vector:",feature_vectors.shape[1])


# Vizualizing loss
plt.plot(history.history['loss'])
plt.plot(history.history['val_loss'])
plt.title('model loss')
plt.ylabel('loss')
plt.xlabel('epoch')
plt.legend(['train', 'test'], loc='upper left')
plt.show()

clustering_utils = load_source('clustering_utils', '/Users/eyamga/Documents/Médecine/Recherche/CODA19/git/CODA19-Phenotyper/py_eyamga/rx_clusterer/src/clustering_utils.py')

# Vizualizing results
for i in range(5):
    img = X_test[0]
    clustering_utils.visualize(img,encoder,decoder)


code = encoder.predict(img[None])[0]
clustering_utils.show_image(img)
