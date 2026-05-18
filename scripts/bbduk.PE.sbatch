#!/bin/bash
#SBATCH --job-name=bbduk_PE
#SBATCH --mail-type=ALL
#SBATCH --mail-user=
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=32gb
#SBATCH --time=4:00:00
#SBATCH --partition=short
#SBATCH --output=%x.%A_%a.out
#SBATCH --error=%x.%A_%a.err
# For array jobs, add: SBATCH --array=0-<N-1>

# Set these values for your environment before submitting the job.
# They are left blank here to keep the script general for anyone using it.
inDir=""
outDir=""
adapterFile=""
numThreads=1

module load bbmap


##reading in multiple PE files that end with the same extension to run them as an array 

queries=($(ls ${inDir}/*fq.gz | xargs -n 1 basename | sed --expression='s/_1.fq.gz//g' | sed --expression='s/_2.fq.gz//g' | uniq))


echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`

echo "bbduk version:" $(bbduk.sh --version)
echo "Processing file:" ${queries[$SLURM_ARRAY_TASK_ID]} 
echo $(date +"[%b %d %H:%M:%S] Running bbduk...")

mkdir -p ${outDir}/stats

bbduk.sh -Xmx4g \
in1=${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_1.fq.gz \
in2=${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_2.fq.gz \
out1=${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}_R1_paired.fastq.gz \
out2=${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}_R2_paired.fastq.gz \
ref=${adapterFile} \
qin=33 ktrim=r k=31 mink=11 hdist=1 tpe tbo \
qtrim=r trimq=10 \
stats=${outDir}/stats/${queries[$SLURM_ARRAY_TASK_ID]}_stats.txt \
t=${numThreads}

echo $(date +"[%b %d %H:%M:%S] Done")
