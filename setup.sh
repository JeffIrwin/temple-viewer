#!/bin/bash

export PATH=$PATH:"/c/Program Files/qemu/"

mkdir scratch

qemu-img create scratch/tdisk.img 20G
qemu-system-x86_64 -boot d -cdrom scratch/TempleOS.ISO -m 2048 -hda scratch/tdisk.img

