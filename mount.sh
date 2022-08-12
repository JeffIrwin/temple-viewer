#!/bin/bash

# Mount the TempleOS virtual disk in the Windows host filesystem.
#
# The disk cannot be mounted while TempleOS is running.
#
# I have ImDisk at "C:\Windows\System32\imdisk.exe"

#=======================================================================
#
# -a: attach
# -f: file to attach
# -m: mount point
# -v: volume number (1 should be TempleOS C:/ drive)
#
imdisk -a -f /c/git/qemu/templeos/tdisk.img -m T: -v 1

#=======================================================================

