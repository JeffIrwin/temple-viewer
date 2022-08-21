
*It’s clusterfucked on purpose by the CIA*

# temple-viewer

3D model viewer for TempleOS

![](doc/temple-viewer-demo2.gif)

## TempleOS basics

### One-time setup

Download the TempleOS ISO:  https://templeos.org/

Install QEMU for machine virtualization:  https://www.qemu.org/download/

Create a virtual disk (20GB is probably overkill):

    qemu-img create tdisk.img 20G

Install TempleOS:

    qemu-system-x86_64 -boot d -cdrom TempleOS.ISO -m 2048 -hda tdisk.img

Follow the TempleOS prompts to install it from the ISO to your virtual drive.

### Running TempleOS

    qemu-system-x86_64 tdisk.img -m 2048

### File transfer

Use ImDisk Toolkit to mount the virtual TempleOS drive and copy files to/from
your Windows host:  http://www.ltr-data.se/opencode.html/

## Running this viewer

After getting TempleOS running, copy all of the `*.HC` files from the top-level
of this repository onto TempleOS.  Include [`Load.HC`](Load.HC), then
run `StlView()` to view one of the provided STLs or any binary or ASCII STL:

    #include "/path/to/temple-viewer/Load"
    StlView("/path/to/my/file.stl");

Alternatively, use [`Run.HC`](Run.HC), which just executes the two lines above
with hard-coded paths to provided STL files.

If Windows makes all the filenames uppercase, run [`FixCase.HC`](FixCase.HC) to
rename them back to the expected case.

Also checkout the video demo:  https://www.youtube.com/watch?v=tHBgW9h7iKI

### STL files

A few STL files are provided in the [`DATA`](DATA) dir here.  Other STL files can be downloaded from [thingiverse.com](https://www.thingiverse.com/) or similar websites.

