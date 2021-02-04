#%% Library load





#%% Loading the dataset (n = 28)
with h5py.File(EXPORTPATH + '/data.h5', 'r') as hf:
    plt.imshow(hf['X28'], cmap='gray')
    plt.show()
    print(hf['y28'].value)

