#!/bin/bash
#SBATCH --job-name=STAR_SJ
#SBATCH --mail-type=ALL
#SBATCH --mail-user=
#SBATCH --nodes=1
#SBATCH --ntasks=10
#SBATCH --mem=64gb
#SBATCH --time=1:00:00
#SBATCH --partition=short
#SBATCH --output=%x.%A_%a.out
#SBATCH --error=%x.%A_%a.err

echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started `date`
echo Using $SLURM_NTASKS processors and $SLURM_NNODES nodes


inDir=/scratch/Users/anor9792/bat_decoys/artibeus.j/2026_thesis/short_Read/bbduk_2
outDir=/scratch/Users/anor9792/bat_decoys/artibeus.j/2026_thesis/short_Read/STAR/pass2
genDir=/scratch/Users/anor9792/bat_decoys/artibeus.j/2026_thesis/short_Read/STAR/pass2/index
gtf=/scratch/Users/anor9792/bat_decoys/artibeus.j/Genomes/ucsc/GCF_021234435.1_CSHL_Jam_final.ncbiRefSeq.gtf

queries=($(ls ${inDir}/*fastq.gz | xargs -n 1 basename | sed --expression='s/_R1_paired.fastq.gz//g' | sed --expression='s/_R2_paired.fastq.gz//g' | uniq))

numThreads=10

mkdir -p ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}

pwd; hostname; date

echo "Running STAR (2nd pass)..."
echo "STAR version: "$(STAR --version)
echo "Processing file: "${queries[$SLURM_ARRAY_TASK_ID]}

module load samtools

STAR --runThreadN ${numThreads} \
--genomeDir ${genDir} \
--readFilesIn ${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_R1_paired.fastq.gz \
${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_R2_paired.fastq.gz \
--alignIntronMin 20 --alignIntronMax 1000000 \
--sjdbGTFfile ${gtf} \
--readFilesCommand zcat \
--outFileNamePrefix ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}/ \
--winAnchorMultimapNmax 100 --outFilterMultimapNmax 100 \
--outSAMtype BAM Unsorted SortedByCoordinate

# Filter BAM for MAPQ >= 10, sort and output to new file
echo "Filtering and sorting for uniquely mapped reads (MAPQ ≥ 10)..."
samtools view -q 10 -@ ${numThreads} -b ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}/Aligned.sortedByCoord.out.bam \
| samtools sort -@ ${numThreads} -o ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam

# Index the filtered BAM
samtools index ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam
