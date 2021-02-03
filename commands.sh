### We get the trees with empirical dates but shuffled topologies from Dominik in the folder ShuffledTrees
# We rename the trees to avoid confusing these artificial trees with empirical ones
python Scripts/renameTips.py ShuffledTrees/shuffle.tree

# then I arbitrarily choose tree 2:
cd ShuffledTrees
head -2 shuffle_renamed.dnd | tail -1 > proposedTree.dnd
figtree proposedTree.dnd& # we got proposedTree.dnd.pdf
cd ..

# Now we're going to use this tree for the simulation work.
mkdir SimulatedTrees
cp ShuffledTrees/proposedTree.dnd SimulatedTrees/

# Rescaling the trees
for i in SimulatedTrees/proposedTree.dnd ; do python Scripts/rescaleTree.py $i 0.01 ; done > statsOnRescaledTrees.txt

# Introducing deviations from the clock
for i in SimulatedTrees/proposedTree_rescaled.dnd ; do python Scripts/alterBranchLengths.py $i 0.03 0.1 1.0 0.2 0.01 ${i/.dnd}_altered.dnd n ; done

# We can compare the distributions of branch lengths before and after alterations by looking into statsOnRescaledTrees.txt and statsOnRescaledAlteredTrees.txt (at the end).

# unrooting the tree, because revbayes does not like rooted branch length trees
for i in SimulatedTrees/proposedTree_rescaled_altered.dnd ; do python Scripts/unrootTree.py $i ; done

# Simulate alignments
mkdir Alignments
cd SimulatedTrees
for i in proposedTree_rescaled_altered_unrooted.dnd ; do echo "tree_file=\"$i\"; source (\"../Scripts/simu_HKY_No_Gamma.Rev\");" | rb ; done
mv *.fasta ../Alignments
cd ..


# Reconstruction of branch length tree distributions using RevBayes
echo "aln_file=\"Alignments/proposedTree_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/proposedTree_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb

# Computation of mean and var
cd Alignments/
echo "tree_file=\"proposedTree_rescaled_altered_unrooted.dnd.fasta.trees\"; burnin=500 ; thinning=5 ; source(\"../Scripts/DatingRevScripts/computeMeanAndVarBl.Rev\");" | rb
# this produced proposedTree_rescaled_altered_unrooted.dnd.fasta.trees_meanBL.nex and proposedTree_rescaled_altered_unrooted.dnd.fasta.trees_varBL.nex
cd ..



#########################################################
# Now we are going to sample calibrations and constraints
#########################################################

################# First, calibrations.
# We get 10 calibrations as in Betts et al. 2018.

# Getting constraints by hand.
# The result is in several files:
# constraints_10.Rev  constraints_15.Rev  constraints_1.Rev  constraints_5.Rev  constraints_full.txt  constraints_informative.Rev  constraints_uninformative.Rev constraints_0.Rev, etc...


#########################################################
# Dating with branch lengths, constraints and calibrations
#########################################################
# We run computations on mellifera.elte.hu
mkdir OutputDating

# dating the tree with balanced calibrations and varying numbers of constraints, on mellifera.elte:
chmod +x launchAllBalancedJobs_Elte.sh
nohup ./launchAllBalancedJobs_Elte.sh &
#
# # dating the tree with unbalanced calibrations and varying numbers of constraints:
nohup ./launchAllUnbalancedJobs_Elte.sh &
#
# # dating the tree with 5 informative or uninformative constraints
# launchDatingInformativeUninformative.sh

