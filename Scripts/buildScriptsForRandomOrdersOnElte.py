import os
import random
import sys

out = sys.argv[1]
num = int(sys.argv[2])  # Number of random orders


for i in range(num):
    # Folder for replicate i
    out_i = os.path.join(out, "Rep_"+str(i))
    for j in range(1, 15):
        # write down 14 scripts for the balanced case,
        # and 14 scripts for the unbalanced case.
        with open(os.path.join(out_i, "balanced_" + str(j) + ".sh"), 'w') as fout:
            l = r"""echo "tree_file=\"SimulatedTrees/proposedTree.dnd\"; calibration_file=\"Calibrations_10_y_y/proposedTree_calibrations.Rev\" ; constraint_file=\"TOREPLACE\" ; clade_file=\"Calibrations_10_y_y/proposedTree_clades.Rev\" ; mean_tree_file=\"Alignments/proposedTree_rescaled_altered_unrooted.dnd.fasta.trees_meanBL.nex\" ; var_tree_file=\"Alignments/proposedTree_rescaled_altered_unrooted.dnd.fasta.trees_varBL.nex\"; handle=\"OutputDatingRandomOrder\"; rate_model=\"UGAMr\"; mc3=\"true\"; source(\"Scripts/DatingRevScripts/mainScript.Rev\");" | /scratch/local/bin/rb-mpi_icc"""
            l = l.replace("TOREPLACE", os.path.join(
                out_i, "constraints_"+str(j)+".Rev"))
            l = l.replace("OutputDatingRandomOrder",
                          os.path.join("OutputDatingRandomOrder", out_i, "Cal_10_y_y_Cons_"+str(j)))
            fout.write(l+"\n")
        with open(os.path.join(out_i, "unbalanced_" + str(j) + ".sh"), 'w') as fout:
            l = r"""echo "tree_file =\"SimulatedTrees/proposedTree.dnd\"; calibration_file=\"Calibrations_10_n_y/proposedTree_calibrations.Rev\" ; constraint_file=\"TOREPLACE\" ; clade_file=\"Calibrations_10_n_y/proposedTree_clades.Rev\" ; mean_tree_file=\"Alignments/proposedTree_rescaled_altered_unrooted.dnd.fasta.trees_meanBL.nex\" ; var_tree_file=\"Alignments/proposedTree_rescaled_altered_unrooted.dnd.fasta.trees_varBL.nex\"; handle=\"OutputDatingRandomOrder\"; rate_model=\"UGAMr\"; mc3=\"true\"; source(\"Scripts/DatingRevScripts/mainScript.Rev\");" | /scratch/local/bin/rb-mpi_icc"""
            l = l.replace("TOREPLACE", os.path.join(
                out_i, "constraints_"+str(j)+".Rev"))
            l = l.replace("OutputDatingRandomOrder",
                          os.path.join("OutputDatingRandomOrder", out_i, "Cal_10_n_y_Cons_"+str(j)))
            fout.write(l+"\n")
