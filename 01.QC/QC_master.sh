#!/bin/bash
#$ -cwd
#$ -S /bin/bash

logPath="/home/goldpm1/OPLL/script/01.QC/log"

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

# /home/goldpm1/OPLL/0.rnaraw/01.fastqc 생성
for subdir in 01.fastqc; do
    if [ ! -d $PROJECTDIR"/0.rnaraw/"$subdir ]; then
        mkdir -p $PROJECTDIR"/0.rnaraw/"$subdir
    fi
done



PROJECTDIR="/home/goldpm1/OPLL"

#for date in 220605 220629 220908 221018 221102 221107 221214 230111 230119; do
for date in 230126 230207; do
    FASTQ_PATH=$PROJECTDIR"/0.rnaraw/00.fastq/"$date
    multiQC_PATH=$PROJECTDIR"/0.rnaraw/01.fastqc/"$date
    BAM_PATH=$PROJECTDIR"/0.rnaraw/02.bam/"$date

    for DIR in $multiQC_PATH $BAM_PATH; do
        if [ ! -d $DIR ] ; then
            mkdir -p $DIR
        fi
    done


    FQ=$(ls $FASTQ_PATH  | egrep "*_1.fastq.gz")    # ' '로 띄어진 string 형태
    FQ_LIST=(${FQ// / })                   # 이를 배열 (list)로 만듬

    for idx in ${!FQ_LIST[@]}              # @ 배열의 모든 element    #! : indexing
    do
            SAMPLE=${FQ_LIST[idx]}         # idx번째의 파일명을 담아둔다
            ID=${FQ_LIST[idx]%_1.fastq.gz}   # 뒤에서 _1.fq.gz는 제거한다    ID : 220605-NORMAL-1, 220605-NORMAL-2, 220605-OLF-1 ...........
            echo -e "Date:"$date"\tID: "$ID

            qsub -pe smp 5 -e $logPath"/2.fastqc" -o $logPath"/2.fastqc" -N "fastqc_"$ID "QC_pipe_2_fastqc.sh" \
                --multiQC_PATH ${multiQC_PATH} --FASTQ1 ${FASTQ_PATH}"/"$ID"_1.fastq.gz"  --FASTQ2 ${FASTQ_PATH}"/"$ID"_2.fastq.gz"
    done
done




    
# #1. FASTP
# qsub -pe smp 5 -e $logPath"/1.fastp" -o $logPath"/1.fastp" -N 'FP_'${Sample_ID} QC_pipe_1_fastp.sh \
# --Sample_ID ${Sample_ID}  --FASTQ_PATH ${FASTQ_PATH} --TRIM_PATH ${TRIM_PATH}

# #2. FASTQC
# qsub -pe smp 5 -e $logPath"/2.fastqc" -o $logPath"/2.fastqc" -N 'FQC_'${Sample_ID} -hold_jid 'FP_'${Sample_ID} QC_pipe_2_fastqc.sh \
# --Sample_ID ${Sample_ID}  --FASTQ_PATH ${TRIM_PATH} --multiQC_PATH ${multiQC_PATH}
