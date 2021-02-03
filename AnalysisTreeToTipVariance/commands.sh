
wget ftp://pbil.univ-lyon1.fr/pub/hogenom/release_07/trees/newick_template_trees.rooted.newick

python ../Scripts/computeUltrametricityIndices.py newick_template_trees.rooted.newick newick_template_trees.rooted.stats
