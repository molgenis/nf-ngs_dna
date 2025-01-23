#!/bin/bash

set -eu
PULLREQUEST=$1

checkout='nf_ngs_dna'
pipeline='nf_ngs_dna'

TMPDIRECTORY='/groups/umcg-gst/tmp0'
GS_RUN='105856-001'
PROJECT="GS_001-WGS_v1"
WORKDIR="${TMPDIRECTORY}/tmp/${pipeline}/betaAutotest/"
TEMP="${WORKDIR}/temp"
## cleanup data to get new data
echo "cleaning up.."
rm -rvf "${TMPDIRECTORY}/${GS_RUN}/" "${TMPDIRECTORY}/Samplesheets/GS_001A-WGS_v1.csv" "${TMPDIRECTORY}/Samplesheets/NGS_DNA/${PROJECT}.csv" "${TMPDIRECTORY}/projects/NGS_DNA/${PROJECT}" "${TMPDIRECTORY}/logs/${PROJECT}"

## retreive data in tmp directory
if [[ "${checkout}" == "${pipeline}" ]]
then
	echo "new pull request for nf_ngs_dna, using default NGS_Automated to get the data from the transfer server"
	rm -rf "${WORKDIR}"
	mkdir -p "${WORKDIR}"

	cd "${WORKDIR}"
	git clone "https://github.com/molgenis/${pipeline}.git"

	cd "${pipeline}" || exit
	git fetch --tags --progress "https://github.com/molgenis/${pipeline}/" +refs/pull/*:refs/remotes/origin/pr/*
	COMMIT=$(git rev-parse refs/remotes/origin/pr/${PULLREQUEST}/merge^{commit})
	echo "checkout commit: COMMIT"
	git checkout -f "${COMMIT}"

	mv * ../
	cd ..
	rm -rf "${pipeline}"
## copy samplesheet to ${TMPDIRECTORY}/Samplesheets/GS_001A-WGS_v1.csv
cp -v "${WORKDIR}/test/GS_001A-WGS_v1.csv" "${TMPDIRECTORY}/Samplesheets/"

rm -rf "${TMPDIRECTORY}/logs/${GS_RUN}/"

## get data from transfer server
var=$(crontab -l | grep PullAndProcessGsAnalysisData.sh | grep -o -P 'module(.+)')
eval ${var::-1} || {
	echo "something went wrong during the PullAndProcessGsAnalysisData step"
	exit 1
}
echo "DONE with pulling/processing, now starting the pipeline"
module load NGS_Automated
module load ${pipeline}/betaAutotest

startNextflowDragenPipeline.sh -g umcg-gst

mkdir -p "${TEMP}"
## Some tests to see whether the pipeline ran successfully
## check if captured file exists
if [[ ! -f "${TMPDIRECTORY}/projects/NGS_DNA/${PROJECT}/run01/results/variants/1111111_123456_HG001_0000000_GS001A_WGS_000001_12348765.captured.vcf.gz" ]]
then
	echo "variants/1111111_123456_HG001_0000000_GS001A_WGS_000001_12348765.captured.vcf.gz does not exist"
	exit 1
fi
#check if concordanceCheck made the correct calls
if [[ ! -f "${TMPDIRECTORY}/projects/NGS_DNA/${PROJECT}/run01/results/concordanceCheckSnps/1111111_123456_HG001_0000000_GS001A_WGS_000001_12348765.concordanceCheckCalls.vcf" ]]
then
	echo "1111111_123456_HG001_0000000_GS001A_WGS_000001_12348765.concordanceCheckCalls.vcf does not exist"
	exit 1
else
	## check if the variants are called
	grep -v '^#' "${TMPDIRECTORY}/projects/NGS_DNA/${PROJECT}/run01/results/concordanceCheckSnps/1111111_123456_HG001_0000000_GS001A_WGS_000001_12348765.concordanceCheckCalls.vcf" | awk 'BEGIN {FS="\t"}{OFS="\t"}{print $1,$2,$3,$4,$5,$10}' > "${TEMP}/concordanceCheckCalls.vcf"
	diffInConcordance='no'
	diff -q "${WORKDIR}/test/trueConcordanceCheckCalls.vcf" "${TEMP}/concordanceCheckCalls.vcf" || diffInConcordance='yes'

	if [[ "${diffInConcordance}" == 'yes' ]]
	then
		echo "There are some differences in the concordanceCheckCalls.vcf file"
		echo "TRUE:"
		cat "${WORKDIR}/test/trueConcordanceCheckCalls.vcf"
		echo -e "\n\n NEW FILE:"
		cat "${TEMP}/concordanceCheckCalls.vcf"
		exit 1
	fi
fi

# check if .seg.bw file is there
if [[ ! -f "${TMPDIRECTORY}/projects/NGS_DNA/${PROJECT}/run01/results/variants/cnv/1111111_123456_HG001_0000000_GS001A_WGS_000001_12348765.seg.bw" ]]
then
	echo "variants/cnv/1111111_123456_HG001_0000000_GS001A_WGS_000001_12348765.seg.bw does not exist"
	exit 1
fi

# check if stats file column is converted correctly
if [[ ! -f "${TMPDIRECTORY}/projects/NGS_DNA/${PROJECT}/run01/results/qc/stats.tsv" ]]
then
	echo "qc/stats.tsv does not exist"
	exit 1
else
	if [[ $(awk '{ if (NR>1){ print $1} }' "${TMPDIRECTORY}/projects/NGS_DNA/${PROJECT}/run01/results/qc/stats.tsv") != '1111111_123456_HG001_0000000_GS001A_WGS_000001_12348765' ]]
	then
		echo "renaming is not done properly!"
		echo -e "The first column of ${TMPDIRECTORY}/projects/NGS_DNA/${PROJECT}/run01/results/qc/stats.tsv should have been:\n1111111_123456_HG001_0000000_GS001A_WGS_000001_12348765, but it is:["
		awk '{if (NR>1){print $1}}' "${TMPDIRECTORY}/projects/NGS_DNA/${PROJECT}/run01/results/qc/stats.tsv"
		echo "]"
		exit 1
	fi
fi

echo -e "\n Test succeeded!!\n"
fi
