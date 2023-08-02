#!/bin/bash
#$ -S /bin/bash
#$ -cwd

PROJECTDIR="/data/project/OPLL"

CURRENT_PATH=`pwd -P`
scriptPath=${CURRENT_PATH}
logPath=${CURRENT_PATH}"/log"

REF_hg38="/home/goldpm1/reference/genome.fa"
#REF_hg38="/data/resource/reference/human/UCSC/hg38/WholeGenomeFasta/genome.fa"
REF_hg19="/home/goldpm1/reference/hg19/hg19.fa"

for sublog in 05-1.call; do
  if [ -d $logPath"/"$sublog ]; then
      rm -rf $logPath"/"$sublog
  fi
  if [ ! -d $logPath"/"$sublog ]; then
          mkdir -p $logPath"/"$sublog
  fi
done


for date in 230126; do
    FASTP_UNZIP_DIR=$PROJECTDIR"/01.bulkRNA/01.fastp/unzip/"$date
    NEOPEPSEE_DIR=$PROJECTDIR"/01.bulkRNA/06.Neopepsee/"$date
    KMER=9
    

    if [ ! -d ${NEOPEPSEE_DIR} ]; then
            mkdir -p ${NEOPEPSEE_DIR}
    fi

    FASTQ1=$(ls ${FASTP_UNZIP_DIR} | egrep '_1.fastq')
    FASTQ2=$(ls ${FASTP_UNZIP_DIR} | egrep '_2.fastq')
    FASTQ1_LIST=(${FASTQ1// / })
    FASTQ2_LIST=(${FASTQ2// / })

    if [ ${#FASTQ1_LIST[@]} -eq ${#FASTQ2_LIST[@]} ]; then
        for idx in ${!FASTQ1_LIST[@]}; do
            SAMPLE=${FASTQ1_LIST[idx]%_1*}
            SAMPLE_LIST="$SAMPLE_LIST $SAMPLE"

            #echo -e ${FASTQ1_LIST[idx]}"\t"${FASTQ2_LIST[idx]}
            echo $SAMPLE
        done
    fi
done