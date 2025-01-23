process run_dragen {

  input: 
  path(fastq_list)

  shell:

	template 'run_dragen.sh'
}