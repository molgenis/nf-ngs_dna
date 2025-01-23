#!/bin/bash

set -o pipefail
set -eu
rawdata=$(basename $(dirname $(dirname "!{fastq_list}"))) 


lines=()
lines=( $(awk 'BEGIN {FS=","}{if (NR>1){print $2}}' "!{fastq_list}" | sort | uniq) )


for i in "${lines[@]}"
do
	firstHit=$(grep "${i}" "!{fastq_list}" | head -1)
	rgid=$(echo "${firstHit}" | awk 'BEGIN {FS=","}{print $1}')
	sampleId=$(echo "${firstHit}" | awk 'BEGIN {FS=","}{print $2}')
	r1=$(echo "${firstHit}" | awk 'BEGIN {FS=","}{print $5}')
	r2=$(echo "${firstHit}" | awk 'BEGIN {FS=","}{print $6}')
	
	mkdir "${params.resultsDir}/Analysis/${sampleId}"
	dragen -f \
	--enable-duplicate-marking true \
	--enable-map-align-output true \
	--enable-bam-indexing true \
	--read-trimmers polyg,quality,adapter \
	--soft-read-trimmers none \
	--trim-adapter-read1 /opt/edico/config/adapter_sequences.fasta \ 
	--trim-adapter-read2 /opt/edico/config/adapter_sequences.fasta \ 
	--trim-min-quality 20 \ 
	--trim-min-length 20 \ 
	-1 "${r1}" \
	-2 "${r2}" \
	--RGID "${rgid}"
	--RGSM "${sampleId}"
	--watchdog-active-timeout 3600 -r "${params.referenceDir}" \ 
	--intermediate-results-dir "${params.intermediateDir}/${rawdata}/" \ 
	--output-directory "${params.resultsDir}/${rawdata}/Analysis/${sampleId}" \ 
	--output-file-prefix "${sampleId}" \ 
	--enable-variant-caller true \ 
	--combine-samples-by-name true \ 
	--vc-emit-ref-confidence GVCF \ 
	--vc-enable-vcf-output true \ 
	--vc-enable-gatk-acceleration false \ 
	--vc-ml-enable-recalibration false \ 
	--high-coverage-support-mode true
done	
