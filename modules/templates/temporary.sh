#
## dragen.config
#
workdir=/staging/development/
intermediateDir = "${workdir}/tmp/"
referenceDir="${workdir}/reference/"
sequencersDir='/mnt/copperfist-sequencers'
resultsFolder="${workdir}/results/"



#
## create_illumina_samplesheet.sh
#

#!/bin/bash
set -o pipefail
set -eu

workdir=/staging/development/
intermediateDir = "${workdir}/tmp/"
referenceDir="${workdir}/reference/"
sequencersDir='/mnt/copperfist-sequencers'
resultsFolder="${workdir}/results/"
sampleSheet="/staging/development/rawdata/191025_NB501043_0417_AHNLN3BGXC/191025_NB501043_0417_AHNLN3BGXC.csv"


#sampleSheet=!{samplesheet}
declare -a sampleSheetColumnNames=()
declare -A sampleSheetColumnOffsets=()
declare  sampleSheetFieldIndex
declare  sampleSheetFieldValueCount
IFS="," read -r -a sampleSheetColumnNames <<< "$(head -1 "${sampleSheet}")"
#
# Backwards compatibility for "Sample Type" including - the horror - a space and optionally quotes :o.
        #
for (( offset = 0 ; offset < ${#sampleSheetColumnNames[@]} ; offset++ ))
do
 	regex='Sample Type'
    if [[ "${sampleSheetColumnNames[${offset}]}" =~ ${regex} ]]
    then
      	columnName='sampleType'
    else
      	columnName="${sampleSheetColumnNames[${offset}]}"
    fi
	sampleSheetColumnOffsets["${columnName}"]="${offset}"
done
#
# Get sampleType from sample sheet and check if all samples are of the same type.
#
sampleType='' # Default.
externalSampleIDFieldIndex=$((${sampleSheetColumnOffsets['externalSampleID']} + 1))
laneFieldIndex=$((${sampleSheetColumnOffsets['lane']} + 1))
flowcellFieldIndex=$((${sampleSheetColumnOffsets['flowcell']} + 1))
barcode1FieldIndex=$((${sampleSheetColumnOffsets['barcode1']} + 1))
barcode2FieldIndex=$((${sampleSheetColumnOffsets['barcode2']} + 1))


echo -e "[Data]\nFCID,Lane,SampleID,Index,Index2" > "${intermediateDir}/IlluminaSamplesheet.csv"
awk -v e=${externalSampleIDFieldIndex} -v l=${laneFieldIndex} -v f=${flowcellFieldIndex} -v b1=${barcode1FieldIndex} -v b2=${barcode2FieldIndex} 'BEGIN {FS=","}{OFS=","}{if (NR>1){print $f,$l,$e,$b1,$b2}}' "${sampleSheet}" >> "${intermediateDir}/IlluminaSamplesheet.csv"

#
## bcl2fastq.nf
#

#!/bin/bash
set -eu
samplesheet="${intermediateDir}/IlluminaSamplesheet.csv"
workdir=/staging/development/
intermediateDir = "${workdir}/tmp/"
referenceDir="${workdir}/reference/"
sequencersDir='/mnt/copperfist-sequencers'
resultsFolder="${workdir}/results/"
##############
rawdata=$(basename "${samplesheet}" '.csv')
mkdir "${intermediateDir}/${rawdata}"
dragen --bcl-conversion-only true --bcl-input-directory "${sequencers}/${rawdata}/"  --output-directory "${intermediateDir}/${rawdata}"  --sample-sheet "${illuminaSamplesheet}"
##############

#
## run_dragen.sh
#

#!/bin/bash

workdir=/staging/development/
intermediateDir="${workdir}/tmp/"
referenceDir="${workdir}/reference/"
sequencersDir='/mnt/copperfist-sequencers'
resultsFolder="${workdir}/results/"
fastq_list="${intermediateDir}/${rawdata}/Reports/fastq_list.csv"
###############

set -o pipefail
set -eu
rawdata=$(basename $(dirname $(dirname "${fastq_list}"))) 


count=0
while read line 
do
	if [[ "${count}" == '0' ]]
	then
		echo "first line"
	else
		sampleId=$(cut -d "," -f 2 "${line}")

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
		--watchdog-active-timeout 3600 -r "${referenceDir}" \ 
		--intermediate-results-dir "${intermediateDir}/${rawdata}/" \ 
		--output-directory "Analysis/${sampleId}" \ 
		--output-file-prefix "${sampleId}" \ 
		--fastq-list !{fastq_list} \ 
		--fastq-list-sample-id "${sampleId}" \ 
		--enable-variant-caller true \ 
		--combine-samples-by-name true \ 
		--vc-emit-ref-confidence GVCF \ 
		--vc-enable-vcf-output true \ 
		--vc-enable-gatk-acceleration false \ 
		--vc-ml-enable-recalibration false \ 
		--high-coverage-support-mode true
	fi
	
	count='1'
	
done< "!{fastq_list}"

##########