#!/bin/bash
#$ -cwd
#$ -S /bin/bash


if ! options=$(getopt -o h --long FASTQ:, -- "$@")
then
    echo "ERROR: invalid options"
    exit 1
fi

eval set -- $options

while true; do
    case "$1" in
        -h|--help)
            echo "Usage"
            shift ;;
        --FASTQ)
            FASTQ=$2
            shift 2 ;;
        --)
            shift
            break
    esac
done

gzip ${FASTQ}