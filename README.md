# Transcriptome-assembly-from-Illumina-short-read

This repository explains the workflow and provides scripts for transcriptome assembly from Illumina short-read RNA-sequencing data.

The workflow includes raw-read cleaning, quality control, splice-aware alignment allowing for multimapping reads, splice junction correction, and transcriptome assembly.

## Workflow Overview

1. `bbduk` for adapter trimming and quality filtering
2. `FastQC` + `MultiQC` for read quality assessment
3. Two-pass alignment with `STAR` and splice junction correction
4. Transcriptome assembly with `StringTie`

## Dependencies

- `bbduk` (BBMap)
- `FastQC`
- `MultiQC`
- `STAR`
- `StringTie`
- Reference genome FASTA and annotation GTF
- RNA-seq paired-end FASTQ files

## Step 1: Read trimming with bbduk

Use `bbduk` to remove adapter contamination, trim low-quality bases, and discard short reads.

Actual script: `scripts/bbduk.PE.sbatch`

This script is written for SLURM and can be submitted either as a single job or as an array job.
- Single job: `sbatch scripts/bbduk.PE.sbatch`
- Array job: `sbatch --array=0-<N-1> scripts/bbduk.PE.sbatch`

The script discovers sample prefixes from paired files in `inDir` using `_1.fq.gz` and `_2.fq.gz` naming.
- In array mode, `SLURM_ARRAY_TASK_ID` selects the sample index from the `queries` list.
- In single-job mode, the script defaults to task `0` and processes the first sample found.

Script variables in `scripts/bbduk.PE.sbatch` are intentionally left blank for general use:
- `inDir` — raw paired-end input FASTQ directory
- `outDir` — trimmed FASTQ output directory
- `adapterFile` — BBMap adapter reference FASTA
- `numThreads` — number of threads passed to `bbduk`

Important bbduk flags used in this workflow:
- `qin=33` — input FASTQ quality scores are Phred+33
- `ktrim=r` — trim adapters from the right read end
- `k=31` — use 31-mers to match adapters
- `mink=11` — allow shorter k-mer matches down to 11 bases
- `hdist=1` — permit one mismatch in adapter k-mer matching
- `tpe tbo` — trim both reads in a pair and use overlap-based adapter removal
- `qtrim=r` — quality trim from the right end
- `trimq=10` — trim bases with quality below 10
- `stats=` — write sample-specific trimming statistics

These flag definitions are documented here and reflect the actual settings used in the script.

## Step 2: Read quality control with FastQC and MultiQC

Run `FastQC` on trimmed FASTQ files to evaluate per-base quality, adapter content, and other sequencing metrics.

Actual scripts:
- `scripts/fastqcPE.sbatch` — SLURM FastQC batch script for paired trimmed reads
- `scripts/multiqc.sbatch` — SLURM MultiQC batch script to aggregate FastQC outputs

FastQC notes:
- `inDir` and `outDir` are left blank in the script to keep paths general
- `-f fastq` specifies FASTQ input format
- `-t <int>` specifies the number of threads
- The script expects paired files named with `_R1_paired.fastq.gz` and `_R2_paired.fastq.gz`
- In array mode, `SLURM_ARRAY_TASK_ID` selects the sample prefix from the `queries` list

MultiQC notes:
- `inDir`, `outDir`, and the `multiqc` image path are left blank in the script
- `multiqc` gathers FastQC ZIP output files and writes a summary report directory
- Set those variables before running to point at your FastQC output, report location, and local container/image path

These scripts are submitted via SLURM and should be customized for your local cluster paths before use.

## Step 3: Two-pass alignment with STAR and splice junction correction

Use `STAR` in two-pass mode to improve splice junction detection and alignment accuracy.

STAR workflow scripts in this repo:
- `scripts/STAR_index.sbatch` — generate the STAR genome index from reference FASTA and GTF
- `scripts/STAR_SJ_index.sbatch` — build the second-pass genome index using first-pass splice junctions
- `scripts/STAR_alignment.sbatch` — first-pass STAR alignment on trimmed paired reads
- `scripts/STAR_alignment_SJ.sbatch` — second-pass STAR alignment with junction-corrected genome index

Submit these with SLURM:
- `sbatch scripts/STAR_index.sbatch`
- `sbatch scripts/STAR_SJ_index.sbatch`
- `sbatch scripts/STAR_alignment.sbatch`
- `sbatch scripts/STAR_alignment_SJ.sbatch`

