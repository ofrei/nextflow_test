/*
  Usage:
    module load Nextflow/24.04.2

    # repeat the same for 20220 (T2 FLAIR)
    dir="/ess/p33/data/durable/s3-api/ukblake/bulk/20216"
    outdir="/ess/p33/cluster/ukbio_users/ofrei/recon/dcm2niix"

    ls "$dir" | head -n 10000 | while IFS= read -r f; do
      in="$dir/$f"
      out="$outdir/"${f%.*}".nii"
      echo -e "$in\t$out"
    done > input_list_20216.txt

    nextflow run main.nf -profile tsd \
      --input_list /ess/p33/cluster/ukbio_users/ofrei/recon/input_list_20216.txt \
      --task_script /ess/p33/cluster/ukbio_users/ofrei/recon/task.sh \

*/

nextflow.enable.dsl = 2

params.input_list = params.input_list
params.task_script = params.task_script
params.batch_size = params.batch_size ?: 10

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

  PROCESS_BATCH(batches)
}

process PROCESS_BATCH {

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
