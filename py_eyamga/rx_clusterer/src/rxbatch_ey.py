import h5py
import numpy as np
import matplotlib.pyplot as plt

IMAGEPATH = '/Users/eyamga/Documents/Médecine/Recherche/CODA19/git/images'
hdf5_path = IMAGEPATH + '/data.h5'

def minibatch_train(size, seed):
    np.random.seed(seed)
    dataset = h5py.File(hdf5_path, "r")
    datasize = int(len(dataset.keys()) / 2)
    train_imgs = []
    train_ids = []
    train_batch_ids = []
    train_batch_imgs = []
    np.random.seed(seed)

    # Loading all images
    for i in range(1,datasize+1):
        img_index = "X" + str(i)
        pid_index = "y" + str(i)
        img = dataset[img_index][()]
        pid = dataset[pid_index][()]

        # converting hf5 into np array
        imgarray = np.array(img) #alternative is img.value but deprecated
        # converting pid into np array
        pidarray = np.array(pid)

        # plt.imshow(dataset['X2'])
        # plt.show()

        # adding all images to a list
        train_imgs.append(imgarray)
        train_ids.append(pidarray)

    # Creating a batch
    # shuffle indexes,int numbers range from 0 to 20000
    permutation = list(np.random.permutation(datasize))
    # get the "train_batch_size" indexes
    train_batch_index = permutation[0:size]

    for i in range(size):
        sample_img = train_imgs[train_batch_index[i]]
        sample_id = train_ids[train_batch_index[i]]
        img = img.astype('float32') / 255.0 - 0.5
        train_batch_imgs.append(sample_img)
        train_batch_ids.append(sample_id)

    # Converting the list of arrays into an array
    train_batch_imgs = np.array(train_batch_imgs)
    train_batch_ids = np.array(train_batch_ids)

    return (train_batch_imgs, train_batch_ids)


# batch, label = minibatch_train(4,5)
# Must add a way to convert shape to add grayscale channel