For multi-sample alignment, the `STAR_alignment` and `STAR_alignment_SJ` scripts use array-mode sample selection, so use:
- `sbatch --array=0-<N-1> scripts/STAR_alignment.sbatch`
- `sbatch --array=0-<N-1> scripts/STAR_alignment_SJ.sbatch`

STAR options used in the actual scripts:
- `--runMode genomeGenerate` — build the STAR genome index
- `--genomeFastaFiles` — reference genome FASTA input
- `--sjdbGTFfile` — splice junction annotation from GTF
- `--sjdbOverhang` — read length minus 1 for splice junction database construction
- `--sjdbFileChrStartEnd` — first-pass junction file for second-pass genome generation
- `--limitGenomeGenerateRAM` — memory limit for genome generation
- `--runThreadN` — number of threads
- `--readFilesIn` — paired FASTQ inputs
- `--readFilesCommand zcat` — decompress gzipped inputs on the fly
- `--alignIntronMin 20` — minimum intron length
- `--alignIntronMax 1000000` — maximum intron length
- `--winAnchorMultimapNmax 100` — maximum multimapping anchors for alignment
- `--outFilterMultimapNmax 100` — maximum multimapped alignments retained
- `--outSAMtype BAM Unsorted SortedByCoordinate` — write BAM output and sort by coordinate

The STAR alignment scripts also post-process the output BAM with `samtools view -q 10` and `samtools sort`, then index the filtered BAM.

After STAR first-pass junction discovery, run the helper script to merge and filter SJ files before building the second-pass index:

```bash
bash scripts/STAR_merge_SJ.sh STAR_1pass STAR_sj
```

This creates:
- `STAR_sj/all_samples.SJ.out.tab`
- `STAR_sj/filtered.SJ.tab`

The helper script:
- removes mitochondrial junctions
- retains annotated junctions
- retains novel canonical junctions with sufficient support
- optionally retains stronger GC/AG junctions when supported

In the first pass, STAR generates alignments and allows junction discovery. In the second pass, STAR aligns again using the corrected junction index to better support novel and lowly expressed splice sites.

## Step 4: Transcriptome assembly with StringTie

Assemble transcripts from the aligned reads and produce gene/transcript-level GTF output.

Script: `scripts/stringtie.sbatch`

This script activates the conda environment `stringtie2` before running StringTie. It does not use `module load stringtie`.

Important StringTie options used in the script:
- `${inFile}` — input BAM file from STAR second-pass alignment
- `-p 8` — use 8 CPU threads
- `-A ${outDir}/AJ_all_sr_conservative.gene_abund.tab` — write gene abundance output
- `--rf` — input library is stranded with reverse-forward read orientation
- `-G ${refFile}` — use the reference annotation GTF file
- `-f 0.05` — minimum isoform abundance in the sample for reporting
- `-c 1.5` — minimum read coverage for assembled transcripts
- `-o ${outDir}/AJ_all_sr_conservative.gtf` — output assembled transcript GTF

Before running, update the script variables `inFile`, `outDir`, and `refFile` to point to your BAM input file, StringTie output directory, and GTF annotation file.

## Notes on documentation

- Best practice: store the exact commands and flags in the scripts for reproducibility.
- The README should summarize each step, explain the purpose, and link to the scripts.

## How to use this repository

1. Place raw paired-end FASTQ files in an input directory.
2. Update the script variables for paths, sample names, and reference files.
3. Run the trimming script, then the QC script, then STAR pass 1 and pass 2, then the StringTie assembly script.
4. Review the output reports and assembled GTF file.

## Script references

- `scripts/bbduk.PE.sbatch` — SLURM batch trimming with `bbduk`
- `scripts/fastqcPE.sbatch` — SLURM FastQC batch script
- `scripts/multiqc.sbatch` — SLURM MultiQC batch script
- `scripts/STAR_index.sbatch` — STAR genome index creation
- `scripts/STAR_SJ_index.sbatch` — STAR splice junction index / first-pass junction generation
- `scripts/STAR_alignment.sbatch` — STAR alignment run
- `scripts/STAR_alignment_SJ.sbatch` — STAR alignment with junction correction
- `scripts/STAR_merge_SJ.sh` — merge and filter first-pass SJ files for second-pass indexing
- `scripts/star_pass1.sh` — first-pass `STAR` alignment and junction collection
- `scripts/star_pass2.sh` — second-pass `STAR` alignment with corrected junctions
- `scripts/stringtie.sbatch` — SLURM StringTie assembly script using conda environment `stringtie2`
