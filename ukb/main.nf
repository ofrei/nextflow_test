nextflow.enable.dsl = 2

/*
  Usage:
    module load Nextflow/24.04.2
    ls /ess/p33/data/durable/s3-api/ukblake/bulk/20216 | head -n 100 > input_files_list.txt
    nextflow run main.nf -profile tsd \
      --input_list first_n100_T1dcmarchs_text.txt \
      --batch_size 5 \
      --outdir /ess/p33/cluster/ukbio_users/ofrei/recon/dcm2niix
*/

params.input_list = params.input_list
params.outdir     = params.outdir
params.batch_size = params.batch_size ?: 25

params.dcm_root   = '/ess/p33/data/durable/s3-api/ukblake/bulk/20216'

workflow {

  Channel
    .fromPath(params.input_list)
    .splitText()
    .map { it.trim() }
    .filter { it }
    .filter { f ->
        !file("${params.outdir}/${file(f).baseName}.nii").exists()
    }
    .buffer(size: params.batch_size, remainder: true)
    .set { batches }

  PROCESS_BATCH(batches)
}

process PROCESS_BATCH {

  tag { "chunk_${task.index}" }

  publishDir params.outdir, mode: 'copy'

  input:
    val files   // files = list of paths

  output:
    path "*.nii"
    path "*.json"    

  script:
    """
    set -ux

    echo "Processing batch ${task.index} with ${files.size()} files (${files})"

    mkdir -p "\${SCRATCH}/dcm" "\${SCRATCH}/nii"

    for ENTRY in ${files.join(' ')}; do
      /ess/p33/cluster/ukbio_users/ofrei/recon/task.sh "${params.dcm_root}/\$ENTRY"
    done
    """
}
