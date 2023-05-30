#!/bin/bash
#$ -S /bin/bash
#$ -cwd

scriptPath="/data/project/OPLL/script/11.public"
logPath=$scriptPath"/log"
PROJECTDIR="/data/project/OPLL/0.rnaraw/99.public"



#REF="/home/goldpm1/reference/genome.fa"

for sublog in 2-1.gz 2-2.align; do
    if [ -d $logPath"/"$sublog ]; then
        rm -rf $logPath"/"$sublog
    fi
    if [ ! -d $logPath"/"$sublog ]; then
        mkdir -p $logPath"/"$sublog
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

# GSE186542 (NP), GSE188760 (LF), GSE197172 (MSC), GSE227994 (OB-Oxford), GSE102312 (BM-MSC-MCL), GSE78608 (ENCODE_Osteoblast)

for date in GSE78608; do
    FASTQDIR=$PROJECTDIR"/"$date"/01.fasta"
    BAMDIR=$PROJECTDIR"/"$date"/02.bam"

    if [ ! -d $BAMDIR ]; then
        mkdir -p $BAMDIR
    fi

    FASTQ1=$(ls $FASTQDIR | egrep '_1.fastq.gz')
    FASTQ2=$(ls $FASTQDIR | egrep '_2.fastq.gz')
    FASTQ1_LIST=(${FASTQ1// / })
    FASTQ2_LIST=(${FASTQ2// / })

    echo $FSQT1_LIST

    if [ ${#FASTQ1_LIST[@]} -eq ${#FASTQ2_LIST[@]} ]; then
        for idx in ${!FASTQ1_LIST[@]}; do
            SAMPLE=${FASTQ1_LIST[idx]%_1*}
            SAMPLE_LIST="$SAMPLE_LIST $SAMPLE"
            
            #echo -e "PROJECTDIR : "$PROJECTDIR"\tBAMDIR : "$BAMDIR"\tFASTQDIR : "$FASTQDIR"\tFASTQ1_LIST[idx] : "${FASTQ1_LIST[idx]}"\tFASTQ2_LIST[idx] : "${FASTQ2_LIST[idx]}"\nSAMPLE : "$SAMPLE
            echo $SAMPLE
            
            # 01.gzip
            # qsub -pe smp 1 -e $logPath"/2-1.gz" -o $logPath"/2-1.gz" -N 'gzip_'$SAMPLE \
            #         $scriptPath"/02.STAR_pipe_1.gzip.pairedend.sh" \
            #                 --FASTQ1 ${FASTQDIR}"/"${FASTQ1_LIST[idx]} --FASTQ2 ${FASTQDIR}"/"${FASTQ2_LIST[idx]} 
            
            #02. STAR align each bam
            qsub -pe smp 5 -e $logPath"/2-2.align" -o $logPath"/2-2.align" -hold_jid 'gzip_'$SAMPLE -N 'star_'$SAMPLE \
                $scriptPath"/02.STAR_pipe_2.pairedend.sh" \
                    --PROJECT "OPLL" --PLATFORM "Illumina" --PROJECTDIR $PROJECTDIR --REF $REF --BAMDIR $BAMDIR --FASTQDIR $FASTQDIR \
                    --FASTQ1 ${FASTQ1_LIST[idx]} --FASTQ2 ${FASTQ2_LIST[idx]} --SAMPLE $SAMPLE
            
            # 02. HISAT align]
            # qsub -e $DIR/temp/ -o $DIR/temp/ -N 'ht2_'$SAMPLE $scriptPath"/pipe_HISAT2.sh" \
            #             $PROJECT $DIR $PLATFORM $REF $BAMDIR $DataPath ${FASTQ1_LIST[idx]} ${FASTQ2_LIST[idx]}
                    
        done
    else
        echo "Not matched pair data."
    fi
done

# GSE220630 GSE149167 (Mandible, Maxilla,)   GSE175236 (ENCODE-Osteocyte), GSE69787 (OPLL,CSM)

# for date in GSE69787 ; do
#     FASTQDIR=$PROJECTDIR"/"$date"/01.fasta"
#     BAMDIR=$PROJECTDIR"/"$date"/02.bam"

#     FASTQ=$(ls $FASTQDIR | egrep '.fastq.gz')
#     FASTQ_LIST=(${FASTQ// / })
    
#     for idx in ${!FASTQ_LIST[@]}; do
#         SAMPLE=${FASTQ_LIST[idx]%".fastq.gz"}
#         SAMPLE_LIST="$SAMPLE_LIST $SAMPLE"
#         #echo ${FASTQDIR}"/"${FASTQ_LIST[idx]}

#         # 01.gzip
#         # qsub -pe smp 1 -e $logPath"/2-1.gz" -o $logPath"/2-1.gz" -N 'star1_'$SAMPLE \
#         #         $scriptPath"/02.STAR_pipe_1.gzip.singleend.sh" \
#         #                 --FASTQ ${FASTQDIR}"/"${FASTQ_LIST[idx]}

#         #02. STAR align each bam
#         echo ${FASTQ_LIST[idx]}  ${SAMPLE}
#         qsub -pe smp 5 -e $logPath"/2-2.align" -o $logPath"/2-2.align" -hold_jid 'star1_'$SAMPLE -N 'star2_'$SAMPLE \
#             $scriptPath"/02.STAR_pipe_2.singleend.sh" \
#                 --PROJECT "OPLL" --PLATFORM "Illumina" --PROJECTDIR $PROJECTDIR --REF $REF --BAMDIR $BAMDIR --FASTQDIR $FASTQDIR \
#                 --FASTQ ${FASTQ_LIST[idx]}  --SAMPLE $SAMPLE

#     done
# done