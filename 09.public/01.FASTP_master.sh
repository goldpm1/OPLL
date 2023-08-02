#!/bin/bash
#$ -S /bin/bash
#$ -cwd

scriptPath="/data/project/OPLL/script/11.public"
logPath=$scriptPath"/log"
PROJECTDIR="/data/project/OPLL/0.rnaraw/99.public"



#REF="/home/goldpm1/reference/genome.fa"

for sublog in 1.fastp; do
    if [ -d $logPath"/"$sublog ]; then
        rm -rf $logPath"/"$sublog
    fi
    if [ ! -d $logPath"/"$sublog ]; then
        mkdir -p $logPath"/"$sublog
    fi
done


for date in "GSE175236" "GSE78608" "GSE227994" "GSE220630" "GSE149167" "GSE188760" "GSE69787" "GSE186542" "GSE197172" "GSE102312" ; do
    FASTQDIR=$PROJECTDIR"/"$date"/01.fasta"
    TRIMDIR=$PROJECTDIR"/"$date"/02.fastp"
    
    if [ ! -d $TRIMDIR ]; then
        mkdir -p $TRIMDIR
    fi

    FASTQ1=$(ls $FASTQDIR | egrep '_1.fastq.gz')
    FASTQ2=$(ls $FASTQDIR | egrep '_2.fastq.gz')
    FASTQ1_LIST=(${FASTQ1// / })
    FASTQ2_LIST=(${FASTQ2// / })


    if [ ${#FASTQ1_LIST[@]} -eq ${#FASTQ2_LIST[@]} ]; then
        for idx in ${!FASTQ1_LIST[@]}; do
            SAMPLE=${FASTQ1_LIST[idx]%_1*}
            SAMPLE_LIST="$SAMPLE_LIST $SAMPLE"
            
            #01. fastp
            qsub -pe smp 5 -e $logPath"/1.fastp" -o $logPath"/1.fastp" -N 'FP_'${SAMPLE} "01.FASTP_pipe_1.sh" \
                     --ID ${SAMPLE}  --FASTQ_PATH ${FASTQDIR} --TRIM_PATH ${TRIMDIR}                    
        done
    else
        echo "Not matched pair data."
    fi
done