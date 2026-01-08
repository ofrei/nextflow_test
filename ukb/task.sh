set -e
echo $1 $2

FULLFILE=$1   # full path and .zip extension
DONEFILE=$2   # full output path to .done file (completion flag)

OUT_DIR=${DONEFILE%/*}
OUT_BASE=${DONEFILE##*/}   
OUT_PREF=${OUT_BASE%.*} 

#FULLFILE="/home/user/data/results/file.tar.gz"
#xpath=${FULLFILE%/*}     # /home/user/data/results
#xbase=${FULLFILE##*/}    # file.tar.gz
#xfext=${xbase##*.}       # gz
#xpref=${xbase%.*}        # file.tar  

DCM2NIIX=/ess/p33/cluster/groups/imaging/BRAINMINT/toolboxes/dcm2niix/v1.0.20250505/dcm2niix

mkdir -p ${SCRATCH}/dcm
mkdir -p ${OUT_DIR}/${OUT_PREF}

# for one SLURM job this script can be called on many inputs, so important to clean up.
rm -rf "${SCRATCH}/dcm"/*

unzip -q "$FULLFILE" -d "${SCRATCH}/dcm"
$DCM2NIIX -o "${OUT_DIR}/${OUT_PREF}" "${SCRATCH}/dcm"
touch ${DONEFILE}

