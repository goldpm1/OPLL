#!/bin/bash
#$ -cwd
#$ -S /bin/bash

REF=$1

##Generating genome indexes.
STAR \
  --runThreadN 8 \
  --runMode genomeGenerate \
  --genomeDir $REF \
  --genomeFastaFiles /data/resource/reference/human/UCSC/hg38/WholeGenomeFasta/genome.fa \
  --sjdbGTFfile /data/resource/annotation/human/UCSC/hg38/Genes/genes.gtf \
  --sjdbOverhang 100


# /home/goldpm1/resources/gencode.v38.primary_assembly.annotation.gtf