#!/bin/bash

export PATH=$PATH:"/c/Program Files/qemu/"

export QEMU_AUDIO_DRV="coreaudio"

#qemu-system-x86_64 tdisk.img -m 2048 -usbdevice tablet
#qemu-system-x86_64 tdisk.img -m 2048 -soundhw pcspk
#qemu-system-x86_64 tdisk.img -m 2048 -machine pcspk-audiodev=pcspk
#qemu-system-x86_64 tdisk.img -m 2048 -audiodev coreaudio,id=id

#qemu-system-x86_64 tdisk-test.img -m 2048 -audiodev coreaudio,id=myid -machine pcspk-audiodev=myid -full-screen

# -smp: number of cores (use more if you have them)
# -m  : set RAM in MB (TempleOS requires at least 512)
qemu-system-x86_64 scratch/tdisk.img -smp 2 -m 2048 -audiodev coreaudio,id=myid -machine pcspk-audiodev=myid -display gtk,zoom-to-fit=on

## Looks better but mouse is weird
#qemu-system-x86_64 tdisk.img -m 2048 -audiodev coreaudio,id=myid -machine pcspk-audiodev=myid -display gtk,zoom-to-fit=on

## VDI instead of IMG
#qemu-system-x86_64 tdisk.vdi -m 2048 -full-screen

