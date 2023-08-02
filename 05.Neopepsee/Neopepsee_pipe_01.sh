#!/bin/bash
#$ -cwd
#$ -S /bin/bash

if ! options=$(getopt -o h --long NEOPEPSEE_DIR:,FASTQ1:,FASTQ2:,REF:,SAMPLE:,INPUT_VCF:,KMER:,OUTPUT_DIR:, -- "$@")
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
        --NEOPEPSEE_DIR)
            NEOPEPSEE_DIR=$2
        shift 2 ;;
        --FASTQ1)
            FASTQ1=$2
        shift 2 ;;
        --FASTQ2)
            FASTQ2=$2
        shift 2 ;;
        --REF)
            REF=$2
        shift 2 ;;
        --SAMPLE)
            SAMPLE=$2
        shift 2 ;;
        --INPUT_VCF)
            INPUT_VCF=$2
        shift 2 ;;
        --KMER)
            KMER=$2
        shift 2 ;;
        --OUTPUT_DIR)
            OUTPUT_DIR=$2
        shift 2 ;;
        --)
            shift
            break
    esac
done

java -jar /opt/Yonsei/Neopepsee/3.0.1/neopepsee-3.0.1.jar \
    -1 ${FASTQ1} \
    -2 ${FASTQ2} \
    -r ${REF} \
    -v ${INPUT_VCF} \
    -n ${KMER} \
    -d ${OUTPUT_DIR}