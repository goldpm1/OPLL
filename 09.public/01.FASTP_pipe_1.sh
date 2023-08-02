#!/bin/bash
#$ -cwd
#$ -S /bin/bash

if ! options=$(getopt -o h --long ID:,FASTQ_PATH:,TRIM_PATH:, -- "$@")
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
        --FASTQ_PATH)
            FASTQ_PATH=$2
        shift 2 ;;
        --TRIM_PATH)
            TRIM_PATH=$2
        shift 2 ;;
        --)
            shift
            break
    esac
done


echo -e $ID"\n"$FASTQ_PATH"\n"$TRIM_PATH

fastp \
-i ${FASTQ_PATH}/${ID}"_1.fastq.gz" -I ${FASTQ_PATH}/${ID}"_2.fastq.gz" \
-o ${TRIM_PATH}/${ID}"_1.fastq.gz" -O ${TRIM_PATH}/${ID}"_2.fastq.gz" \
-p \
-w 5 \
-5 \
-3 \
--trim_poly_g \
--trim_poly_x \
--length_required 15 \
-y --detect_adapter_for_pe \
-h ${TRIM_PATH}/${ID}'.html'
