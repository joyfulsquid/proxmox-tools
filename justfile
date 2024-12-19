sync:
    rsync get_rocky.sh pve:

run: sync
    ssh pve ./get_rocky.sh

clean:
    ssh pve rm "Rocky-9-GenericCloud-*.qcow2"
    ssh pve qm delete 114
