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

if ! options=$(getopt -o h --long FASTQ1:,FASTQ2: -- "$@")
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
        --FASTQ1)
            FASTQ1=$2
            shift 2 ;;
        --FASTQ2)
            FASTQ2=$2
            shift 2 ;;
        --)
            shift
            break
    esac
done

gzip ${FASTQ1}
gzip ${FASTQ2}