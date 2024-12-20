sync:
    rsync get_latest_rocky_9.sh pve:

run: sync
    ssh pve ./get_latest_rocky_9.sh