#!/bin/bash
#$ -S /bin/bash
#$ -cwd

scriptPath="/data/project/OPLL/script/11.public"
logPath=$scriptPath"/log"
PROJECTDIR="/data/project/OPLL/0.rnaraw/99.public"

#GTFPath="/home/goldpm1/resources/gencode.v38.primary_assembly.annotation.gtf"     # Ensembl ID로 나옴
GTFPath="/data/resource/annotation/human/UCSC/hg38/Genes/genes.gtf "       # Gene symbol로 나옴


#REF="/home/goldpm1/reference/genome.fa"

for sublog in 3-1.htseq; do
    if [ -d $logPath"/"$sublog ]; then
        rm -rf $logPath"/"$sublog
    fi
    if [ ! -d $logPath"/"$sublog ]; then
        mkdir -p $logPath"/"$sublog
    fi
done


## GSE78608 (ENCODE_Osteoblast)
### GSE188760 (O2, C2, 4개), GSE197172 (BM-MSC, 3개), GSE186542 (NP, 6개), GSE220630 (Fibula, 5개), GSE149167 (maxilla, mandible, tibia), GSE175236 (ENCODE Osteocyte), GSE69787(OPLL, Lig)

for date in GSE78608; do
        BAMDIR=$PROJECTDIR"/"$date"/02.bam"
        MATRIXDIR=$PROJECTDIR"/"$date"/03.matrix"

        if [ ! -d $MATRIXDIR ]; then
                mkdir -p $MATRIXDIR
        fi

        BAM=$(ls $BAMDIR | egrep '*.bam')     # ' '로 띄어진 string 형태
        BAM_LIST=(${BAM// / })                   # 이를 배열 (list)로 만듬


        for idx in ${!BAM_LIST[@]}              # idx : 1, 2, 3, ...
        do
                SAMPLE=${BAM_LIST[idx]}
                ID=${BAM_LIST[idx]%.bam*}    # ID :  CSM_2 ....
                echo -e "\nDate: "$date"\tID: "$ID

                INPUT=$BAMDIR"/"$ID".bam"         # /data/project/OPLL/0.rnaraw/99.public/GSE188760/02.bam/CSM_2.bam
                OUTPUT=$MATRIXDIR"/"$ID".tsv"
                #echo -e "Input: "$INPUT"\tOUTPUT: "$OUTPUT
                #qsub -pe smp 8 -o $logPath"/3-1.htseq" -e $logPath"/3-1.htseq" -N "HT_"$ID -hold_jid "star_"$ID $scriptPath"/03.HTseq_pipe.sh" $INPUT $OUTPUT $GTFPath
        done

done