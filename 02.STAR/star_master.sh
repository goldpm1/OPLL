#!/bin/bash
#$ -S /bin/bash
#$ -cwd

scriptPath="/data/project/OPLL/script/02.STAR"
logPath=$scriptPath"/log"
PROJECTDIR="/data/project/OPLL"



for sublog in 01.mkindex 02.align; do
    if [ ! -d $logPath"/"$sublog ]; then
        mkdir -p $logPath"/"$sublog
    fi
done

for subdir in 00.fastq 02.bam; do
    if [ ! -d $PROJECTDIR"/01.bulkRNA/"$subdir ]; then
        mkdir -p $PROJECTDIR"/01.bulkRNA/"$subdir
    fi
done



# reference path
# HISAT2
#REF=/data/public/HISAT/UCSC_hg19/genome
# STAR
REF="/data/project/OPLL/01.bulkRNA/03.index"
PLATFORM="Illumina"



# [Generating genome indexes   2.index]  #이미 만들어놓음
#qsub -pe smp 3 -e $logPath"/01.mkindex" -o $logPath"/01.mkindex" -N 'star1_'$SAMPLE $scriptPath"/star_pipe_1.sh" $REF

if [ -d $logPath"/02.align" ]; then
    rm -rf $logPath"/02.align"
fi
if [ ! -d $logPath"/02.align" ]; then
    mkdir -p $logPath"/02.align"
fi

#for date in 220605 220629 220908 221018 221102 221107 221214 230111 230119 230126 230207 230222 230316 230511 230512; do
for date in 230621 230622 230623; do
    FASTP_DIR_GZ=$PROJECTDIR"/01.bulkRNA/01.fastp/gz/"$date
    BAM_DIR=$PROJECTDIR"/01.bulkRNA/02.bam/"$date

    if [ ! -d $BAM_DIR ]; then
        mkdir -p $BAM_DIR
    fi

    FASTQ1=$(ls $FASTP_DIR_GZ | egrep '_1.fastq.gz')
    FASTQ2=$(ls $FASTP_DIR_GZ | egrep '_2.fastq.gz')
    FASTQ1_LIST=(${FASTQ1// / })
    FASTQ2_LIST=(${FASTQ2// / })

    if [ ${#FASTQ1_LIST[@]} -eq ${#FASTQ2_LIST[@]} ]; then
        for idx in ${!FASTQ1_LIST[@]}; do
            SAMPLE=${FASTQ1_LIST[idx]%_1*}
            SAMPLE_LIST="$SAMPLE_LIST $SAMPLE"
            
            echo -e "PROJECTDIR : "$PROJECTDIR"\tBAM_DIR : "$BAM_DIR"\tFASTP_DIR_GZ : "$FASTP_DIR_GZ"\tFASTQ1_LIST[idx] : "${FASTQ1_LIST[idx]}"\tFASTQ2_LIST[idx] : "${FASTQ2_LIST[idx]}"\nSAMPLE : "$SAMPLE
            
            
            # [STAR align each bam]
            qsub -pe smp 5 -e $logPath"/02.align" -o $logPath"/02.align" -hold_jid "fastqc_"$SAMPLE -N 'star2_'$SAMPLE \
                $scriptPath"/star_pipe_2.sh" \
                    --PROJECT "OPLL" --PLATFORM "Illumina" --PROJECTDIR $PROJECTDIR --REF $REF --BAM_DIR $BAM_DIR --FASTP_DIR_GZ $FASTP_DIR_GZ \
                    --FASTQ1 ${FASTQ1_LIST[idx]} --FASTQ2 ${FASTQ2_LIST[idx]} --SAMPLE $SAMPLE
            
            # [HISAT align]
            # qsub -e $DIR/temp/ -o $DIR/temp/ -N 'ht2_'$SAMPLE $scriptPath"/pipe_HISAT2.sh" \
            #             $PROJECT $DIR $PLATFORM $REF $BAM_DIR $DataPath ${FASTQ1_LIST[idx]} ${FASTQ2_LIST[idx]}
                    
        done
    else
        echo "Not matched pair data."
    fi
done