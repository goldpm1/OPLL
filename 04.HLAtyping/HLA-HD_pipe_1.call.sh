#!/bin/bash
#$ -cwd
#$ -S /bin/bash

if ! options=$(getopt -o h --long FREQ_DIR:,HLAGENE_SPLIT_PATH:,DICT_DIR:,HLA_HD_DIR:,FASTQ1:,FASTQ2:,SAMPLE:, -- "$@")
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
        --FREQ_DIR)
            FREQ_DIR=$2
        shift 2 ;;
        --HLAGENE_SPLIT_PATH)
            HLAGENE_SPLIT_PATH=$2
        shift 2 ;;
        --DICT_DIR)
            DICT_DIR=$2
        shift 2 ;;
        --HLA_HD_DIR)
            HLA_HD_DIR=$2
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


echo -e "bash /home/goldpm1/tools/HLA-HD/hlahd.1.7.0/bin/hlahd.sh  -t 2 -m 100 -c 0.95 -f " ${FREQ_DIR}  ${FASTQ1} ${FASTQ2}  ${HLAGENE_SPLIT_PATH} ${DICT_DIR} ${SAMPLE} ${HLA_HD_DIR}

bash "/home/goldpm1/tools/HLA-HD/hlahd.1.7.0/bin/hlahd.sh" \
		-t 2 -m 70 -c 0.95 \
		-f ${FREQ_DIR} \
		${FASTQ1} ${FASTQ2} \
		${HLAGENE_SPLIT_PATH} \
		${DICT_DIR} \
		${SAMPLE} \
	 	${HLA_HD_DIR}