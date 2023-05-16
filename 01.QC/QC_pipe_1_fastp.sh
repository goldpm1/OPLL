#!/bin/bash
#$ -cwd
#$ -S /bin/bash

if ! options=$(getopt -o h --long Sample_ID:,FASTQ_PATH:,TRIM_PATH:, -- "$@")
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
        --Sample_ID)
            Sample_ID=$2
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


echo -e $Sample_ID"\n"$FASTQ_PATH"\n"$TRIM_PATH

fastp \
-i ${FASTQ_PATH}/${Sample_ID}'_1.fastq' -I ${FASTQ_PATH}/${Sample_ID}'_2.fastq' \
-o ${TRIM_PATH}/${Sample_ID}".R1.fq" -O ${TRIM_PATH}/${Sample_ID}".R2.fq" \
-p \
-w 5 \
-5 \
-3 \
--trim_poly_g \
--trim_poly_x \
--length_required 15 \
-y --detect_adapter_for_pe \
-h ${TRIM_PATH}/${Sample_ID}'.html'

gzip ${TRIM_PATH}/${Sample_ID}".R1.fq"
gzip ${TRIM_PATH}/${Sample_ID}".R2.fq"