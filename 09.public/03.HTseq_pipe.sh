#!/bin/bash
#$ -cwd
#$ -S /bin/bash

INPUT=$1
OUTPUT=$2
GTFPath=$3

htseq-count -f bam -r name -t exon -i gene_id -a 20 -m intersection-strict --stranded=no  $INPUT $GTFPath > $OUTPUT