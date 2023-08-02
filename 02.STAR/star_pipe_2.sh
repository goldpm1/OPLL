#!/bin/bash
#$ -cwd
#$ -S /bin/bash

if ! options=$(getopt -o h --long PROJECT:,PROJECTDIR:,PLATFORM:,REF:,BAM_DIR:,FASTP_DIR_GZ:,FASTQ1:,FASTQ2:,SAMPLE: -- "$@")
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
        --BAM_DIR)
            BAM_DIR=$2
            shift 2 ;;
        --FASTP_DIR_GZ)
            FASTP_DIR_GZ=$2
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


echo -e "PLATFORM="$PLATFORM"\nPROJECTDIR="$PROJECTDIR"\nREF="$REF"\nBAM_DIR="$BAM_DIR"\nFASTP_DIR_GZ="$FASTP_DIR_GZ"\nFASTQ1="$FASTQ1"\nFASTQ2="$FASTQ2"\nSAMPLE="$SAMPLE


#Running mapping jobs.
STAR \
--runThreadN 5 \
--genomeDir $REF \
--readFilesIn $FASTP_DIR_GZ"/"$FASTQ1 $FASTP_DIR_GZ"/"$FASTQ2 \
--readFilesCommand gunzip -c \
--outFileNamePrefix $BAM_DIR"/"$SAMPLE"." \
--outSAMtype BAM SortedByCoordinate \
--twopassMode Basic \
--outSAMattributes All

echo "step1 done"
date

gatk --java-options "-Xmx8G -Djava.io.tmpdir=$PROJECTDIR/temp/" AddOrReplaceReadGroups \
--INPUT $BAM_DIR"/"$SAMPLE".Aligned.sortedByCoord.out.bam" \
--OUTPUT $BAM_DIR"/"$SAMPLE".RGadded.bam" \
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
--INPUT $BAM_DIR"/"$SAMPLE".RGadded.bam" \
--OUTPUT $BAM_DIR"/"$SAMPLE".RGadded.marked.bam" \
--METRICS_FILE $BAM_DIR"/"$SAMPLE".RGadded.marked.metrics" \
--CREATE_INDEX true \
--VALIDATION_STRINGENCY SILENT

echo "MarkDuplicate done"
date

gatk --java-options "-Xmx8G -Djava.io.tmpdir=$PROJECTDIR/temp/" SplitNCigarReads \
-R /data/resource/reference/human/UCSC/hg38/WholeGenomeFasta/genome.fa \
-I $BAM_DIR"/"$SAMPLE".RGadded.marked.bam" \
-O $BAM_DIR"/"$SAMPLE".bam"

echo "SplitNCigarReads done"
date


rm -rf $BAM_DIR"/"$SAMPLE".RGadded.marked.bam" $BAM_DIR"/"$SAMPLE".RGadded.marked.bai" $BAM_DIR"/"$SAMPLE".RGadded.bam" $BAM_DIR"/"$SAMPLE".RGadded.bai" $BAM_DIR"/"$SAMPLE".Aligned.sortedByCoord.out.bam" $BAM_DIR"/"$SAMPLE".Aligned.sortedByCoord.out.bai"