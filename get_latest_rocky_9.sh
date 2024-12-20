#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status, if an undefined variable is used, or if any command in a pipeline fails
set -euo pipefail

# Define the storage location
storage="${STORAGE:-local-lvm}"

# Check if virt-customize is installed, if not, prompt to install libguestfs-tools package and exit
if ! command -v virt-customize &>/dev/null; then
	echo "virt-customize is not installed. Install libguestfs-tools package."
	exit 1
fi

# Base URL for downloading Rocky Linux images
base_url="https://download.rockylinux.org/pub/rocky/9/images/x86_64/"

# Fetch the image file name from the base URL
image_file=$(wget -qO - "${base_url}" | grep -oP 'Rocky-9-GenericCloud-Base-9.\d-\d{8}.0.x86_64.qcow2(?!\.)')
# Extract the image name from the image file name
image_name=$(echo "${image_file}" | grep -oP 'Rocky-9-GenericCloud-Base-9.\d{1,2}-\d{8}.\d')
# Define the image file name with qemu-guest-agent installed
qemuga_image_file="$(basename "${image_file}" .qcow2)-qemuga.qcow2"

# Check if a VM with the same name already exists, if so, exit
if qm list | grep Rocky-9 | awk '{print $2}' | grep -q -P "^${image_name}\$"; then
	echo "VM with name ${image_name} already exists."
	exit 0
fi

# Download the image and checksum file if they do not exist
if [[ ! -f ${image_file} ]] || [[ ! -f ${image_file}.CHECKSUM ]]; then
	echo "Downloading image and checksum file."
	wget --quiet --no-clobber --continue \
		"${base_url}/${image_file}" "${base_url}/${image_file}.CHECKSUM"
fi

# Verify the checksum of the downloaded image file
sha256sum --quiet -c "${image_file}.CHECKSUM"

# If the image file with the QEMU guest agend does not exist,
# create it and install qemu-guest-agent
if [[ ! -f ${qemuga_image_file} ]]; then
	echo "Installing qemu-guest-agent into image."
	cp "${image_file}" "${qemuga_image_file}"
	virt-customize --quiet --add "${qemuga_image_file}" --install qemu-guest-agent
fi

# Generate a new VM ID
vmid=$(qm list | awk 'NR>1 {print $1}' | sort -n |
	awk -v i=100 '$1!=i{exit} {i++} END{print i}')

# Create a new VM with the specified configuration
qm create "${vmid}" --name "${image_name}" \
	--cpu host --sockets 1 --cores 1 \
	--memory 1024 \
	--rng0 source=/dev/urandom \
	--tpmstate0 "${storage}:1" \
	--bios ovmf \
	--machine q35 \
	--serial0 socket \
	--scsihw virtio-scsi-single \
	--efidisk0 "${storage}:1" \
	--bootdisk scsi0 --boot c \
	--ostype l26 \
	--net0 virtio,bridge=vmbr0 \
	--ide2 "${storage}:cloudinit" \
	--ipconfig0 ip=dhcp,ip6=dhcp \
	--agent enabled=1,type=virtio

# Import the disk image to the VM and configure the disk settings
osdisk=$(qm disk import "${vmid}" "${qemuga_image_file}" "${storage}" | grep -oP "${storage}:.+disk-\d+")
qm set "${vmid}" --scsi0 "${osdisk},iothread=1,cache=writeback,discard=on,ssd=1"
# Convert the VM to a template
qm template "${vmid}"

# Clean up by removing the downloaded and created image files
rm -f "${qemuga_image_file}" "${image_file}" "${image_file}".CHECKSUM
