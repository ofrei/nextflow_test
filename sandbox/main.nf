nextflow.enable.dsl = 2

params.input_list = params.input_list ?: 'nf_input.txt'
params.outdir     = params.outdir     ?: 'results'
params.batch_size = params.batch_size ?: 5
params.task_script = params.task_script ?: '/home/oleksanf/github/ofrei/nextflow_test/sandbox/task.sh'

workflow {

  Channel
    .fromPath(params.input_list)
    .splitText()
    .map { it.trim() }
    .filter { it }
    .map { line ->
        def (inPath, outPath) = line.split('\t')
        tuple( file(inPath), file(outPath) )
    }
    .filter { inFile, outFile ->
        !outFile.exists()
    }
    .buffer(size: params.batch_size, remainder: true)
    .set { batches }

  MD5_BATCH(batches)
}

process MD5_BATCH {

  tag { "batch_${task.index}" }

  input:
    val batch   // list of (input, output) Path pairs

  output:
    path ".done"

  script:
"""
set -eux

# Write pairs to a TSV (robust, space-safe)
cat << 'EOF' > pairs.tsv
${batch.collect { "${it[0]}\t${it[1]}" }.join('\n')}
EOF

while IFS=\$'\\t' read -r in out; do
  echo "Processing \$in -> \$out"
  ${params.task_script} "\$in" "\$out"
done < pairs.tsv

touch .done
"""
}
