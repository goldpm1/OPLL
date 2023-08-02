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

for sublog in 11.multipleMT 12.vep; do
    if [ $logPath"/"$sublog ] ; then
        rm -rf $logPath"/"$sublog
    fi
    if [ ! -d $logPath"/"$sublog ] ; then
        mkdir -p $logPath"/"$sublog
    fi
done


sample_name_list=$(cat ${CURRENT_PATH%/*}"/sample_name.txt")
sample_name_LIST=(${sample_name_list// / })     # array로 만듬



######################################  MULTIPLE CALL ########################################

for idx in ${!sample_name_LIST[@]}; do
    Sample_ID=${sample_name_LIST[idx]}        # 230511, 230512

    CASE_BAM_PATH_OLF=${DATA_PATH}"/"${hg}"/OLF/05.Final_bam/"${Sample_ID}"_OLF.bam"
    CASE_BAM_PATH_LF=${DATA_PATH}"/"${hg}"/LF/05.Final_bam/"${Sample_ID}"_LF.bam"
    CASE_BAM_PATH_LAMINA=${DATA_PATH}"/"${hg}"/Lamina/05.Final_bam/"${Sample_ID}"_Lamina.bam"
    if [ ! -f ${CASE_BAM_PATH_LAMINA} ]; then     # File이 있어야만 진행
        CASE_BAM_PATH_LAMINA="None"
    fi
    
    
    CONTROL_BAM_PATH=${DATA_PATH}"/"${hg}"/Blood/05.Final_bam/"${Sample_ID}"_Blood.bam"
    
    SAMPLE_THRESHOLD="all"   # "all"
    DP_THRESHOLD=30
    ALT_THRESHOLD=2
    REMOVE_MULTIALLELIC="True"
    PASS="True"
    REMOVE_MITOCHONDRIAL_DNA="True"
    BLACKLIST="/home/goldpm1/resources/RM+SegDup.bed"

    


    ####################################### 3개 다 있는 경우 (OLF, LF, Lamina) #######################################
    if [[ ${CASE_BAM_PATH_LAMINA} != "None" && ${CASE_BAM_PATH_LF} != "None" ]]; then
        echo -e "\n"${Sample_ID}" : OLF, LF, Lamina"

        for NUM in "12" "13" "23"; do        # 12: OLF-LF,      13: OLF-Lamina         23: LF-Lamina
            if [[ ${NUM} == "12" ]]; then
                CASE_BAM_PATH1=${CASE_BAM_PATH_OLF}
                CASE_BAM_PATH2=${CASE_BAM_PATH_LF}
            fi
            if [[ ${NUM} == "13" ]]; then
                CASE_BAM_PATH1=${CASE_BAM_PATH_OLF}
                CASE_BAM_PATH2=${CASE_BAM_PATH_LAMINA}
            fi
            if [[ ${NUM} == "23" ]]; then
                CASE_BAM_PATH1=${CASE_BAM_PATH_LF}
                CASE_BAM_PATH2=${CASE_BAM_PATH_LAMINA}
            fi

            OUTPUT_VCF_GZ=${DATA_PATH%/*}"/04.mutect/01.raw/"${Sample_ID}"_"${NUM}".vcf.gz"
            OUTPUT_FMC_PATH=${DATA_PATH%/*}"/04.mutect/02.PASS/"${Sample_ID}"_"${NUM}".MT2.FMC.vcf"
            OUTPUT_FMC_HF_PATH=${DATA_PATH%/*}"/04.mutect/02.PASS/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.vcf"
            OUTPUT_FMC_HF_RMBLACK_PATH=${DATA_PATH%/*}"/04.mutect/02.PASS/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.RMBLACK.vcf"


            #11. Multiple sample Mutect2 call (FMC, HF, RMBLACK 포함)
            qsub -pe smp 6 -e $logPath"/11.multipleMT" -o $logPath"/11.multipleMT" -N "MT_11."${Sample_ID}"_"${NUM} -hold_jid "doc_"${Sample_ID}"_LF,doc_"${Sample_ID}"_OLF" ${CURRENT_PATH}"/mutect_pipe_11.multipleMT.sh" \
            --Sample_ID ${Sample_ID} \
            --CASE_BAM_PATH1 ${CASE_BAM_PATH1} --CASE_BAM_PATH2 ${CASE_BAM_PATH2}  --NUM ${NUM}  \
            --CONTROL_BAM_PATH ${CONTROL_BAM_PATH} \
            --OUTPUT_VCF_GZ ${OUTPUT_VCF_GZ} --OUTPUT_FMC_PATH ${OUTPUT_FMC_PATH}  --OUTPUT_FMC_HF_PATH ${OUTPUT_FMC_HF_PATH} --OUTPUT_FMC_HF_RMBLACK_PATH ${OUTPUT_FMC_HF_RMBLACK_PATH} \
            --PON ${PON} --REF ${REF} --gnomad ${gnomad} --INTERVAL ${INTERVAL} --TMP_PATH ${TMP_PATH} \
            --SAMPLE_THRESHOLD ${SAMPLE_THRESHOLD} --DP_THRESHOLD ${DP_THRESHOLD} --ALT_THRESHOLD ${ALT_THRESHOLD} --REMOVE_MULTIALLELIC ${REMOVE_MULTIALLELIC} --PASS ${PASS} --REMOVE_MITOCHONDRIAL_DNA ${REMOVE_MITOCHONDRIAL_DNA} \
            --BLACKLIST ${BLACKLIST}

            #12. VEP annotation  +  Nearest gene annotation
            INPUT_VCF=${OUTPUT_FMC_HF_RMBLACK_PATH}
            VEP_FMC_HF_RMBLACK_PATH=${DATA_PATH%/*}"/04.mutect/03.vep/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.RMBLACK.vep.vcf"
            for folder in  ${VEP_FMC_HF_RMBLACK_PATH%/*}  ; do
                if [ ! -d $folder ] ; then
                    mkdir $folder
                fi
            done
            qsub -pe smp 6 -e $logPath"/12.vep" -o $logPath"/12.vep" -N "MT_12."${Sample_ID}"_"${NUM} -hold_jid "MT_11."${Sample_ID}"_"${NUM}  ${CURRENT_PATH}"/mutect_pipe_20.vep.sh" \
            --REF ${REF} --INPUT_VCF ${INPUT_VCF} --OUTPUT_VCF ${VEP_FMC_HF_RMBLACK_PATH}
        done
    fi

    
    # ####################################### 2개만 있는 경우 (OLF, LF) #######################################
    if [[ ${CASE_BAM_PATH_LAMINA} == "None" && ${CASE_BAM_PATH_LF} != "None" ]]; then
        echo -e "\n"${Sample_ID}" : OLF, LF"

        for NUM in "12" ; do        # 12: OLF-LF
            if [[ ${NUM} == "12" ]]; then
                CASE_BAM_PATH1=${CASE_BAM_PATH_OLF}
                CASE_BAM_PATH2=${CASE_BAM_PATH_LF}
            fi

            OUTPUT_VCF_GZ=${DATA_PATH%/*}"/04.mutect/01.raw/"${Sample_ID}"_"${NUM}".vcf.gz"
            OUTPUT_FMC_PATH=${DATA_PATH%/*}"/04.mutect/02.PASS/"${Sample_ID}"_"${NUM}".MT2.FMC.vcf"
            OUTPUT_FMC_HF_PATH=${DATA_PATH%/*}"/04.mutect/02.PASS/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.vcf"
            OUTPUT_FMC_HF_RMBLACK_PATH=${DATA_PATH%/*}"/04.mutect/02.PASS/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.RMBLACK.vcf"


            #11. Multiple sample Mutect2 call (FMC, HF, RMBLACK 포함)
            qsub -pe smp 6 -e $logPath"/11.multipleMT" -o $logPath"/11.multipleMT" -N "MT_11."${Sample_ID}"_"${NUM} -hold_jid "doc_"${Sample_ID}"_LF,doc_"${Sample_ID}"_OLF" ${CURRENT_PATH}"/mutect_pipe_11.multipleMT.sh" \
            --Sample_ID ${Sample_ID} \
            --CASE_BAM_PATH1 ${CASE_BAM_PATH1} --CASE_BAM_PATH2 ${CASE_BAM_PATH2}  --NUM ${NUM}  \
            --CONTROL_BAM_PATH ${CONTROL_BAM_PATH} \
            --OUTPUT_VCF_GZ ${OUTPUT_VCF_GZ} --OUTPUT_FMC_PATH ${OUTPUT_FMC_PATH}  --OUTPUT_FMC_HF_PATH ${OUTPUT_FMC_HF_PATH} --OUTPUT_FMC_HF_RMBLACK_PATH ${OUTPUT_FMC_HF_RMBLACK_PATH} \
            --PON ${PON} --REF ${REF} --gnomad ${gnomad} --INTERVAL ${INTERVAL} --TMP_PATH ${TMP_PATH} \
            --SAMPLE_THRESHOLD ${SAMPLE_THRESHOLD} --DP_THRESHOLD ${DP_THRESHOLD} --ALT_THRESHOLD ${ALT_THRESHOLD} --REMOVE_MULTIALLELIC ${REMOVE_MULTIALLELIC} --PASS ${PASS} --REMOVE_MITOCHONDRIAL_DNA ${REMOVE_MITOCHONDRIAL_DNA} \
            --BLACKLIST ${BLACKLIST}

            #12. VEP annotation  +  Nearest gene annotation
            INPUT_VCF=${OUTPUT_FMC_HF_RMBLACK_PATH}
            VEP_FMC_HF_RMBLACK_PATH=${DATA_PATH%/*}"/04.mutect/03.vep/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.RMBLACK.vep.vcf"
            for folder in  ${VEP_FMC_HF_RMBLACK_PATH%/*}  ; do
                if [ ! -d $folder ] ; then
                    mkdir $folder
                fi
            done
            qsub -pe smp 6 -e $logPath"/12.vep" -o $logPath"/12.vep" -N "MT_12."${Sample_ID}"_"${NUM} -hold_jid "MT_11."${Sample_ID}"_"${NUM}  ${CURRENT_PATH}"/mutect_pipe_20.vep.sh" \
            --REF ${REF} --INPUT_VCF ${INPUT_VCF} --OUTPUT_VCF ${VEP_FMC_HF_RMBLACK_PATH}
        done
    fi


done










 ############################################### RESCUE ########################################

for sublog in 04.rescue 05.sort 06.maf; do
    if [ $logPath"/"$sublog ] ; then
        rm -rf $logPath"/"$sublog
    fi
    if [ ! -d $logPath"/"$sublog ] ; then
        mkdir -p $logPath"/"$sublog
    fi
done



for idx in ${!sample_name_LIST[@]}; do
    Sample_ID=${sample_name_LIST[idx]}        # 230511, 230512

    rm -rf ${DATA_PATH%/*}"/04.mutect/04.rescue/"${Sample_ID}"_"*
    rm -rf ${DATA_PATH%/*}"/04.mutect/05.unique/"${Sample_ID}"_"*
    
    for TISSUE in OLF LF Lamina; do  
        INDIVIDUAL_VCF_PATH=${DATA_PATH%/*}"/04.mutect/03.vep/"${Sample_ID}"_"${TISSUE}".MT2.FMC.HF.RMBLACK.vep.vcf"


        if [ -f ${INDIVIDUAL_VCF_PATH} ]; then     # File이 있어야만 진행
            echo -e "\n"${Sample_ID}"_"${TISSUE}

            INDIVIDUAL_VCF_GZ_PATH=${DATA_PATH%/*}"/04.mutect/03.vep/"${Sample_ID}"_"${TISSUE}".MT2.FMC.HF.RMBLACK.vep.vcf.gz"
            INDIVIDUAL_RESCUED_VCF_PATH=${DATA_PATH%/*}"/04.mutect/04.rescue/"${Sample_ID}"_"${TISSUE}".MT2.FMC.HF.RMBLACK.vep.rescue.vcf"
            INDIVIDUAL_RESCUED_VCF_GZ_PATH=${DATA_PATH%/*}"/04.mutect/04.rescue/"${Sample_ID}"_"${TISSUE}".MT2.FMC.HF.RMBLACK.vep.rescue.vcf.gz"
            INDIVIDUAL_UNIQUE_VCF_PATH=${DATA_PATH%/*}"/04.mutect/05.unique/"${Sample_ID}"_"${TISSUE}".MT2.FMC.HF.RMBLACK.vep.rescue.unique.vcf"
            INDIVIDUAL_UNIQUE_VCF_GZ_PATH=${DATA_PATH%/*}"/04.mutect/05.unique/"${Sample_ID}"_"${TISSUE}".MT2.FMC.HF.RMBLACK.vep.rescue.unique.vcf.gz"

            for dir in ${INDIVIDUAL_RESCUED_VCF_PATH%/*}  ${INDIVIDUAL_UNIQUE_VCF_PATH%/*} ; do
                if [ ! -d ${dir} ] ; then
                    mkdir ${dir}
                fi
            done

            rm -rf ${INDIVIDUAL_RESCUED_VCF_PATH} ${INDIVIDUAL_RESCUED_VCF_GZ_PATH} ${INDIVIDUAL_UNIQUE_VCF_PATH} ${INDIVIDUAL_UNIQUE_VCF_GZ_PATH} 

            ppp='None'

            if [[ ${TISSUE} == "OLF" ]]; then
                for NUM in "12" "13" ; do        # 12: OLF-LF, 13 : OLF-Lamina
                    MULTIPLE_VCF_PATH=${DATA_PATH%/*}"/04.mutect/03.vep/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.RMBLACK.vep.vcf"
                    MULTIPLE_VCF_GZ_PATH=${DATA_PATH%/*}"/04.mutect/03.vep/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.RMBLACK.vep.vcf.gz"            
                
                    if [ -f ${MULTIPLE_VCF_PATH} ]; then     # File이 있어야만 진행
                        # 04.rescue & 05.unique
                        #echo $ppp
                        qsub -pe smp 1 -e $logPath"/04.rescue" -o $logPath"/04.rescue" -N "res."${Sample_ID}"_"${TISSUE}"."${NUM}  -hold_jid ${ppp} ${CURRENT_PATH}"/mutect_pipe_21.rescue.sh" \
                            --Sample_ID ${Sample_ID} --TISSUE ${TISSUE} --NUM ${NUM} \
                            --MULTIPLE_VCF_PATH ${MULTIPLE_VCF_PATH}  --MULTIPLE_VCF_GZ_PATH ${MULTIPLE_VCF_GZ_PATH} \
                            --INDIVIDUAL_VCF_PATH ${INDIVIDUAL_VCF_PATH} --INDIVIDUAL_VCF_GZ_PATH ${INDIVIDUAL_VCF_GZ_PATH} \
                            --INDIVIDUAL_RESCUED_VCF_PATH ${INDIVIDUAL_RESCUED_VCF_PATH} --INDIVIDUAL_RESCUED_VCF_GZ_PATH ${INDIVIDUAL_RESCUED_VCF_GZ_PATH} \
                            --INDIVIDUAL_UNIQUE_VCF_PATH ${INDIVIDUAL_UNIQUE_VCF_PATH} --INDIVIDUAL_UNIQUE_VCF_GZ_PATH ${INDIVIDUAL_UNIQUE_VCF_GZ_PATH}
                        ppp="res."${Sample_ID}"_"${TISSUE}"."${NUM}
                        #sleep 10s
                    fi
                done
            fi

            if [[ ${TISSUE} == "LF" ]]; then
                for NUM in "12"  "23" ; do        # 12: OLF-LF, 23: LF-Lamina
                    MULTIPLE_VCF_PATH=${DATA_PATH%/*}"/04.mutect/03.vep/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.RMBLACK.vep.vcf"
                    MULTIPLE_VCF_GZ_PATH=${DATA_PATH%/*}"/04.mutect/03.vep/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.RMBLACK.vep.vcf.gz"            

                    if [ -f ${MULTIPLE_VCF_PATH} ]; then     # File이 있어야만 진행
                        # 04.rescue & 05.unique
                        qsub -pe smp 1 -e $logPath"/04.rescue" -o $logPath"/04.rescue" -N "res."${Sample_ID}"_"${TISSUE}"."${NUM}  -hold_jid ${ppp} ${CURRENT_PATH}"/mutect_pipe_21.rescue.sh" \
                            --Sample_ID ${Sample_ID} --TISSUE ${TISSUE} --NUM ${NUM} \
                            --MULTIPLE_VCF_PATH ${MULTIPLE_VCF_PATH}  --MULTIPLE_VCF_GZ_PATH ${MULTIPLE_VCF_GZ_PATH} \
                            --INDIVIDUAL_VCF_PATH ${INDIVIDUAL_VCF_PATH} --INDIVIDUAL_VCF_GZ_PATH ${INDIVIDUAL_VCF_GZ_PATH} \
                            --INDIVIDUAL_RESCUED_VCF_PATH ${INDIVIDUAL_RESCUED_VCF_PATH} --INDIVIDUAL_RESCUED_VCF_GZ_PATH ${INDIVIDUAL_RESCUED_VCF_GZ_PATH} \
                            --INDIVIDUAL_UNIQUE_VCF_PATH ${INDIVIDUAL_UNIQUE_VCF_PATH} --INDIVIDUAL_UNIQUE_VCF_GZ_PATH ${INDIVIDUAL_UNIQUE_VCF_GZ_PATH}
                        ppp="res."${Sample_ID}"_"${TISSUE}"."${NUM}
                        #sleep 10s
                    fi
                done
            fi

            if [[ ${TISSUE} == "Lamina" ]]; then
                for NUM in "13"  "23" ; do        # 13: OLF-Lamina, 23: LF-Lamina
                    MULTIPLE_VCF_PATH=${DATA_PATH%/*}"/04.mutect/03.vep/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.RMBLACK.vep.vcf"
                    MULTIPLE_VCF_GZ_PATH=${DATA_PATH%/*}"/04.mutect/03.vep/"${Sample_ID}"_"${NUM}".MT2.FMC.HF.RMBLACK.vep.vcf.gz"            
                
                    if [ -f ${MULTIPLE_VCF_PATH} ]; then     # File이 있어야만 진행
                        # 04.rescue & 05.unique
                        qsub -pe smp 1 -e $logPath"/04.rescue" -o $logPath"/04.rescue" -N "res."${Sample_ID}"_"${TISSUE}"."${NUM}  -hold_jid ${ppp} ${CURRENT_PATH}"/mutect_pipe_21.rescue.sh" \
                            --Sample_ID ${Sample_ID} --TISSUE ${TISSUE} --NUM ${NUM} \
                            --MULTIPLE_VCF_PATH ${MULTIPLE_VCF_PATH}  --MULTIPLE_VCF_GZ_PATH ${MULTIPLE_VCF_GZ_PATH} \
                            --INDIVIDUAL_VCF_PATH ${INDIVIDUAL_VCF_PATH} --INDIVIDUAL_VCF_GZ_PATH ${INDIVIDUAL_VCF_GZ_PATH} \
                            --INDIVIDUAL_RESCUED_VCF_PATH ${INDIVIDUAL_RESCUED_VCF_PATH} --INDIVIDUAL_RESCUED_VCF_GZ_PATH ${INDIVIDUAL_RESCUED_VCF_GZ_PATH} \
                            --INDIVIDUAL_UNIQUE_VCF_PATH ${INDIVIDUAL_UNIQUE_VCF_PATH} --INDIVIDUAL_UNIQUE_VCF_GZ_PATH ${INDIVIDUAL_UNIQUE_VCF_GZ_PATH}
                        ppp="res."${Sample_ID}"_"${TISSUE}"."${NUM}
                        #sleep 10s
                    fi
                done
            fi



        
            # Sort
            qsub -pe smp 1 -e $logPath"/05.sort" -o $logPath"/05.sort" -N "MT_sort."${Sample_ID}"_"${TISSUE} -hold_jid ${ppp} ${CURRENT_PATH}"/mutect_pipe_22.sort.sh" \
                --Sample_ID ${Sample_ID} --TISSUE ${TISSUE} --NUM ${NUM} \
                --MULTIPLE_VCF_PATH ${MULTIPLE_VCF_PATH}  --MULTIPLE_VCF_GZ_PATH ${MULTIPLE_VCF_GZ_PATH} \
                --INDIVIDUAL_VCF_PATH ${INDIVIDUAL_VCF_PATH} --INDIVIDUAL_VCF_GZ_PATH ${INDIVIDUAL_VCF_GZ_PATH} \
                --INDIVIDUAL_RESCUED_VCF_PATH ${INDIVIDUAL_RESCUED_VCF_PATH} --INDIVIDUAL_RESCUED_VCF_GZ_PATH ${INDIVIDUAL_RESCUED_VCF_GZ_PATH} \
                --INDIVIDUAL_UNIQUE_VCF_PATH ${INDIVIDUAL_UNIQUE_VCF_PATH} --INDIVIDUAL_UNIQUE_VCF_GZ_PATH ${INDIVIDUAL_UNIQUE_VCF_GZ_PATH}
            ppp="MT_sort."${Sample_ID}"_"${TISSUE}



            # 06. MAF annotation

            for dir in ${DATA_PATH%/*}"/04.mutect/06.maf/01.shared_yes/" ${DATA_PATH%/*}"/04.mutect/06.maf/02.shared_no/" ; do
                if [ ! -d ${dir} ] ; then
                    mkdir -p ${dir}
                fi
            done

            INPUT_VCF=${INDIVIDUAL_RESCUED_VCF_PATH}
            OUTPUT_MAF=${DATA_PATH%/*}"/04.mutect/06.maf/01.shared_yes/"${Sample_ID}"_"${TISSUE}".MT2.FMC.HF.RMBLACK.vep.maf"
            rm -rf ${DATA_PATH%/*}"/04.mutect/06.maf/01.shared_yes/"${Sample_ID}"_"*
            qsub -pe smp 1 -e $logPath"/06.maf" -o $logPath"/06.maf" -N "MT_maf."${Sample_ID}"_"${TISSUE} -hold_jid ${ppp}  ${CURRENT_PATH}"/mutect_pipe_23.manualmaf.sh" \
            --INPUT_VCF ${INPUT_VCF} --OUTPUT_MAF ${OUTPUT_MAF} --SELECTED_DB "None"

            INPUT_VCF=${INDIVIDUAL_UNIQUE_VCF_PATH}
            OUTPUT_MAF=${DATA_PATH%/*}"/04.mutect/06.maf/02.shared_no/"${Sample_ID}"_"${TISSUE}".MT2.FMC.HF.RMBLACK.vep.maf"
            rm -rf ${DATA_PATH%/*}"/04.mutect/06.maf/01.shared_no/"${Sample_ID}"_"*
            qsub -pe smp 1 -e $logPath"/06.maf" -o $logPath"/06.maf" -N "MT_maf."${Sample_ID}"_"${TISSUE} -hold_jid ${ppp}  ${CURRENT_PATH}"/mutect_pipe_23.manualmaf.sh" \
            --INPUT_VCF ${INPUT_VCF} --OUTPUT_MAF ${OUTPUT_MAF} --SELECTED_DB "None"

        fi
    done
done