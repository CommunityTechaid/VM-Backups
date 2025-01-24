#! /bin/bash
# Usage: 
#      Backup-script.sh
#
# Description:
#      Script to automatically back up VMs
#      As well as truncate number of backups
#
# Options:
#      None at the moment
#
# Last updated:
#      2025/01/24
#
# Caveats:
#      - Needs initial backup xml template from Virsh 
#        for correct disk backup and target editing
#
# TODO:
#      - Add arg parsing to enable XML template generation
#      - Add arg for manual use (removed sleep / spinner for .service use)
#
#########################################################

### Varibles ###

vm_store_root=/mnt/VM-BackUps
xml_template_folder=$vm_store_root/BackupXMLTemplates
number_to_keep=4


### Functions ###

function generate_xmls_for_backup {
    sudo mkdir -p $xml_template_folder

    vm_list=($(sudo virsh list --all | tail -n+3 | tr -s ' ' | cut -d " " -f 3))

    for vm in "${vm_list[@]}"; do
        # Create scratch file for XMLs to avoid file permission issues
        scratch_file=$(mktemp)

        echo "Starting backup for $vm"
        sudo virsh backup-begin $vm

        echo "Getting XML for backup for $vm"
        sudo virsh backup-dumpxml $vm > $scratch_file

        echo "Aborting backup of $vm"
        sudo virsh domjobabort --domain $vm

        # Move scratch to permanent file
        sudo mv $scratch_file $vm_store_root/BackupXMLTemplates/$vm-template.xml

        done
}



function run_backups {
    xml_list=($(ls $xml_template_folder))

    # run in series to avoid slow downs due to slow destination write speeds
    for xml in "${xml_list[@]}";
        do
        # Truncate xml to get vm name
        vm_name=${xml//"-template.xml"/}

        # Ensure folder for backup exists
        sudo mkdir -p $vm_store_root/$vm_name

        # Create scratch file to edit
        temp_version=$(mktemp)

        # Copy template to scratch
        cp $xml_template_folder/$xml $temp_version

        # Remove mention of index (is output only: https://stackoverflow.com/questions/76252019/virsh-begin-backup-unable-to-validate-doc-domainbackup-rng)

        sed -i "s/ index='[[:digit:]]'//" $temp_version

        # Create target string
        target=$vm_store_root/$vm_name/$vm_name-$(date '+%Y%m%d').qcow2

        # Replace backup target with actual target
        perl -i -pe "s/(?<=<target file=).*(?=\/>)/\'${target//\//\\/}\'/g" $temp_version

        # Start backup
        echo "Starting backup for $vm_name"
        sudo virsh backup-begin $vm_name $temp_version

        # Wait for backup to complete     
        # Commented this out 'coz it was messing up usage in .service context
        # local -a marks=( '/' '-' '\' '|' )
        while [ "$(sudo virsh domjobinfo $vm_name | grep 'Job type:' | awk '{ print $3 }')" != "None" ];
            do
        #         printf '%s\r' "${marks[i++ % ${#marks[@]}]}"
                sleep 5
            done




        # Keep only the most recent 4 files
        # find - because ls parsing is a nightmare
        #     -maxdepth 1 > look only 1 folder deep
        #    -type f > return files
        #    -printf '%Ts\t%P\n' > format the output as timestamp \tab filename \newline
        # sort - sorts based on timestamp
        # head - returns everything but the 4 newest
        # cut - dumps the timestamp and keeps just the filename
        # xargs - then runs rm on that filename, the -f silences issues if file doesn't exist or fewer than expect files.

        find $vm_store_root/$vm_name -maxdepth 1 -type f -printf '%Ts\t%P\n' | sort -n | head -n -$number_to_keep | cut -f 2- | xargs rm -f

        done
}


### Do the thing ###
# generate_xmls_for_backup
run_backups
