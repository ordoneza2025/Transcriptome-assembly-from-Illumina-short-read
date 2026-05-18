#!/bin/bash

#SBATCH --job-name=stringtie
#SBATCH --mail-type=ALL
#SBATCH --mail-user=anor9792@colorado.edu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24gb
#SBATCH --time=20:00:00
#SBATCH --partition=short
#SBATCH --output=/scratch/Users/anor9792/eofiles/%x.%j.out
#SBATCH --error=/scratch/Users/anor9792/eofiles/%x.%j.err

echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started `date`
echo Using $SLURM_NTASKS processors and $SLURM_NNODES nodes

inFile=/scratch/Users/anor9792/bat_decoys/artibeus.j/2026_thesis/short_Read/STAR/pass2/all_samples_merged.sorted.bam
outDir=/scratch/Users/anor9792/bat_decoys/artibeus.j/2026_thesis/short_Read/stringtie
refFile=/scratch/Users/anor9792/bat_decoys/artibeus.j/Genomes/ucsc/GCF_021234435.1_CSHL_Jam_final.ncbiRefSeq.gtf

##queries=($(ls ${inFile}/*.bam | xargs -n 1 basename))

echo "Stringtie version: "$(stringtie --version)

module load stringtie


pwd; hostname; date


stringtie ${inFile} -p 8 \
-A ${outDir}/AJ_all_sr_conservative.gene_abund.tab \
--rf \
-G ${refFile} \
-f 0.05 -c 1.5 \
-o ${outDir}/AJ_all_sr_conservative.gtf

echo $(date +"[%b %d %H:%M:%S] Done")

## -f 0.25 (PSI is 25% for calling an isoform)
## -G annotation file
## -j is coverage of splice site, default is 1. 
## -c 1.5 \
## -f 0.05 \

