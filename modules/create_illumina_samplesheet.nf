process create_illumina_samplesheet {

  input: 
  path(samplesheet)

  output:
  path(illuminaSamplesheet)

  shell:
	illuminaSamplesheet="IlluminaSamplesheet.csv"
	template 'create_illumina_samplesheet.sh'

  stub:
  illuminaSamplesheet="IlluminaSamplesheet.csv"

  """
  touch "${illuminaSamplesheet}"
  """

}