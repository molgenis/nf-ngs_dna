process bcl2fastq {

  input: 
  path(illuminaSamplesheet)

  output:
  path(fastq_list)

  shell:
		
	'''
	rawdata=$(basename "${params.samplesheet}" '.csv')
	mkdir "${params.intermediateDir}/${rawdata}"
	dragen -f --bcl-conversion-only true --bcl-input-directory "${params.sequencersDir}/${rawdata}/"  --output-directory "${params.intermediateDir}/${rawdata}"  --sample-sheet "${illuminaSamplesheet}"
	
	'''
	fastq_list="${params.intermediateDir}/${rawdata}/Reports/fastq_list.csv"

}