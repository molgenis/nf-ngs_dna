#!/bin/bash

set -o pipefail
set -eu
#sampleSheet=!{params.samplesheet}
sampleSheet=!{samplesheet}
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
barcode2FieldIndex=$((${sampleSheetColumnOffsets['project']} + 1))


echo -e "[Data]\nFCID,Lane,Sample_ID,Index,Index2" > IlluminaSamplesheet.csv
awk -v e=${externalSampleIDFieldIndex} -v l=${laneFieldIndex} -v f=${flowcellFieldIndex} -v b1=${barcode1FieldIndex} -v b2=${barcode2FieldIndex} 'BEGIN {FS=","}{OFS=","}{if (NR>1){print $f,$l,$e,$b1,$b2}}' "${sampleSheet}" >> IlluminaSamplesheet.csv
echo "Illumina samplesheet created: IlluminaSamplesheet.csv"