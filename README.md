# Proxmox Tools

A collection of tools and scripts for managing Proxmox Virtual Environment (VE) servers.

## Features

- Rocky Linux 9 cloud image template creation.

## The Tools

### get_latest_rocky_9.sh

This script automates the process of downloading the latest Rocky Linux 9 image, customizing it with `qemu-guest-agent`, and creating a Proxmox VM template.

#### Prerequisites

- `virt-customize` (part of the `libguestfs-tools` package)
- `wget`
- `sha256sum`

#### Usage

- **`STORAGE`**: Specify the Proxmox storage location (default is `local-lvm`).

Example:

```bash
STORAGE=your-storage ./get_latest_rocky_9.sh
```

#### What the Script Does

- Downloads the latest Rocky Linux 9 cloud image.
- Verifies the image checksum.
- Installs `qemu-guest-agent` into the image.
- Creates a VM template in Proxmox VE with the appropriate configuration.
- Cleans up downloaded files after completion.

#### Notes

- Ensure you have the required permissions to create VMs in Proxmox VE.
- The VM template will be named based on the Rocky Linux image version.
- The script automatically selects the next available VM ID.


## Contributing

Contributions are welcome. Please open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).