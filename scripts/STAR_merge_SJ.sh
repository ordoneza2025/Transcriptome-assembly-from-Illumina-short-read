#!/bin/bash
set -euo pipefail

# Usage: bash scripts/STAR_merge_SJ.sh [SJ_ROOT_DIR] [OUT_DIR]
# Default: SJ_ROOT_DIR=STAR_1pass, OUT_DIR=STAR_sj

sj_root=${1:-STAR_1pass}
out_dir=${2:-STAR_sj}

mkdir -p "${out_dir}"

echo "Merging SJ files from ${sj_root}..."
cat "${sj_root}"/*/*.SJ.out.tab > "${out_dir}/all_samples.SJ.out.tab"

echo "Filtering merged SJ file..."
awk 'BEGIN{OFS="\t"}
{
  chr=$1
  start=$2
  end=$3
  strand=$4
  motif=$5
  annotated=$6
  unique_reads=$7
  multi_reads=$8
  overhang=$9

  # remove mitochondrial junctions
  if (chr == "chrM" || chr == "MT" || chr == "M") next

  # keep annotated junctions
  if (annotated == 1 && strand != 0) {
    print chr, start, end, strand
    next
  }

  # keep novel canonical junctions with support
  # motif 1/2 = GT/AG or CT/AC
  if ((motif == 1 || motif == 2) && unique_reads >= 3 && overhang >= 12 && strand != 0) {
    print chr, start, end, strand
    next
  }

  # optionally keep stronger GC/AG junctions
  # motif 3/4 = GC/AG or CT/GC
  if ((motif == 3 || motif == 4) && unique_reads >= 5 && overhang >= 12 && strand != 0) {
    print chr, start, end, strand
  }
}' "${out_dir}/all_samples.SJ.out.tab" | sort -k1,1 -k2,2n -k3,3n -k4,4 | uniq > "${out_dir}/filtered.SJ.tab"

echo "Filtered SJ file written to ${out_dir}/filtered.SJ.tab"