# Gathering the trees :
scp -i /home/boussau/.ssh/apismellifera_rsa mellifera.elte.hu:~/DatingWithConsAndCal/OutputDating/*.trees OutputDating/
# removing mixed-up lines:
cd OutputDating
#for i in *.trees ; do awk '{ if (NF==5) {print} }' $i | awk '{ if (NR<2) { print } else if ($0 ~/;$/) { print } }' > ${i/.trees}noMix.trees; echo $i ; wc -l ${i/.trees}noMix.trees; done
for i in *.trees ; do python ../Scripts/removeIncorrectLinesFromTrace.py $i ${i/.trees}noMix.trees ; done > outputCleaningTraceFiles

# control of what happened: No line has been removed.


# Then we can make map trees for each file.
for i in *noMix.trees ; do echo "fname_stem=\"${i/.trees}\" ; source(\"../Scripts/DatingRevScripts/makeMAPTree.Rev\") ;" | rb ; done
cd ..


## Analysing the dated trees
./launchAnalysis.sh > resultAllTrees.txt

grep -A1 "fracInHPD" resultAllTrees.txt | grep -v "fracInHPD" | grep -v "-" > resultAllTreesExcerpt.txt
# then analysis in Analysis of constraints vs calibrations.ipynb



#########################################################
## Same thing for the comparison of informative and uninformative constraints
#########################################################
# Gathering the trees :
mkdir OutputDatingInfoUninfo
scp -i /home/boussau/.ssh/apismellifera_rsa mellifera.elte.hu:~/DatingWithConsAndCal/OutputDatingInfoUninfo/*.trees OutputDatingInfoUninfo/
# removing mixed-up lines:
cd OutputDatingInfoUninfo

# Then we can make map trees for each file.
for i in *.trees ; do echo "fname_stem=\"${i/.trees}\" ; source(\"../Scripts/DatingRevScripts/makeMAPTree.Rev\") ;" | rb ; done
cd ..

## Analysing the dated trees
./launchAnalysisProximalDistal.sh > resultAllTreesProxiDist.txt

grep -A1 "fracInHPD" resultAllTreesProxiDist.txt | grep -v "fracInHPD" | grep -v "-" > resultAllTreesProxiDistExcerpt.txt

# Adding the data with 0 constraint from the previous experiments
awk '{ if ($3==0) {print} }' resultAllTreesExcerpt.txt > result0Constraints
cat result0Constraints resultAllTreesProxiDistExcerpt.txt > resultAllTreesProxiDistExcerptWith0Constraint.txt

# then analysis in Analysis of constraints vs calibrations.ipynb



#########################################################
## Validation test: when the model for simulating rates
## matches the reconstruction model
#########################################################
# We use revbayes to simulate rates along the tree, then
# sequences.

mkdir Alignment_WNr
echo "tree_file=\"SimulatedTrees/proposedTree.dnd\"; output_file=\"Alignment_WNr/alignment.fasta\"; source(\"Scripts/simulateWNr.Rev\");" | rb

# We have the sequences in Alignment_WNr/alignment.fasta

# Reconstruction of branch length tree distributions using RevBayes
echo "aln_file=\"Alignment_WNr/alignment.fasta\"; tree_file=\"SimulatedTrees/proposedTree_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb

# Computation of mean and var
cd Alignment_WNr/
echo "tree_file=\"alignment.fasta.trees\"; burnin=500 ; thinning=10 ; source(\"../Scripts/DatingRevScripts/computeMeanAndVarBl.Rev\");" | rb
# this produced alignment.fasta.trees_meanBL.nex and alignment.fasta.trees_varBL.nex
cd ..

mkdir OutputDatingWNr

# dating the tree with balanced calibrations and varying numbers of constraints:
launchDatingBalancedWNr.sh

# dating the tree with unbalanced calibrations and varying numbers of constraints:
launchDatingUnbalancedWNr.sh

#########################################################
## Analysing the dated trees
#########################################################
./launchAnalysisWNr.sh > resultAllTreesWNr.txt

./launchAnalysisInfoUninfoWNr.sh > resultAllTreesInfoUninfoWNr.txt

# THe 95% HPD still do not contain the true dates 95% of the time...
# Fixing the rates:
echo "tree_file=\"SimulatedTrees/proposedTree.dnd\"; calibration_file=\"Calibrations_10_y_y/proposedTree_calibrations.Rev\" ; constraint_file=\"Constraints/constraints_0.Rev\" ; clade_file=\"Calibrations_10_y_y/proposedTree_clades.Rev\" ; mean_tree_file=\"Alignment_WNr/alignment.fasta.trees_meanBL.nex\" ; var_tree_file=\"Alignment_WNr/alignment.fasta.trees_varBL.nex\"; handle=\"OutputDatingWNr/Cal_10_y_y_Cons_0_Fixed_rate\"; rate_model=\"WNr_FixedMeanAndVar\"; source(\"Scripts/DatingRevScripts/mainScript.Rev\");" | rb

# The results are quite bad, it seems like I can't correctly fix the mean and variance of the rates.

#########################################################
#########################################################
#### Another analysis, building the branch length trees with HKY as in the simulation.
#########################################################


# Reconstruction of branch length tree distributions using RevBayes
echo "aln_file=\"Alignment_WNr/alignment.fasta\"; tree_file=\"SimulatedTrees/proposedTree_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_HKY.Rev\");" | rb

# We compare the tree reconstructed with HKY to the tree reconstructed using JC
# not working
# python Scripts/analyzeMAPTree.py Alignment_WNr/alignment.fasta.tree  Alignment_WNr/alignment.fastaHKY.tree

cd Alignment_WNr/
echo "tree_file=\"alignment.fastaHKY.trees\"; burnin=500 ; thinning=10 ; source(\"../Scripts/DatingRevScripts/computeMeanAndVarBl.Rev\");" | rb
# this produced alignment.fastaHKY.trees_meanBL.nex and alignment.fastaHKY.trees_varBL.nex
cd ..

# Then obtaining a timetree distribution
echo "tree_file=\"SimulatedTrees/proposedTree.dnd\"; calibration_file=\"Calibrations_10_y_y/proposedTree_calibrations.Rev\" ; constraint_file=\"Constraints/constraints_0.Rev\" ; clade_file=\"Calibrations_10_y_y/proposedTree_clades.Rev\" ; mean_tree_file=\"Alignment_WNr/alignment.fastaHKY.trees_meanBL.nex\" ; var_tree_file=\"Alignment_WNr/alignment.fastaHKY.trees_varBL.nex\"; handle=\"OutputDatingWNr/Cal_10_y_y_Cons_0_HKY\"; rate_model=\"WNr\"; source(\"Scripts/DatingRevScripts/mainScript.Rev\");" | rb

# Analysis
python Scripts/analyzeMAPTree.py SimulatedTrees/proposedTree.dnd OutputDatingWNr/Cal_10_y_y_Cons_0_HKY_cons_BD_WNr_BL.tree y


# Then obtaining a timetree distribution under UGAMr
echo "tree_file=\"SimulatedTrees/proposedTree.dnd\"; calibration_file=\"Calibrations_10_y_y/proposedTree_calibrations.Rev\" ; constraint_file=\"Constraints/constraints_0.Rev\" ; clade_file=\"Calibrations_10_y_y/proposedTree_clades.Rev\" ; mean_tree_file=\"Alignment_WNr/alignment.fastaHKY.trees_meanBL.nex\" ; var_tree_file=\"Alignment_WNr/alignment.fastaHKY.trees_varBL.nex\"; handle=\"OutputDatingWNr/Cal_10_y_y_Cons_0_HKY\"; rate_model=\"UGAMr\"; source(\"Scripts/DatingRevScripts/mainScript.Rev\");" | rb

# Analysis
python Scripts/analyzeMAPTree.py SimulatedTrees/proposedTree.dnd OutputDatingWNr/Cal_10_y_y_Cons_0_HKY_cons_BD_UGAMr_BL.tree y

# Did not mix well ESS global_rate_mean=15.

#########################################
# Then obtaining a timetree distribution under UGAMr
echo "tree_file=\"SimulatedTrees/proposedTree.dnd\"; calibration_file=\"Calibrations_10_y_y/proposedTree_calibrations.Rev\" ; constraint_file=\"Constraints/constraints_0.Rev\" ; clade_file=\"Calibrations_10_y_y/proposedTree_clades.Rev\" ; mean_tree_file=\"Alignment_WNr/alignment.fastaHKY.trees_meanBL.nex\" ; var_tree_file=\"Alignment_WNr/alignment.fastaHKY.trees_varBL.nex\"; handle=\"OutputDatingWNr/Cal_10_y_y_Cons_0_HKY\"; rate_model=\"UGAMr\"; mc3=\"true\"; source(\"Scripts/DatingRevScripts/mainScript.Rev\");" | rb





#########################################################
## New analysis: new BD tree, then inference under the same model that was used for simulation (JC).
## Also, slower rate of evolution.
#########################################################
mkdir SimuAndInfer
cd SimuAndInfer
echo "tree_file=\"../SimulatedTrees/proposedTree.dnd\"; source(\"../Scripts/DatingRevScripts/simulateThenInfer.Rev\");" | rb

# Analysis
python ../Scripts/analyzeMAPTree.py simulatedTree_BD.nex simuAndinfer_BD_WNr_BL.tree y
cd ..



#########################################################
## New analysis: new BD tree, then inference under the same model that was used for simulation (JC).
# With UGAMr instead of WNr.
## Also, slower rate of evolution.
#########################################################
mkdir SimuAndInferUGAM
cd SimuAndInferUGAM
echo "tree_file=\"../SimulatedTrees/proposedTree.dnd\"; source(\"../Scripts/DatingRevScripts/simulateThenInferUGAM.Rev\");" | rb

# When we relaunch the analysis:
echo "tree_file=\"../SimulatedTrees/proposedTree.dnd\"; source(\"../Scripts/DatingRevScripts/endSimulateThenInferUGAM.Rev\");" | rb


# Analysis
python ../Scripts/analyzeMAPTree.py simulatedTree_BD.nex simuAndinfer_BD_BD_UGAMr_BL.tree y
cd ..

# Works!!!!!


#########################################################
## Same thing, but we estimate the UGAM parameters
#########################################################

cd SimuAndInferUGAM
echo "tree_file=\"../SimulatedTrees/proposedTree.dnd\"; source(\"../Scripts/DatingRevScripts/endSimulateThenInferUGAM_InferUGAMParameters.Rev\");" | rb


# Analysis
python ../Scripts/analyzeMAPTree.py simulatedTree_BD.nex simuAndinferInferUGAMParameters_BD_BD_UGAMr_BL.tree y
cd ..


#########################################################
## Same thing, but we use UGAM, not UGAMr.
#########################################################

cd SimuAndInferUGAM
echo "tree_file=\"../SimulatedTrees/proposedTree.dnd\"; source(\"../Scripts/DatingRevScripts/endSimulateThenInferUGAMNotUGAMr_InferUGAMParameters.Rev\");" | rb


# Analysis
python ../Scripts/analyzeMAPTree.py simulatedTree_BD.nex simuAndinferInferUGAMParameters_BD_BD_UGAM_BL.tree y

# UGAMr seems to work better, although mixing is slow for the mean rate parameter of UGAMr.

#########################################################
## UGAMr, but we try Bactrian scale moves on all the parameters of UGAMr.
#########################################################

cd SimuAndInferUGAM
echo "tree_file=\"../SimulatedTrees/proposedTree.dnd\"; source(\"../Scripts/DatingRevScripts/endSimulateThenInferUGAM_InferUGAMParametersBactrian.Rev\");" | rb


# Analysis
python ../Scripts/analyzeMAPTree.py simulatedTree_BD.nex simuAndinferInferUGAMrParametersBactrian_BD_BD_UGAMr_BL.tree y



# Convergence sucks for global_mean_rate, even though our prior is good (centered on the true value).

#########################################################
## UGAMr, Bactrian scale moves on all the parameters of UGAMr, and MC3.
#########################################################




echo "tree_file=\"../SimulatedTrees/proposedTree.dnd\"; source(\"../Scripts/DatingRevScripts/endSimulateThenInferUGAM_InferUGAMParametersBactrianMC3.Rev\");" | rb

# Analysis
python ../Scripts/analyzeMAPTree.py simulatedTree_BD.nex simuAndinferInferUGAMrParametersBactrianMC3_BD_BD_UGAMr_BL.tree y

# MC3 works!


#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
### Previous plans:
#########################################################
#########################################################
#########################################################
#########################################################




pick up one larger tree with ~100 leaves. Then consider situations where:
calibrations are placed in an unbalanced way
calibrations are placed in a balanced way
(edited)
Then we place constraints. Constraints can be informative or not. They are informative if they provide node order information between nodes that have similar ages and are not in an ancestor-descendant relationship. We have not really decided yet if we want to pay attention to the informativeness of a constraint.
In the next few days, Gergely is going to get the tree with 102 sp from Betts et al. he is going to extract speciation times from that tree, and simulate a new tree with a random topology but keeping those node ages. That's a good way to simulate many trees ; we will choose one of them for our experiments.
I will write a script to build calibrations from a given tree. This script will be able to produce sets of k calibrations, either balanced or unbalanced.
Hopefully in a few days we can look at trees and sets of calibrations. Once we're happy with those, we move on to putting constraints in the simulations.

#### Test tree with 102 leaves
# Simulating the Birth-death tree
  Rscript Scripts/simulateTreeWith102Leaves.R
  mkdir SimulatedTrees
  mv *.dnd SimulatedTrees
  mkdir SimulatedTreesPDF
  mv *.pdf SimulatedTreesPDF

# our tree of interest is SimulatedTrees/extantTree.dnd

# Rescaling the trees
for i in SimulatedTrees/extantTree*.dnd ; do python Scripts/rescaleTree.py $i 0.3 ; done > statsOnRescaledTrees.txt

# Introducing deviations from the clock
for i in SimulatedTrees/extantTree*_rescaled.dnd ; do python Scripts/alterBranchLengths.py $i 0.03 0.1 1.0 0.2 0.01 ${i/.dnd}_altered.dnd n ; done

# unrooting the tree, because revbayes does not like rooted branch length trees
for i in SimulatedTrees/extantTree*_rescaled_altered.dnd ; do python Scripts/unrootTree.py $i ; done

# Get statistics on branch lengths of the altered and unrooted trees
for i in SimulatedTrees/extantTree*_rescaled_altered_unrooted.dnd ; do python Scripts/getBranchLengthStats.py $i ; done > statsOnRescaledAlteredTrees.txt

# Simulate alignments
mkdir Alignments
cd SimulatedTrees
for i in extantTree*_rescaled_altered_unrooted.dnd ; do echo "tree_file=\"$i\"; source (\"../Scripts/simu_HKY.Rev\");" | rb ; done
mv *.fasta ../Alignments
cd ..

# Reconstruction of branch length tree distributions using RevBayes
echo "aln_file=\"Alignments/extantTree_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/extantTree_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb

#########################################################
# Now we are going to sample calibrations and constraints
#########################################################

# First, calibrations:
# 4 ways of sampling constraints:
- balanced (both sides of the root)
- unbalanced (one side of the root only)
- randomly (all nodes have the same probability to be picked)
- old-biased (older nodes are more likely to be picked; the weight is according to their order in the list of node ages)


# Getting old and young calibrations, on both sides:
python Scripts/extractCalibrations.py SimulatedTrees/extantTree.dnd 10 y both

# Getting old and young calibrations, on one side only:
python Scripts/extractCalibrations.py SimulatedTrees/extantTree.dnd 10 n both

# Second, constraints, by hand a priori:
# python Scripts/extractRelativeConstraints.py SimulatedTrees/extantTree.dnd



#########################################################
# Dating with branch lengths, constraints and calibrations
#########################################################

# Little test:

echo "tree_file=\"Alignments/10First.trees\"; source(\"Scripts/DatingRevScripts/computeMeanAndVarBl.Rev\");" | rb

# This gave us 10First.trees_meanBL.nex and 10First.trees_varBL.nex
# We select calibrations:
python Scripts/sampleCalibrations.py SimulatedTrees/extantTree_calibrations.Rev SimulatedTrees/extantTree_calibrations_5.Rev 5
# And we select constraints, by hands to produce file SimulatedTrees/extantTree_constraints_5.txt


#### Dating the tree:
echo "tree_file=\"SimulatedTrees/extantTree.dnd\"; calibration_file=\"SimulatedTrees/extantTree_calibrations_5.Rev\" ; constraint_file=\"SimulatedTrees/extantTree_constraints_5.txt\" ; clade_file=\"SimulatedTrees/extantTree_clades.Rev\" ; mean_tree_file=\"Alignments/10First.trees_meanBL.nex\" ; var_tree_file=\"Alignments/10First.trees_varBL.nex\" ; source(\"Scripts/DatingRevScripts/mainScript.Rev\");" | rb





#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
### VERY OLD Previous plans:
#########################################################
#########################################################
#########################################################
#########################################################


# Simulating the Birth-death trees
  Rscript Scripts/simulate10Trees.R
  mkdir SimulatedTrees
  mv *.dnd SimulatedTrees
  mkdir SimulatedTreesPDF
  mv *.pdf SimulatedTreesPDF

# Rescaling the trees
for i in SimulatedTrees/extantTree*.dnd ; do python Scripts/rescaleTree.py $i 0.3 ; done > statsOnRescaledTrees.txt

# Introducing deviations from the clock
for i in SimulatedTrees/extantTree*_rescaled.dnd ; do python Scripts/alterBranchLengths.py $i 0.03 0.2 1.0 0.4 0.01 ${i/.dnd}_altered.dnd n ; done

# unrooting the tree, because revbayes does not like rooted branch length trees
for i in SimulatedTrees/extantTree*_rescaled_altered.dnd ; do python Scripts/unrootTree.py $i ; done

# Get statistics on branch lengths of the altered and unrooted trees
for i in SimulatedTrees/extantTree*_rescaled_altered_unrooted.dnd ; do python Scripts/getBranchLengthStats.py $i ; done > statsOnRescaledAlteredTrees.txt

# Simulate alignments
mkdir Alignments
cd SimulatedTrees
for i in extantTree_*_rescaled_altered_unrooted.dnd ; do echo "tree_file=\"$i\"; source (\"../Scripts/simu_HKY.Rev\");" | rb ; done
mv *.fasta ../Alignments
#for i in extantTree_*_rescaled_altered_unrooted.dnd ; do bppseqgen input.tree.file=$i output.sequence.file=../Alignments/${i/_rescaled_altered.dnd}.fa number_of_sites=1000 "rate_distribution=Gamma(n=20, alpha=0.3)" 'model=HKY85([kappa=3, theta=0.6, theta1=0.55, theta2=0.35 ])' ; done
cd ..

# Reconstruction of branch length tree distributions using RevBayes
echo "aln_file=\"Alignments/extantTree_1_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/extantTree_1_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb
echo "aln_file=\"Alignments/extantTree_2_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/extantTree_2_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb
echo "aln_file=\"Alignments/extantTree_3_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/extantTree_3_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb
echo "aln_file=\"Alignments/extantTree_4_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/extantTree_4_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb
echo "aln_file=\"Alignments/extantTree_5_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/extantTree_5_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb
echo "aln_file=\"Alignments/extantTree_6_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/extantTree_6_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb
echo "aln_file=\"Alignments/extantTree_7_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/extantTree_7_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb
echo "aln_file=\"Alignments/extantTree_8_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/extantTree_8_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb
echo "aln_file=\"Alignments/extantTree_9_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/extantTree_9_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb
echo "aln_file=\"Alignments/extantTree_10_rescaled_altered_unrooted.dnd.fasta\"; tree_file=\"SimulatedTrees/extantTree_10_rescaled_altered_unrooted.dnd\"; source(\"Scripts/mcmc_JC.Rev\");" | rb


# We extract from these tree distributions mean branch lengths and variances, and build trees with such branch lengths

# Now we are going to sample calibrations and constraints
for i in SimulatedTrees/extantTree_[123456789].dnd SimulatedTrees/extantTree_10.dnd ; do python Scripts/extractRelativeConstraints.py $i ; done

# Cleaning and backing up in case.
mv BUPAlignments Alignments OLDCOMMANDS SimulatedTrees SimulatedTreesPDF ExperimentsTrees30Leaves
