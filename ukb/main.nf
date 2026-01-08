/*
  Usage:
    module load Nextflow/24.04.2

    # repeat the same for 20220 (T2 FLAIR)
    outdir="/ess/p33/scratch/no-backup/projects/ukbio/dcm2niix"
    for fieldid in "20216" "20220"; do
        dir="/ess/p33/data/durable/s3-api/ukblake/bulk/${fieldid}"

        ls "$dir" | head -n 200000 | while IFS= read -r f; do
            in="$dir/$f"
            out="$outdir/"${f%.*}".done"
            echo -e "$in\t$out"
         done > input_list_${fieldid}.txt

    done

    cat input_list_20216.txt > input_list_20216_20220.txt
    cat input_list_20220.txt >> input_list_20216_20220.txt

    nextflow run main.nf -profile tsd \
      --input_list /ess/p33/cluster/ukbio_users/ofrei/recon/input_list_20216_20220.txt \
      --task_script /ess/p33/cluster/ukbio_users/ofrei/recon/task.sh \

*/

nextflow.enable.dsl = 2

params.input_list = params.input_list
params.task_script = params.task_script
params.batch_size = params.batch_size ?: 25

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

  script:
"""
set -eux

# Write pairs to a TSV (robust, space-safe)
cat << 'EOF' > pairs.tsv
${batch.collect { "${it[0]}\t${it[1]}" }.join('\n')}
EOF

while IFS=\$'\\t' read -r in out; do
  echo "Processing \$in -> \$out"
  if ! ${params.task_script} "\$in" "\$out"; then
    echo "Skipping failed pair:" "\$in" -> "\$out"
  fi
done < pairs.tsv

"""
}
