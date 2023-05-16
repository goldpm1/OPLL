#!/bin/bash

if ! options=$(getopt -o h --long FASTQ1:,FASTQ2:,multiQC_PATH:, -- "$@")
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
        --multiQC_PATH)
            multiQC_PATH=$2
        shift 2 ;;
        --)
            shift
            break
    esac
done


echo -e $FASTQ1"\n"$FASTQ2"\n"$multiQC_PATH


fastqc -o ${multiQC_PATH} -f fastq ${FASTQ1} ${FASTQ2}