Freesurfer is installed in /usr/local/freesurfer/7.1.1-1 and sourced via /etc/profile.d/freesurfer.sh

# rename dicom files
DICOM_DIR="dicom_upload"
for f in "$DICOM_DIR"/*; do mv -v "$f" "$(echo "$f" |tr -cd '/.A-Za-z0-9_-'|sed 's/.VIM.DCM$/.001.DCM/gi')"; done

# dicom to volume
DICOM_DIR="dicom_upload"
recon-all -threads 8 -s bert1337 -i "$DICOM_DIR"/*.001.DCM

# autorecon1 (oder was auch immer)
recon-all -threads 8 -s bert1337 -autorecon1

# allllll
recon-all -threads 8 -s bert1337 -all


