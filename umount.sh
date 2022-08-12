#!/bin/bash

# Remove the TempleOS virtual disk previously mounted by mount.sh

# TODO: move things like drive letter "T:" to a shared config script

imdisk -D -m T:

