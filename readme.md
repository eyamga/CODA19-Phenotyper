# CODA19 phenotyper project
 
## Files organization of the project


### Custom SQL scripts
- Files located in py_eyamga/sql
- SQL lite scripts extracting all meaningful categories from the 

### Python scripts
#### 1. Dataparser
* Queries all SQL file appropriately and exports them as CSV in local directory
#### 2. RXCUI class
* Maps drug names to MESH drug class categories
#### 3. ImageExtractor
* Queries the CODA19 database and preprocess the DICOM images before deep learning

### R script

In order :
#### 1. Dataparser
- Similar to the python script
- Runs sql scripts and exports appropriate csv files in the local /csv dir

#### 2. EDA
- Loads datawrangled csv files and transforms the data from narrow to wide 
- Exports a final csv file that is ready for analysis
- **Other features** : MICE imputation, exports EDA pdf files, 3 differents timestamps (at 24h, 48h and 72h)

#### 3. Feature engineering
- Runs PCA/MCA/FAMD  

#### 4. Cluster Analysis
- As described

#### 5. Markdown folder
- Runs entire project and modified script and outputs sharable html file
