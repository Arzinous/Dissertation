# Shared Input

`IL-2_pdb_1M47.fasta` — the single-chain sequence extracted from the apo
IL-2 crystal structure (PDB 1M47, chain A). This is the sole sequence
input to all three ensemble-generation methods (MSA Subsampling,
AFsample2, BioEmu), so that any differences between their output
ensembles reflect the generative method itself rather than a difference
in input sequence.

| Property | Value |
|---|---|
| Source structure | PDB 1M47, chain A |
| Length | 133 residues |
| Sequence | `APTSSSTKKTQLQLEHLLLDLQMILNGINNYKNPKLTRMLTFKFYMPKKATELKHLQCLEEELKPLEEVLNLAQSKNFHLRPRDLISNINVIVLELKGSETTFMCEYADETATIVEFLNRWITFCQSIISTLT` |

**Note on the MSA:** MSA Subsampling additionally reused a single
server-generated `.a3m` alignment (captured once, then reused across the
whole depth sweep — see `../msa_subsampling/README.md`) rather than
re-querying per run. Whether that same fixed `.a3m` was also supplied to
AFsample2 and BioEmu's embedding step should be confirmed and stated
explicitly in each method's README, since it materially affects whether
cross-method comparisons are confounded by different alignments.
