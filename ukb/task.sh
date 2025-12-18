FULLFILE=$1  # full path and .zip extension
#xpath=${FULLFILE%/*} 
xbase=${FULLFILE##*/}
#xfext=${xbase##*.}
xpref=${xbase%.*}

DCM2NIIX=/ess/p33/cluster/groups/imaging/BRAINMINT/toolboxes/dcm2niix/v1.0.20250505/dcm2niix

OUT_NII=$xpref.nii
OUT_JSON=$xpref.json
echo $FULLFILE $OUT_NII $OUT_JSON

rm -rf "${SCRATCH}/dcm"/* "${SCRATCH}/nii"/*

unzip -q "$FULLFILE" -d "${SCRATCH}/dcm" || continue
$DCM2NIIX -o "${SCRATCH}/nii" "${SCRATCH}/dcm" || continue

nii=$(ls "${SCRATCH}/nii"/*.nii 2>/dev/null | tail -n 1 || true)
if [[ -z "${nii}" ]]; then
    echo "ERROR: Missing NIfTI outputs for ${FULLFILE}"
    exit 1
fi

mv $nii "$OUT_NII"
mv ${nii%.*}.json $OUT_JSON
