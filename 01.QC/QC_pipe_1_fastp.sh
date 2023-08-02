#!/bin/bash
#$ -cwd
#$ -S /bin/bash

if ! options=$(getopt -o h --long ID:,FASTQ_DIR:,FASTP_DIR_GZ:,FASTP_DIR_UNZIP:, -- "$@")
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
        --ID)
            ID=$2
        shift 2 ;;
        --FASTQ_DIR)
            FASTQ_DIR=$2
        shift 2 ;;
        --FASTP_DIR_GZ)
            FASTP_DIR_GZ=$2
        shift 2 ;;
        --FASTP_DIR_UNZIP)
            FASTP_DIR_UNZIP=$2
        shift 2 ;;
        --)
            shift
            break
    esac
done


echo -e "ID: "$ID"\nFASQT_DIR: "$FASTQ_DIR"\nFQSTP_DIR_GZ: "$FASTP_DIR_GZ"\nFQSTP_DIR_UNZIP: "$FASTP_DIR_UNZIP

fastp \
-i ${FASTQ_DIR}/${ID}"_1.fastq.gz" -I ${FASTQ_DIR}/${ID}"_2.fastq.gz" \
-o ${FASTP_DIR_GZ}/${ID}"_1.fastq.gz" -O ${FASTP_DIR_GZ}/${ID}"_2.fastq.gz" \
-p \
-w 5 \
-5 \
-3 \
--trim_poly_g \
--trim_poly_x \
--length_required 15 \
-y --detect_adapter_for_pe \
-h ${FASTP_DIR_GZ}/${ID}'.html'


cp -f ${FASTP_DIR_GZ}/${ID}"_1.fastq.gz"  ${FASTP_DIR_UNZIP}/${ID}"_1.fastq.gz" 
gunzip ${FASTP_DIR_UNZIP}/${ID}"_1.fastq.gz" 
cp -f ${FASTP_DIR_GZ}/${ID}"_2.fastq.gz"  ${FASTP_DIR_UNZIP}/${ID}"_2.fastq.gz" 
gunzip ${FASTP_DIR_UNZIP}/${ID}"_2.fastq.gz" 