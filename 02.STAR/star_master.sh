#!/bin/bash
#$ -S /bin/bash
#$ -cwd

/data/project/OPLL/script

scriptPath="/data/project/OPLL/script/02.STAR"
logPath=$scriptPath"/log"
PROJECTDIR="/data/project/OPLL"



#REF="/home/goldpm1/reference/genome.fa"

for sublog in 01.mkindex 02.align; do
    if [ ! -d $logPath"/"$sublog ]; then
        mkdir -p $logPath"/"$sublog
    fi
done

for subdir in 00.fastq 02.bam; do
    if [ ! -d $PROJECTDIR"/0.rnaraw/"$subdir ]; then
        mkdir -p $PROJECTDIR"/0.rnaraw/"$subdir
    fi
done



# reference path
# HISAT2
#REF=/data/public/HISAT/UCSC_hg19/genome
# STAR
REF="/home/goldpm1/OPLL/0.rnaraw/03.index"
PLATFORM="Illumina"



# [Generating genome indexes   2.index]  #이미 만들어놓음
#qsub -pe smp 3 -e $logPath"/01.mkindex" -o $logPath"/01.mkindex" -N 'star1_'$SAMPLE $scriptPath"/star_pipe_1.sh" $REF

if [ -d $logPath"/02.align" ]; then
    rm -rf $logPath"/02.align"
fi
if [ ! -d $logPath"/02.align" ]; then
    mkdir -p $logPath"/02.align"
fi


#for date in 220605 220629 220908 221018 221102 221107 221214 230111 230119; do
for date in 230126 230207; do
    FASTQPath=$PROJECTDIR"/0.rnaraw/00.fastq/"$date
    BAMPath=$PROJECTDIR"/0.rnaraw/02.bam/"$date

    if [ ! -d $BAMPath ]; then
        mkdir -p $BAMPath
    fi

    FASTQ1=$(ls $FASTQPath | egrep '_1.fastq.gz')
    FASTQ2=$(ls $FASTQPath | egrep '_2.fastq.gz')
    FASTQ1_LIST=(${FASTQ1// / })
    FASTQ2_LIST=(${FASTQ2// / })

    if [ ${#FASTQ1_LIST[@]} -eq ${#FASTQ2_LIST[@]} ]; then
        for idx in ${!FASTQ1_LIST[@]}; do
            SAMPLE=${FASTQ1_LIST[idx]%_1*}
            SAMPLE_LIST="$SAMPLE_LIST $SAMPLE"
            
            echo -e "PROJECTDIR : "$PROJECTDIR"\tBAMPath : "$BAMPath"\tFASTQPath : "$FASTQPath"\tFASTQ1_LIST[idx] : "${FASTQ1_LIST[idx]}"\tFASTQ2_LIST[idx] : "${FASTQ2_LIST[idx]}"\nSAMPLE : "$SAMPLE
            
            
            # [STAR align each bam]
            qsub -pe smp 5 -e $logPath"/02.align" -o $logPath"/02.align" -hold_jid 'star1_'$SAMPLE -N 'star2_'$SAMPLE \
                $scriptPath"/star_pipe_2.sh" \
                    --PROJECT "OPLL" --PLATFORM "Illumina" --PROJECTDIR $PROJECTDIR --REF $REF --BAMPath $BAMPath --FASTQPath $FASTQPath \
                    --FASTQ1 ${FASTQ1_LIST[idx]} --FASTQ2 ${FASTQ2_LIST[idx]} --SAMPLE $SAMPLE
            
            # [HISAT align]
            # qsub -e $DIR/temp/ -o $DIR/temp/ -N 'ht2_'$SAMPLE $scriptPath"/pipe_HISAT2.sh" \
            #             $PROJECT $DIR $PLATFORM $REF $BAMPath $DataPath ${FASTQ1_LIST[idx]} ${FASTQ2_LIST[idx]}
                    
        done
    else
        echo "Not matched pair data."
    fi
done