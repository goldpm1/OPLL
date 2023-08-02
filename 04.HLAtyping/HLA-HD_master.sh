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

for sublog in 04-1.HLA-HD; do
  if [ -d $logPath"/"$sublog ]; then
      rm -rf $logPath"/"$sublog
  fi
  if [ ! -d $logPath"/"$sublog ]; then
          mkdir -p $logPath"/"$sublog
  fi
done

FREQ_DIR="/opt/Yonsei/HLA-HD/hlahd.1.7.0/freq_data"
HLAGENE_SPLIT_PATH="/opt/Yonsei/HLA-HD/hlahd.1.7.0/HLA_gene.split.txt"
DICT_DIR="/opt/Yonsei/HLA-HD/hlahd.1.7.0/dictionary"

for date in 220605 220629 220908 221018 221102 221107 221214 230111 230119 230207 230222 230316 230511 230512; do
#for date in 230126; do
    FASTP_UNZIP_DIR=$PROJECTDIR"/01.bulkRNA/01.fastp/unzip/"$date
    HLA_HD_DIR=$PROJECTDIR"/01.bulkRNA/05.HLAtyping/HLA-HD/"$date

    if [ ! -d ${HLA_HD_DIR} ]; then
            mkdir -p ${HLA_HD_DIR}
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

            qsub -pe smp 5 -e $logPath"/04-1.HLA-HD" -o $logPath"/04-1.HLA-HD" -N 'HLAHD.1_'${SAMPLE}  ${scriptPath}"/HLA-HD_pipe_1.call.sh" \
                --FREQ_DIR ${FREQ_DIR} --HLAGENE_SPLIT_PATH ${HLAGENE_SPLIT_PATH} --DICT_DIR ${DICT_DIR} --HLA_HD_DIR ${HLA_HD_DIR} \
                --FASTQ1  ${FASTP_UNZIP_DIR}"/"${FASTQ1_LIST[idx]} \
                --FASTQ2  ${FASTP_UNZIP_DIR}"/"${FASTQ2_LIST[idx]} \
                --SAMPLE ${SAMPLE}

            qsub -pe smp 1 -e $logPath"/04-2.ToNeopepsee" -o $logPath"/04-2.ToNeopepsee" -N 'HLAHD.1_'${SAMPLE} -N 'HLAHD.2_'${SAMPLE}  ${scriptPath}"/HLA-HD_pipe_2.ToNeopepsee.sh" \
                --FREQ_DIR ${FREQ_DIR} --HLAGENE_SPLIT_PATH ${HLAGENE_SPLIT_PATH} --DICT_DIR ${DICT_DIR} --HLA_HD_DIR ${HLA_HD_DIR} \
                
        done
    fi
done