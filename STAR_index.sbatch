#!/bin/bash
#SBATCH --job-name=STAR_index
#SBATCH --mail-type=ALL
#SBATCH --mail-user=anor9792@colorado.edu
#SBATCH --nodes=2
#SBATCH --ntasks=16
#SBATCH --mem=64gb
#SBATCH --time=1:00:00
#SBATCH --partition=short
#SBATCH --output=/scratch/Users/anor9792/eofiles/%x.%j.out
#SBATCH --error=/scratch/Users/anor9792/eofiles/%x.%j.err

echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started `date`
echo Using $SLURM_NTASKS processors and $SLURM_NNODES nodes

echo $(date +"[%b %d %H:%M:%S] Initialize the shell to use conda...")
eval "$(conda shell.bash hook)"


conda activate STAR


outDir=/scratch/Users/anor9792/bat_decoys/artibeus.j/2026_thesis/short_Read/STAR/index
inFiles=/scratch/Users/anor9792/bat_decoys/artibeus.j/Genomes/ucsc/GCF_021234435.1.fa
GTF=/scratch/Users/anor9792/bat_decoys/artibeus.j/Genomes/ucsc/GCF_021234435.1_CSHL_Jam_final.ncbiRefSeq.gtf
SJDB_OVERHANG=149


STAR --runMode genomeGenerate --genomeDir ${outDir} --genomeFastaFiles ${inFiles} --sjdbGTFfile ${GTF}  --sjdbOverhang ${SJDB_OVERHANG} --runThreadN 16 --limitGenomeGenerateRAM 77706498773
