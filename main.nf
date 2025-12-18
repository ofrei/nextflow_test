nextflow.enable.dsl = 2

params.input_list = params.input_list ?: 'nf_input.txt'
params.outdir     = params.outdir     ?: 'results'
params.batch_size = params.batch_size ?: 5

workflow {

  Channel
    .fromPath(params.input_list)
    .splitText()
    .map { it.trim() }
    .filter { it }
    .map { file(it) }
    // group files into batches of 5
    .buffer(size: params.batch_size, remainder: true)
    .set { batches }

  MD5_BATCH(batches)
}

process MD5_BATCH {

  tag { "batch_${task.index}" }

  publishDir params.outdir, mode: 'copy'

  input:
    val files   // files = list of paths

  output:
    path "*.md5"

  script:
    """
    echo "Processing batch ${task.index} with ${files.size()} files (${files})"

    for f in ${files.join(' ')}; do
      md5sum "\$f" > "\$(basename "\$f").md5"
    done
    """
}

