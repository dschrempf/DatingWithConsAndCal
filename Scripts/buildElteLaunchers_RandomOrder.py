import glob
import os
import random
import sys

folder_with_launchers = sys.argv[1]
folder_with_scripts = sys.argv[2]
base_launcher = sys.argv[3]
num = int(sys.argv[4])  # Number of random orders
output_folder = "OutputDatingRandomOrder"


lines = str()
with open(base_launcher, "r") as fin:
    for l in fin:
        lines = lines + l

for i in range(num):
    # Folder for replicate i
    out_i = os.path.join(folder_with_scripts, "Rep_"+str(i))
    all_scripts_balanced = str()
    all_scripts_unbalanced = str()
    num_scripts = 0
    for j in range(1, 15):
        # Check if the map tree is already there, in which case we do not run the computation
        print(os.path.join(output_folder, "Rep_"+str(i), "Cal_10_y_y_Cons_"+str(j)+"*.tree"))
        if len(glob.glob(os.path.join(output_folder, "Rep_"+str(i), "Cal_10_y_y_Cons_"+str(j)+"*.tree"))) == 0:
            # write down 1 string for the balanced case,
            # and 1 string for the unbalanced case.
            all_scripts_balanced = all_scripts_balanced + " \"bash " + \
                os.path.join(out_i, "balanced_" + str(j) + ".sh\"")
            num_scripts += 1
        if len(glob.glob(os.path.join(output_folder, "Rep_"+str(i), "Cal_10_n_y_Cons_"+str(j)+"*.tree"))) == 0:
            all_scripts_unbalanced = all_scripts_unbalanced + " \"bash " + \
                os.path.join(out_i, "unbalanced_" + str(j) + ".sh\"")
            num_scripts += 1

    print(num_scripts)
    with open(os.path.join(folder_with_launchers, "launcher_Rep_" + str(i) + ".sh"), "w") as fout:
        fout.write(lines.replace("\"TOREPLACEWITH28JOBS\"", all_scripts_balanced +
                                 " " + all_scripts_unbalanced).replace("balancedRuns", "Rep_"+str(i)).replace("\"FOURSHERE\"", "\"4\" "*num_scripts))
