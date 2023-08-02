#!/bin/bash
#$ -S /bin/bash
#$ -cwd

scriptPath="/data/project/OPLL/script/03.HTseq"
logPath=$scriptPath"/log"
PROJECTDIR="/data/project/OPLL"
#GTFPath="/home/goldpm1/resources/gencode.v38.primary_assembly.annotation.gtf"     # Ensembl ID로 나옴
GTFPath="/data/resource/annotation/human/UCSC/hg38/Genes/genes.gtf "       # Gene symbol로 나옴

if [ -d $logPath ]; then
        rm -rf $logPath
fi
if [ ! -d $logPath ]; then
        mkdir -p $logPath
fi


#for date in 220605 220629 220908 221018 221102 221107 221214 230111 230119 230126 230207 230222 230316 230511 230512; do
for date in 230621 230622 230623; do
        BAM_DIR=${PROJECTDIR}"/01.bulkRNA/02.bam/"${date}
        MATRIX_DIR=${PROJECTDIR}"/01.bulkRNA/04.matrix/"${date}

        if [ ! -d ${MATRIX_DIR} ]; then
                mkdir -p ${MATRIX_DIR}
        fi

        BAM=$(ls $BAM_DIR | egrep '*.bam')     # ' '로 띄어진 string 형태
        BAM_LIST=(${BAM// / })                   # 이를 배열 (list)로 만듬


        for idx in ${!BAM_LIST[@]}              # idx : 1, 2, 3, ...
        do
                SAMPLE=${BAM_LIST[idx]}
                ID=${BAM_LIST[idx]%.bam*}    # ID :  220629-LAMINA, 220629-OLF, 220908-LAMINA, 221018-LAMINA, 221018-OLF, 221102-LAMINA, 221102-OLF
                echo -e "Date: "${date}"\tID: "${ID}

                INPUT=${BAM_DIR}"/"${ID}".bam"
                OUTPUT=${MATRIX_DIR}"/"${ID}".tsv"
                echo -e "Input: "${INPUT}"\tOUTPUT: "${OUTPUT}
                qsub -pe smp 8 -o ${logPath} -e ${logPath} -N "HT_"${ID} -hold_jid "star2_"${ID} ${scriptPath}"/htseq_pipe_1.sh" ${INPUT} ${OUTPUT} ${GTFPath}
        done

done