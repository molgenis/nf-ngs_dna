#!/usr/bin/env nextflow

nextflow.enable.dsl=2

log.info """\
         T E S T - N F   P I P E L I N E
         ===================================
         samplesheet  : ${params.samplesheet}
         group        : ${params.group}
         tmpdir       : ${params.tmpdir}
         """
         .stripIndent()

include { create_illumina_samplesheet } from './modules/create_illumina_samplesheet.nf'
include { bcl2fastq } from './modules/bcl2fastq.nf'
include { run_dragen } from './modules/run_dragen.nf'



def split_samples(sample) {
    sample.projectResultsDir=params.tmpDataDir+"/projects/NGS_DNA/"
    return sample
}

workflow {
  Channel.fromPath(params.samplesheet)
	| create_illumina_samplesheet
	| set { ch_samplesheet_check }
	
	ch_samplesheet_check 
	| bcl2fastq
	| set{fastq_processed}

	fastq_processed
	| run_dragen

}
