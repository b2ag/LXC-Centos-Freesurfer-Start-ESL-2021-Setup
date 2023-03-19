# What is this?

This is the Start-ESL 2021 Freesurfer-Setup repository containing documentation in form of ansible tasks to assist with deployment and configuration of Freesurfer.

You have to bring your own LXC (Linux Containers) virtualized Centos 8 or similar.

# Preparing MRT data to be used by Freesurfer

## Sanitizing DICOM files

       # sometimes the files are not even ending on '.DCM'
       find . '(' -iname 'I*\.[0-9][0-9][0-9]' -or -iname 'I*\.VIM' ')' -exec echo mv '{}' '{}.DCM' ';'
       # remove unsupported characters and rename '*.VIM.DCM' to '*.001.DCM'
       for f in /my-dicom-folder-path/*; do
         mv -v "$f" "$(echo "$f" |tr -cd '/.A-Za-z0-9_-'|sed 's/.VIM.DCM$/.001.DCM/gi')"; 
       done

## Generating MGH/MGZ-File

> The .mgh file format is used to store high-resolution structural data and other data which are to be overlaid on the high-resolution structural volume. A .mgz (or .mgh.gz) file is a .mgh file that has been compressed with ZLib. 

Only give the first file of a DICOM file set. Freesurfer will find the others.

    recon-all -s mysubjectname -i /my-dicom-folder-path/*.001.DCM

There is a manual approach by creating the folder `subjid/mri/orig` and generating the `001.mgz` file with the following commands. Again only use first file as argument. Don't do one argument per file! Already done that. It explodes.

    mkdir -p subjid/mri/orig
    mri_convert /my-dicom-folder-path/*.001.DCM

# Running Freesurfer

## Docker

    docker run -v /srv/freesurfer/subjects:/usr/local/freesurfer/subjects -v /home/b2ag/freesurfer-test:/freesurfer-test -it freesurfer/freesurfer:7.1.1

## MacOS

- XQuartz X-Window-Server für MacOS downloaden und installieren

        wget "https://github.com/XQuartz/XQuartz/releases/download/XQuartz-2.8.1/XQuartz-2.8.1.dmg"
        scp XQuartz-2.8.1.dmg ep-jobs-1:

    Instalieren und so muss man klicken. ist ja ein mac...

- Freesurfer für MacOS downloaden und installieren
  
        pushd ansible/files; wget "https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.1.1/freesurfer-darwin-macOS-7.1.1.pkg"; popd
        scp freesurfer-darwin-macOS-7.1.1.pkg ep-jobs-1:

    Instalieren und so muss man klicken. ist ja ein mac...


## CentOS

- Create a LXContainer in Proxmox with template "centos-8-default" version 20201210

        [root@ep-ct66465021 ~]#  cat /etc/centos-release
        CentOS Linux release 8.5.2111

- Configure proxy server to download packages (maybe not needed, depends on your network)

    edit `/etc/dnf/dnf.conf`

        vi /etc/dnf/dnf.conf 

    and add working proxy server

    > proxy=http://epm-5e4b656c:42342/

- Install OpenSSH server package

        dnf install openssh-server

- Enable and start SSH server

        systemctl enable --now sshd

- Now Ansible can finish the deployment

        pushd ansible/files; wget 'https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.1.1/freesurfer-CentOS8-7.1.1-1.x86_64.rpm'; popd
        ansible-galaxy install -r requirements.yml

    Comma at the end of IP address for the inventory argument is mandatory!

        ansible-playbook --inventory '10.24.15.213,' -v freesurfer.yml



