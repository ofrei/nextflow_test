echo $1 $2

FULLFILE=$1  # full path and .zip extension
OUT_NII=$2   # full output path to .nii file with extension

#xpath=${FULLFILE%/*} 
#xbase=${FULLFILE##*/}
#xfext=${xbase##*.}
#xpref=${xbase%.*}

DCM2NIIX=/ess/p33/cluster/groups/imaging/BRAINMINT/toolboxes/dcm2niix/v1.0.20250505/dcm2niix

mkdir -p ${SCRATCH}/dcm
mkdir -p ${SCRATCH}/nii

# for one SLURM job this script can be called on many inputs, so important to clean up.
rm -rf "${SCRATCH}/dcm"/* "${SCRATCH}/nii"/*

unzip -q "$FULLFILE" -d "${SCRATCH}/dcm"
$DCM2NIIX -o "${SCRATCH}/nii" "${SCRATCH}/dcm"

# TBD: check if taking the last series is the right thing to do?
nii=$(ls "${SCRATCH}/nii"/*.nii 2>/dev/null | tail -n 1 || true)
if [[ -z "${nii}" ]]; then
    echo "ERROR: Missing NIfTI outputs for ${FULLFILE}"
    exit 1
fi

mv ${nii%.*}.json ${OUT_NII%.*}.json
mv $nii "$OUT_NII"
