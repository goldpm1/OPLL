#!/bin/bash
#$ -S /bin/bash
#$ -cwd

scriptPath="/home/goldpm1/OPLL/script/03.HTseq"
logPath=$scriptPath"/log"
PROJECTDIR="/home/goldpm1/OPLL"
#GTFPath="/home/goldpm1/resources/gencode.v38.primary_assembly.annotation.gtf"     # Ensembl ID로 나옴
GTFPath="/data/resource/annotation/human/UCSC/hg38/Genes/genes.gtf "       # Gene symbol로 나옴

if [ -d $logPath ]; then
        rm -rf $logPath
fi
if [ ! -d $logPath ]; then
        mkdir -p $logPath
fi


#for date in 220605 220629 220908 221018 221102 22110 221214 230111 230119; do
for date in 230126 230207; do
        FASTQPath=$PROJECTDIR"/0.rnaraw/00.fastq/"$date
        BAMPath=$PROJECTDIR"/0.rnaraw/02.bam/"$date
        MATRIXPath=$PROJECTDIR"/0.rnaraw/04.matrix/"$date

        if [ ! -d $MATRIXPath ]; then
                mkdir -p $MATRIXPath
        fi

        BAM=$(ls $BAMPath | egrep '*.bam')     # ' '로 띄어진 string 형태
        BAM_LIST=(${BAM// / })                   # 이를 배열 (list)로 만듬


        for idx in ${!BAM_LIST[@]}              # idx : 1, 2, 3, ...
        do
                SAMPLE=${BAM_LIST[idx]}
                ID=${BAM_LIST[idx]%.bam*}    # ID :  220629-NORMAL, 220629-OLF, 220908-NORMAL, 221018-NORMAL, 221018-OLF, 221102-NORMAL, 221102-OLF
                echo -e "Date: "$date"\tID: "$ID

                INPUT=$BAMPath"/"$ID".bam"
                OUTPUT=$MATRIXPath"/"$ID".tsv"
                echo -e "Input: "$INPUT"\tOUTPUT: "$OUTPUT
                qsub -pe smp 8 -o $logPath -e $logPath -N "HT_"$ID -hold_jid "star2_"$ID $scriptPath"/htseq_pipe_1.sh" $INPUT $OUTPUT $GTFPath
        done

done