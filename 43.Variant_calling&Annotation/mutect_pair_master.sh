#!/bin/bash
#$ -cwd
#$ -S /bin/bash

CURRENT_PATH=`pwd -P`
logPath=$CURRENT_PATH"/log"

DATA_PATH="/data/project/OPLL/04.WES/02.Align"
PON="/data/public/GATK/gatk-best-practices/somatic-hg38/1000g_pon.hg38.vcf.gz"
#REF="/data/resource/reference/human/UCSC/hg38/WholeGenomeFasta/genome.fa"
REF="/home/goldpm1/reference/genome.fa"
hg="hg38"
gnomad="/data/public/GATK/gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz"
TMP_PATH=${DATA_PATH}"/temp"
INTERVAL="/home/goldpm1/resources/TWIST2_exome/Twist_Exome_RefSeq_targets_added_chrM_hg38.bed"

if [ ! -d $logPath ] ; then
    mkdir $logPath
fi

for sublog in 01.MTcall 02.FMC_HF_RMBLACK 03.vep 04.rescue 06.maf; do
    if [ $logPath"/"$sublog ] ; then
        rm -rf $logPath"/"$sublog
    fi
    if [ ! -d $logPath"/"$sublog ] ; then
        mkdir -p $logPath"/"$sublog
    fi
done


sample_name_list=$(cat ${CURRENT_PATH%/*}"/sample_name.txt")
sample_name_LIST=(${sample_name_list// / })     # array로 만듬


for idx in ${!sample_name_LIST[@]}; do
    Sample_ID=${sample_name_LIST[idx]}        # 230511 230512
    
    for TISSUE in Blood OLF LF Lamina ; do   #Tumor Dura
        CASE_BAM_PATH=${DATA_PATH}"/"${hg}"/"${TISSUE}"/05.Final_bam/"${Sample_ID}"_"${TISSUE}".bam"
        CONTROL_BAM_PATH=${DATA_PATH}"/"${hg}"/Blood/05.Final_bam/"${Sample_ID}"_Blood.bam"
        OUTPUT_VCF_GZ=${DATA_PATH%/*}"/04.mutect/01.raw/"${Sample_ID}"_"${TISSUE}".vcf.gz"
        OUTPUT_FMC_PATH=${DATA_PATH%/*}"/04.mutect/02.PASS/"${Sample_ID}"_"${TISSUE}".MT2.FMC.vcf"
        OUTPUT_FMC_HF_PATH=${DATA_PATH%/*}"/04.mutect/02.PASS/"${Sample_ID}"_"${TISSUE}".MT2.FMC.HF.vcf"
        OUTPUT_FMC_HF_RMBLACK_PATH=${DATA_PATH%/*}"/04.mutect/02.PASS/"${Sample_ID}"_"${TISSUE}".MT2.FMC.HF.RMBLACK.vcf"

        if [ -f ${CASE_BAM_PATH} ]; then     # File이 있어야만 진행

            SAMPLE_THRESHOLD="all"   # "all"
            DP_THRESHOLD=30
            ALT_THRESHOLD=1
            REMOVE_MULTIALLELIC="True"
            PASS="True"
            REMOVE_MITOCHONDRIAL_DNA="True"
            BLACKLIST="/home/goldpm1/resources/RM+SegDup.bed"
            
            for folder in  ${OUTPUT_VCF_GZ%/*}   ${OUTPUT_FMC_PATH%/*}  ${VEP_FMC_HF_PATH%/*}  ; do
                if [ ! -d $folder ] ; then
                    mkdir $folder
                fi
            done
            #01. Mutect2 call
            qsub -pe smp 6 -e $logPath"/01.MTcall" -o $logPath"/01.MTcall" -N 'MT_01.'${Sample_ID}"_"${TISSUE} -hold_jid "doc_"${Sample_ID}"_"${TISSUE} ${CURRENT_PATH}"/mutect_pipe_01.call.sh" \
            --Sample_ID ${Sample_ID} --CASE_BAM_PATH ${CASE_BAM_PATH} --CONTROL_BAM_PATH ${CONTROL_BAM_PATH} \
            --OUTPUT_VCF_GZ ${OUTPUT_VCF_GZ}  \
            --PON ${PON} --REF ${REF} --gnomad ${gnomad} --INTERVAL ${INTERVAL} --TMP_PATH ${TMP_PATH}

            
            #02. FMC & HF & RMBLACK
            qsub -pe smp 5 -e $logPath"/02.FMC_HF_RMBLACK" -o $logPath"/02.FMC_HF_RMBLACK" -N 'MT_02.'${Sample_ID}"_"${TISSUE} -hold_jid  'MT_01.'${Sample_ID}"_"${TISSUE}  ${CURRENT_PATH}"/mutect_pipe_02.FMC_HF_RMBLACK.sh" \
            --Sample_ID ${Sample_ID} --CASE_BAM_PATH ${CASE_BAM_PATH} --CONTROL_BAM_PATH ${CONTROL_BAM_PATH} \
            --OUTPUT_VCF_GZ ${OUTPUT_VCF_GZ} --OUTPUT_FMC_PATH ${OUTPUT_FMC_PATH} --OUTPUT_FMC_HF_PATH ${OUTPUT_FMC_HF_PATH}  --OUTPUT_FMC_HF_RMBLACK_PATH ${OUTPUT_FMC_HF_RMBLACK_PATH} \
            --PON ${PON} --REF ${REF} --gnomad ${gnomad} --INTERVAL ${INTERVAL} --TMP_PATH ${TMP_PATH} \
            --SAMPLE_THRESHOLD ${SAMPLE_THRESHOLD} --DP_THRESHOLD ${DP_THRESHOLD} --ALT_THRESHOLD ${ALT_THRESHOLD} --REMOVE_MULTIALLELIC ${REMOVE_MULTIALLELIC} --PASS ${PASS} --REMOVE_MITOCHONDRIAL_DNA ${REMOVE_MITOCHONDRIAL_DNA} \
            --BLACKLIST ${BLACKLIST}

            # 03. VEP annotation + Nearest gene annotation 
            INPUT_VCF=${OUTPUT_FMC_HF_RMBLACK_PATH}
            VEP_FMC_HF_RMBLACK_PATH=${DATA_PATH%/*}"/04.mutect/03.vep/"${Sample_ID}"_"${TISSUE}".MT2.FMC.HF.RMBLACK.vep.vcf"
            for folder in  ${VEP_FMC_HF_RMBLACK_PATH%/*}  ; do
                if [ ! -d $folder ] ; then
                    mkdir $folder
                fi
            done
            qsub -pe smp 6 -e $logPath"/03.vep" -o $logPath"/03.vep" -N "MT_03."${Sample_ID}"_"${TISSUE} -hold_jid 'MT_02.'${Sample_ID}"_"${TISSUE}  ${CURRENT_PATH}"/mutect_pipe_20.vep.sh" \
            --REF ${REF} --INPUT_VCF ${INPUT_VCF} --OUTPUT_VCF ${VEP_FMC_HF_RMBLACK_PATH}      
        
        fi
    done
done


