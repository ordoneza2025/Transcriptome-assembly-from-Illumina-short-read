#!/bin/bash
#SBATCH --job-name=PE_fqc
#SBATCH --mail-type=ALL
#SBATCH --mail-user=anor9792@colorado.edu
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=4gb
#SBATCH --time=00:30:00
#SBATCH --partition=short
#SBATCH --output=/scratch/Users/anor9792/eofiles/%x.%A_%a.out
#SBATCH --error=/scratch/Users/anor9792/eofiles/%x.%A_%a.err


echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo date

inDir=/bbduk
outDir=/QCfiles

queries=($(ls ${inDir}/*fastq.gz | xargs -n 1 basename | sed --expression='s/_R1_paired.fastq.gz//g' | sed --expression='s/_R2_paired.fastq.gz//g' | uniq))

numThreads=8

module load fastqc


echo "Running FastQC..."
echo "FastQC version: "$(fastqc --version)
echo "Processing file: "${queries[$SLURM_ARRAY_TASK_ID]}
echo "File: "$(ls ${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}) 

for i in 1_paired 2_paired
do
fastqc \
-o ${outDir} \
-f fastq \
-t ${numThreads} \
${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_R$i.fastq.gz
done

echo $(date +"[%b %d %H:%M:%S] Done")

## Explanation of arguments:
# '-f <file_type>' - input file type; options: fastq, bam, sam, bam_mapped, and sam_mapped
# '-t <int>' - number of threads