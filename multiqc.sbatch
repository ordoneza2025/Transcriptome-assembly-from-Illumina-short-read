#!/bin/bash
#SBATCH --job-name=multiqc
#SBATCH --mail-type=ALL
#SBATCH --mail-user=anor9792@colorado.edu
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=4gb
#SBATCH --time=00:30:00
#SBATCH --partition=short
#SBATCH --output=/scratch/Users/anor9792/eofiles/%x.%j.out
#SBATCH --error=/scratch/Users/anor9792/eofiles/%x.%j.err

echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started `date`
echo Using $SLURM_NTASKS processors and $SLURM_NNODES nodes

module load singularity

inDir=/QCfiles
outDir=/mqc
multiqc=/scratch/Shares/public/singularity/multiqc-1.7.img

pwd; hostname; date

echo "Singularity version: "$(singularity --version)
echo "MultiQC version: "$(singularity exec --bind /scratch ${multiqc} multiqc --version)
echo $(date +"[%b %d %H:%M:%S] Running MultiQC...")

singularity exec --bind /scratch ${multiqc} \
multiqc ${inDir}/*.zip \
--outdir ${outDir}

echo $(date +"[%b %d %H:%M:%S] Done") 
