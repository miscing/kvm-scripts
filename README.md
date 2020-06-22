# kvm-scripts

Scripts for use with kvm to create vm and maintain snapshots and backups. Basic rundown given below. Since these are primarily for my personal use the dependency list is not comprehensiveand generally there is some tinkering involved. While some scripts are usable, others are meant more as a reference source.


## Basic rundown:
1. Create a thinlvm and place a basic operating system. I used a cloud image and unpacked it into a thinlvm.
2. ADDTIONAL STEP: If you want to customize the image without using cloud-init install it using virt-install and prepair the image for use
3. Create conf directory and files based on example in the project. I also keep other vm specific scripts and files in these folders
4. run `create_vm.sh` (copy or create a symbolic link the script to your path with whatever name you prefer for convenience, I use `addvm`)
5. Place `lvm_snapshots` script in your cron folder, I use cron.hourly but feel free to configurate it to whatever intervals you want.
6. Create `/etc/kvm-scripts/to_snapshot` and add the names of vm's you want to snapshot either manually (syntax: `vg_name/lv_name`) or using option in `create_vm.sh` script

## Dependencies:
* cron
* kvm
* lvm

### Notes:
* there are multiple convenience scripts for the initial process of installation, most are usable but require some knowledge of the procedures.
* `lvm_snapshots` only takes snapshots of lvm's in use
* script `raw_to_thinlv.sh` is locked and meant to be used as reference. Due to the lvm syntax it requires a large amount of inputs. If you do want to use it you can read through it and then remove the early exit line. Personally I'd rewrite/modify it to some have hardcoded information.
