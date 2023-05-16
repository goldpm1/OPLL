#!/bin/bash
#$ -cwd
#$ -S /bin/bash

# PROJECT=$1
# PROJECTDIR=$2
# PLATFORM=$3
# REF=$4
# BAMPath=$5
# FASTQPath=$6
# FASTQ1=$7
# FASTQ2=$8
# SAMPLE=$9

if ! options=$(getopt -o h --long PROJECT:,PROJECTDIR:,PLATFORM:,REF:,BAMPath:,FASTQPath:,FASTQ1:,FASTQ2:,SAMPLE: -- "$@")
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
        --BAMPath)
            BAMPath=$2
            shift 2 ;;
        --FASTQPath)
            FASTQPath=$2
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


echo -e "PLATFORM="$PLATFORM"\nPROJECTDIR="$PROJECTDIR"\nREF="$REF"\nBAMPath="$BAMPath"\nFASTQPath="$FASTQPath"\nFASTQ1="$FASTQ1"\nFASTQ2="$FASTQ2"\nSAMPLE="$SAMPLE


#Running mapping jobs.
STAR \
--runThreadN 5 \
--genomeDir $REF \
--readFilesIn $FASTQPath"/"$FASTQ1 $FASTQPath"/"$FASTQ2 \
--readFilesCommand gunzip -c \
--outFileNamePrefix $BAMPath"/"$SAMPLE"." \
--outSAMtype BAM SortedByCoordinate \
--twopassMode Basic \
--outSAMattributes All

echo "step1 done"
date

gatk --java-options "-Xmx8G -Djava.io.tmpdir=$PROJECTDIR/temp/" AddOrReplaceReadGroups \
--INPUT $BAMPath"/"$SAMPLE".Aligned.sortedByCoord.out.bam" \
--OUTPUT $BAMPath"/"$SAMPLE".RGadded.bam" \
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
--INPUT $BAMPath"/"$SAMPLE".RGadded.bam" \
--OUTPUT $BAMPath"/"$SAMPLE".RGadded.marked.bam" \
--METRICS_FILE $BAMPath"/"$SAMPLE".RGadded.marked.metrics" \
--CREATE_INDEX true \
--VALIDATION_STRINGENCY SILENT

echo "MarkDuplicate done"
date

gatk --java-options "-Xmx8G -Djava.io.tmpdir=$PROJECTDIR/temp/" SplitNCigarReads \
-R /data/resource/reference/human/UCSC/hg38/WholeGenomeFasta/genome.fa \
-I $BAMPath"/"$SAMPLE".RGadded.marked.bam" \
-O $BAMPath"/"$SAMPLE".bam"

echo "SplitNCigarReads done"
date


rm -rf $BAMPath"/"$SAMPLE".RGadded.marked.bam" $BAMPath"/"$SAMPLE".RGadded.marked.bai" $BAMPath"/"$SAMPLE".RGadded.bam" $BAMPath"/"$SAMPLE".RGadded.bai" $BAMPath"/"$SAMPLE".Aligned.sortedByCoord.out.bam" $BAMPath"/"$SAMPLE".Aligned.sortedByCoord.out.bai"