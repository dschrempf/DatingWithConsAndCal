import pandas as pd
import sys
from ete3 import Tree, TreeStyle, NodeStyle


# Load useful functions
exec (open("/home/boussau/Data/TransferRelated/datingWithTransfers/ReplicatedAnalysis_112019/Scripts/functionsToCompareChronograms.py").read ())



file=sys.argv[1]
out=sys.argv[2]

numLine = 0
numRemoved = 0
with open (file, "r") as f:
    with open (out, 'w') as fo:
        for l in f:
            if numLine == 0:
                fo.write(l)
            else:
                li = l.split()
                if len(li)==5:
                    try :
                        if not (li[4].startswith("(((((((T_15[&index=102]:") and li[4].endswith(")[&index=203]:0.000000;")):
                            raise(Exception('not properly formatted tree'))
                        elif "&&" in li[4]:
                            raise(Exception("tree contains '&&'"))
                        t = readAnnotatedChronogramWithoutAnnotations ( li[4] )
                        fo.write(l)
                    except Exception as err:
                        print("\n\t\tImproper tree at line "+str(numLine) + " :\n" + l +"{0}".format(err))
                        numRemoved += 1
                else:
                    print("\n\t\tNot 5 words at line: "+str(numLine) + " :\n" + l)
                    numRemoved += 1
            numLine += 1

print("File " + file + " : total number of lines that have been removed: "+ str(numRemoved))
