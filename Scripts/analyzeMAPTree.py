from ete3 import Tree
import os
import sys
from subprocess import call
from math import sqrt, pow
import numpy as np
import scipy
from sklearn.metrics import mean_squared_error

trueTreeFile=sys.argv[1]
inferredTreeFile = sys.argv[2]
verbose = sys.argv[3]

verbose_bool = False
if "y" in verbose:
    verbose_bool = True

###################################################################
########################## WARNING ################################
# the output line expects that the input inferred tree is named according to some rules, e.g. OutputDating/Cal_10_n_y_Cons_0_BD_WNr_BL.tree
###################################################################

# Load useful functions
exec (open("/home/boussau/Data/TransferRelated/datingWithTransfers/ReplicatedAnalysis_112019/Scripts/functionsToCompareChronograms.py").read ())

#import functionsToCompareChronograms as fn
# "/home/boussau/Programming/Notebooks/code/functionsToCompareChronograms.py"

# Read true tree
try:
    t = readTreeFromFile(trueTreeFile)
except :
    print("Format error, trying to read the input tree as a nexus: ")
    t = readMAPChronogramFromRBOutput(trueTreeFile)

# Need to number the nodes of the tree if they are not numbered already; otherwise we rename.
t = numberNodes( t )

# Read reconstructed tree
mapTWithId, idToHPD = readMAPChronogramFromRBOutputAndExtract95Hpd(inferredTreeFile)


# Make sure leaves in tMap contain 95%HPD information
#t = homogenizeNodeAnnotations( t )

# Number nodes in tMap so that they match node numbers in t
nodeId2LeafListRef, leafList2NodeIdRef = getNameToLeavesLink( t )
mapTWithId, mapIdToHPD = renumberNodesAndUpdate95HPDAccordingly( mapTWithId, leafList2NodeIdRef, idToHPD )

################################
# Build 2 vectors of node heights, in the same order so we can plot and compute correlations
heightsTrueDict = getInternalNodeHeights(t)
heightsMapDict = getInternalNodeHeights(mapTWithId)
heightsTrue = list()
heightsMap = list()
HPDMap = list()

for k,v in heightsTrueDict.items():
    if k != 1.0:
        heightsTrue.append(v)
        heightsMap.append(heightsMapDict[k])
        HPDMap.append(mapIdToHPD[int(k)])

# Compute correlation

#print(heightsTrue)
#print(heightsMap)

cor = scipy.stats.pearsonr(heightsTrue, heightsMap)
# rmsd = sqrt(mean_squared_error(y_true=heightsTrue, y_pred=heightsMap,
#                                multioutput='raw_values', squared=False))
rmsd_vec = list()
rmsd_norm_vec = list()
rmsd = 0.0
rmsd_norm = 0.0
for i in range(len(heightsTrue)):
    rmsd_vec.append(sqrt(pow(heightsTrue[i]-heightsMap[i], 2)))
    rmsd_norm_vec.append(rmsd_vec[i]/heightsTrue[i])
    rmsd += rmsd_vec[i]
    rmsd_norm += rmsd_norm_vec[i]

rmsd = rmsd / len(heightsTrue)
rmsd_norm = rmsd_norm / len(heightsTrue)

################################
# Same thing, but with branch lengths, not node ages

blsTrueDict = getBranchLengths(t)
blsMapDict = getBranchLengths(mapTWithId)
blsTrue = list()
blsMap = list()

for k,v in blsTrueDict.items():
    if k != 1.0:
        blsTrue.append(v)
        blsMap.append(blsMapDict[k])

# Compute correlation

cor_bls = scipy.stats.pearsonr(blsTrue, blsMap)
rmsd_bls = sqrt(mean_squared_error(blsTrue, blsMap))


# Compute over all nodes how many times the 95% HPD contains the true node age
# And also compute quantile HPD sizes
tot = 0.0
HPDMapLen = len(HPDMap)
HPDSizes = list()
if verbose_bool:
    print("true\tlow\thigh")
for i in range(HPDMapLen):
    if verbose_bool:
        print(str(heightsTrue[i]) + "\t" + str(HPDMap[i][0]) + "\t" + str(HPDMap[i][1]) )
    if (heightsTrue[i] >= HPDMap[i][0] and heightsTrue[i] <= HPDMap[i][1]):
        tot = tot + 1.0
        HPDSizes.append(HPDMap[i][1] - HPDMap[i][0])

numberOfQuantiles = 5
if len(HPDSizes) > 0:
    percents = np.percentile(HPDSizes, np.arange(0, 100, 100/numberOfQuantiles))
else:
    percents = [np.NaN]*numberOfQuantiles


# the output line expects that the input inferred tree is named according to some rules, e.g. OutputDating/Cal_10_n_y_Cons_0_BD_WNr_BL.tree

nameSplit =""
numTree = ""
numCalib = ""
numCons = ""

nameSplit = inferredTreeFile.split("_")
if len(nameSplit) > 8:
    numTree = nameSplit[6] + "_" + nameSplit[7] + "_" + nameSplit[8].replace(".tree", "")
    numCalib = nameSplit[1]
    balanced = nameSplit[2]
    old_biased = nameSplit[3]
    numCons = nameSplit[5]
else :
    numTree = "NA"
    numCalib = "NA"
    balanced = "NA"
    old_biased = "NA"
    numCons = "NA"

#print("Relaxed clock: Out of " + str(HPDMapLen) +" nodes, "+str(tot) +" were in the 95% HPD, i.e. " + str(100*tot/HPDMapLen) + "%.\n")

if verbose_bool:
    print("TreeId\tnumCalib\tnumCons\tbalanced\told_biased\tcorrelation\trmsd\trmsd_norm\tcor_bls\trmsd_bls\tnum_nodes\tnumInHPD\tfracInHPD\tpercent0\tpercent25\tpercent50\tpercents75\tpercent100" )
print(numTree+"\t"+numCalib +"\t"+ numCons +"\t"+ balanced +"\t"+ old_biased +"\t"+ str(cor[0]) +"\t"+ str(rmsd) +"\t"+ str(rmsd_norm) +"\t" + str(cor_bls[0]) +"\t"+ str(rmsd_bls) +"\t"+ str(HPDMapLen) +"\t"+ str(tot) + "\t" + str(100*tot/HPDMapLen) + "\t"+ str(percents[0]) +"\t"+ str(percents[1]) +"\t"+ str(percents[2]) +"\t"+ str(percents[3]) +"\t"+ str(percents[4]) )
