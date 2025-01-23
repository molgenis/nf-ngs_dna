process coverage {

    publishDir "$samples.projectResultsDir/coverage", mode: 'copy', overwrite: true
    
    module = ['HTSlib/1.16-GCCcore-11.3.0','BCFtools/1.16-GCCcore-11.3.0','gVCF2BED/1.1.0-GCCcore-11.3.0']

    input: 
    tuple val(samples), path(files)

    output: 
    tuple val(samples), path(coverageOutput), path(coveragePerTarget), path(coverageStatistics)

  shell:
  
  coverageOutput="${samples.externalSampleID}.PseudoExome.CoverageOutput.csv"
  coveragePerTarget="${samples.externalSampleID}.pseudoExome.coveragePerTarget.txt"
  coverageStatistics="${samples.externalSampleID}.incl_TotalAvgCoverage_TotalPercentagebelow10x.txt"

  template 'coverage.sh'

  stub:
  coverageOutput="${samples.externalSampleID}.PseudoExome.CoverageOutput.csv"
  coveragePerTarget="${samples.externalSampleID}.pseudoExome.coveragePerTarget.txt"
  coverageStatistics="${samples.externalSampleID}.incl_TotalAvgCoverage_TotalPercentagebelow10x.txt"

  """
  touch "${coverageOutput}"
  touch "${coveragePerTarget}"
  touch "${coverageStatistics}"
  """

}