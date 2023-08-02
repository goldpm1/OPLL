#!/bin/bash
#$ -cwd
#$ -S /bin/bash

# PROJECT=$1
# PROJECTDIR=$2
# PLATFORM=$3
# REF=$4
# BAMDIR=$5
# FASTQDIR=$6
# FASTQ1=$7
# FASTQ2=$8
# SAMPLE=$9

if ! options=$(getopt -o h --long PROJECT:,PROJECTDIR:,PLATFORM:,REF:,BAMDIR:,FASTQDIR:,FASTQ1:,FASTQ2:,SAMPLE: -- "$@")
then
    echo "ERROR: invalid options"
    exit 1
fi

eval set -- $options

while true; do
    case "$1" in
        -h|--help)
            echo "Usage"
            shift ;;
        --PROJECT)
            PROJECT=$2
            shift 2 ;;
        --PROJECTDIR)
            PROJECTDIR=$2
            shift 2 ;;
        --PLATFORM)
            PLATFORM=$2
            shift 2 ;;
        --REF)
            REF=$2
            shift 2 ;;
        --BAMDIR)
            BAMDIR=$2
            shift 2 ;;
        --FASTQDIR)
            FASTQDIR=$2
            shift 2 ;;
        --FASTQ1)
            FASTQ1=$2
            shift 2 ;;
        --FASTQ2)
            FASTQ2=$2
            shift 2 ;;
        --SAMPLE)
            SAMPLE=$2
            shift 2 ;;
        --)
            shift
            break
    esac
done


echo -e "PLATFORM="$PLATFORM"\nPROJECTDIR="$PROJECTDIR"\nREF="$REF"\nBAMDIR="$BAMDIR"\nFASTQDIR="$FASTQDIR"\nFASTQ1="$FASTQ1"\nFASTQ2="$FASTQ2"\nSAMPLE="$SAMPLE


#Running mapping jobs.
STAR \
--runThreadN 5 \
--genomeDir $REF \
--readFilesIn $FASTQDIR"/"$FASTQ1 $FASTQDIR"/"$FASTQ2 \
--readFilesCommand gunzip -c \
--outFileNamePrefix $BAMDIR"/"$SAMPLE"." \
--outSAMtype BAM SortedByCoordinate \
--twopassMode Basic \
--outSAMattributes All

echo "step1 done"
date

gatk --java-options "-Xmx8G -Djava.io.tmpdir=$PROJECTDIR/temp/" AddOrReplaceReadGroups \
--INPUT $BAMDIR"/"$SAMPLE".Aligned.sortedByCoord.out.bam" \
--OUTPUT $BAMDIR"/"$SAMPLE".RGadded.bam" \
--SORT_ORDER coordinate \
--RGLB $PROJECT  \
--RGPL $PLATFORM  \
--RGPU $PLATFORM  \
--RGSM $SAMPLE  \
--CREATE_INDEX true  \
--VALIDATION_STRINGENCY SILENT

echo "AddRG done"
date

gatk --java-options "-Xmx8G -Djava.io.tmpdir=$PROJECTDIR/temp/" MarkDuplicates \
--INPUT $BAMDIR"/"$SAMPLE".RGadded.bam" \
--OUTPUT $BAMDIR"/"$SAMPLE".RGadded.marked.bam" \
--METRICS_FILE $BAMDIR"/"$SAMPLE".RGadded.marked.metrics" \
--CREATE_INDEX true \
--VALIDATION_STRINGENCY SILENT

echo "MarkDuplicate done"
date

gatk --java-options "-Xmx8G -Djava.io.tmpdir=$PROJECTDIR/temp/" SplitNCigarReads \
-R /data/resource/reference/human/UCSC/hg38/WholeGenomeFasta/genome.fa \
-I $BAMDIR"/"$SAMPLE".RGadded.marked.bam" \
-O $BAMDIR"/"$SAMPLE".bam"

echo "SplitNCigarReads done"
date


rm -rf $BAMDIR"/"$SAMPLE".RGadded.marked.bam" $BAMDIR"/"$SAMPLE".RGadded.marked.bai" $BAMDIR"/"$SAMPLE".RGadded.bam" $BAMDIR"/"$SAMPLE".RGadded.bai" $BAMDIR"/"$SAMPLE".Aligned.sortedByCoord.out.bam" $BAMDIR"/"$SAMPLE".Aligned.sortedByCoord.out.bai"