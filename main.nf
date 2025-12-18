nextflow.enable.dsl = 2

params.input_list = params.input_list ?: 'nf_input.txt'
params.outdir     = params.outdir     ?: 'results'

workflow {

  Channel
    .fromPath(params.input_list)
    .splitText()
    .map { it.trim() }
    .filter { it }
    .map { file(it) }
    .set { inputs }

  MD5SUM(inputs)
}

process MD5SUM {

  tag { input.baseName }

  publishDir params.outdir, mode: 'copy'

  input:
    path input

  output:
    path "${input.baseName}.md5"

  script:
    """
    md5sum "${input}" > "${input.baseName}.md5"
    """
}

