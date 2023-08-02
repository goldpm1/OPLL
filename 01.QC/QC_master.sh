#!/bin/bash
#$ -cwd
#$ -S /bin/bash

logPath="/data/project/OPLL/script/01.QC/log"

if [ ! -d $logPath ] ; then
    mkdir $logPath
fi
for sublog in 1.fastp 2.fastqc; do
    if [ $logPath"/"$sublog ] ; then
        rm -rf $logPath"/"$sublog
    fi
    if [ ! -d $logPath"/"$sublog ] ; then
        mkdir -p $logPath"/"$sublog
    fi
done

# /home/goldpm1/OPLL/01.bulkRNA/01.fastqc 생성
PROJECTDIR="/data/project/OPLL"

for subdir in 01.fastqc 01.fastp; do
    if [ ! -d $PROJECTDIR"/01.bulkRNA/"$subdir ]; then
        mkdir -p $PROJECTDIR"/01.bulkRNA/"$subdir
    fi
done


#for date in 220605 220629 220908 221018 221102 221107 221214 230111 230119 230126 230207 230222 230316 230511 230512; do
for date in 230621 230622 230623; do
    FASTQ_DIR=$PROJECTDIR"/01.bulkRNA/00.fastq/"$date
    FASTP_DIR_GZ=$PROJECTDIR"/01.bulkRNA/01.fastp/gz/"$date    
    FASTP_DIR_UNZIP=$PROJECTDIR"/01.bulkRNA/01.fastp/unzip/"$date    
    multiQC_DIR=$PROJECTDIR"/01.bulkRNA/01.fastqc/"$date
    
    for DIR in ${FASTP_DIR_GZ} ${FASTP_DIR_UNZIP} ${multiQC_DIR}  ; do
        if [ ! -d $DIR ] ; then
            mkdir -p $DIR
        fi
    done


    FQ=$(ls ${FASTQ_DIR}  | egrep "*_1.fastq.gz")    # ' '로 띄어진 string 형태
    FQ_LIST=(${FQ// / })                   # 이를 배열 (list)로 만듬

    for idx in ${!FQ_LIST[@]}              # @ 배열의 모든 element    #! : indexing
    do
            SAMPLE=${FQ_LIST[idx]}         # idx번째의 파일명을 담아둔다
            ID=${FQ_LIST[idx]%_1.fastq.gz}   # 뒤에서 _1.fq.gz는 제거한다    ID : 220605-NORMAL-1, 220605-NORMAL-2, 220605-OLF-1 ...........
            echo -e "Date:"$date"\tID: "$ID

            #01. fastp
            qsub -pe smp 5 -e $logPath"/1.fastp" -o $logPath"/1.fastp" -N 'FP_'${ID} QC_pipe_1_fastp.sh \
                    --ID ${ID}  --FASTQ_DIR ${FASTQ_DIR} --FASTP_DIR_GZ ${FASTP_DIR_GZ} --FASTP_DIR_UNZIP ${FASTP_DIR_UNZIP}

            #02. fastqc
             qsub -pe smp 5 -e $logPath"/2.fastqc" -o $logPath"/2.fastqc" -N "fastqc_"$ID -hold_jid "FP_"$ID "QC_pipe_2_fastqc.sh" \
                 --multiQC_DIR ${multiQC_DIR} --FASTQ1 ${FASTP_DIR}"/"$ID"_1.fastq.gz"  --FASTQ2 ${FASTP_DIR}"/"$ID"_2.fastq.gz"
    done
done