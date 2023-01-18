#!/usr/bin/env bash

if [ "$FLOCKED" != "yes" ]; then
  flock --exclusive --nonblock "$0" env FLOCKED=yes "$0"
  exit $?
fi

source /etc/profile.d/freesurfer.sh

DICOM_IN_DIR="$HOME/dicom_in"

find "$DICOM_IN_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r directory; do
 freesurfer_subject="fs_$( basename "$directory" )"

 echo "Processing folder \"$directory\""


 # sanitize file names
 # sometimes the files are not even ending on '.DCM'
 find . '(' -iname 'I*\.[0-9][0-9][0-9]' -or -iname 'I*\.VIM' ')' -exec mv '{}' '{}.DCM' ';'
 # sometimes they just have unsupported characters or end on '.VIM.DCM' instead of '.001.DCM'
 for f in "$directory"/*; do mv -v "$f" "$(echo "$f" |tr -cd '/.A-Za-z0-9_-'|sed 's/.VIM.DCM$/.001.DCM/gi')"; done

 # DICOM to MGH/MGZ format
 if [ ! -e "$SUBJECTS_DIR/$freesurfer_subject/mri/orig/001.mgz" ]; then
   recon-all -threads 8 -s "$freesurfer_subject" -i "$directory/"*".001.DCM" || exit 2
 fi

 # allllll
 recon-all -cw256 -threads 8 -s "$freesurfer_subject" -all || exit 3
 #recon-all -threads 8 -s "$freesurfer_subject" -all || exit 3
 #recon-all -threads 8 -s "$freesurfer_subject" -autorecon1 || exit 3

 # generate combined grey matter
 mri_concat --combine --i "$SUBJECTS_DIR/$freesurfer_subject/mri/lh.ribbon.mgz" --i "$SUBJECTS_DIR/$freesurfer_subject/mri/rh.ribbon.mgz" --o "$SUBJECTS_DIR/$freesurfer_subject/mri/combined-grey.ribbon.mgz"

 # convert stuff to nii
 mkdir -p "$SUBJECTS_DIR/$freesurfer_subject/nii"
 #find "$SUBJECTS_DIR/$freesurfer_subject/mri/" -name "*.mgz" -type f
 (
   echo "$SUBJECTS_DIR/$freesurfer_subject/mri/orig/001.mgz"
   echo "$SUBJECTS_DIR/$freesurfer_subject/mri/T1.mgz"
   echo "$SUBJECTS_DIR/$freesurfer_subject/mri/brain.mgz"
   echo "$SUBJECTS_DIR/$freesurfer_subject/mri/brainmask.mgz"
   echo "$SUBJECTS_DIR/$freesurfer_subject/mri/combined-grey.ribbon.mgz"
 ) | while read -r f; do
   mri_convert "$f" "$SUBJECTS_DIR/$freesurfer_subject/nii/$(basename "$f" .mgz).nii"
 done

 # move DICOMs from _in to _out
 mv "$directory" "$SUBJECTS_DIR/$freesurfer_subject/dicom"

done


echo "Done!"
echo "Press Enter to close"
read

