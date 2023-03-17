<h1 align="center">Linux From Scratch Playground</h1>

<div align="center">
    <a href="https://www.linuxfromscratch.org"> <img src="https://www.linuxfromscratch.org/images/lfs-logo.png" alt="Linux From Scratch logo" /></a>
</div>
<br>

A collection of scripts and files for use in completing and automating LFS.

Some scripts simply automate the exact tasks as specified in the book, some make cosmetic changes (e.g. colorizing outputs),
some change the method that certain tasks are completed by (e.g. parallellization), and some do a mix of these things.

All files provided in the LFS book are provided *as is* in the `provided`(provided/) directory.
Files with the same name in the root of the repository are my personal adaptations of provided files.



## Assumptions

[Libvirt](https://libvirt.org) and [QEMU](https://www.qemu.org) are used to build and manage the virtual machines used to build the LFS system.
Tools from the [virt-manager](https://virt-manager.org) project (`virt-install` & `virt-xml`) are also used in some scripts.

The LFS host machine is itself a virtual machine with an additonal attached vdisk to build the LFS system on.

The `$LFS` variable is used and set to `/mnt/lfs`, as described in the LFS book.

In keeping with the conventions used in LFS, all scripts are written in `bash`. There is no effort to be compatible with POSIX or ZSH.



## Scripts

### Host Scripts (Should be run on the Host Machine)

- [`mklfsvm`](scripts/mklfsvm):
        Creates a virtual machine that serves as the LFS host system, a second drive for the LFS system, and performs and unattended install of the host OS.

### LFS Host Scripts - user (Should be run on the LFS Host as a normal user)

- [`lfs-dlsrc`](scripts/lfs-dlsrc):
        Downloads required LFS sourced and verifies the md5 sums of the downloaded sources __(requires `lfs-sources.curl`)__.
- [`lfs-mkuser`](scripts/lfs-mkuser):
        Makes the `lfs` user and sets the `lfs` user's environment.
- [`lfs-chkv`](scripts/lfs-chkv):
        Checks the version of required packages installed on the host system

### LFS Host Scripts - lfs (Should be run on the LFS Host as the `lfs` user)

- []()

### LFS Scripts (Should be run as root in the LFS `chroot`)

- []()



## Files

### Host Files (Host machine of the LFS host virtual machine)

- [`lfs-host.xml`](files/lfs-host.xml):
        The Libvirt XML config file for the Host.
- [`lfs-disk.xml`](files/lfs-disk.xml):
        The Libvirt XML config fragment for the LFS disk.

### LFS Host Files (The LFS host virtual machine)

- [`lfs-sources.curl`](files/lfs-sources.curl):
        Addaptation of `wget-list-sysv` to work with `curl` __(required by `lfs-dlsrc`)__.
- [`lfs.bashrc`](files/lfs.bashrc):
        A minimal `.bashrc` for the `lfs` user.
        The file is named `lfs.bashrc` to distinguish it from `root.bashrc` in this repo, but should be renamed to `.bashrc`
        on the LFS host and placed in the appropriate location (`/home/lfs/.bashrc`).
- [`root.bashrc`](files/root.bashrc):
        A minimal `.bashrc` for the `root` user once the `chroot` is entered.
        The file is named `root.bashrc` to distinguish it from `lfs.bashrc` in this repo, but should be renamed to `.bashrc`
        on the LFS host and placed in the appropriate location (`/root/.bashrc`).

### LFS Files (The LFS machine itself)

- []()



## LFS Provided Files and Scripts

| File Name | Book Chapter | File Path |
| --------- | ------------ | --------- |
| [`version-check.sh`](provided/version-check.sh) | [Chapter 2.2 - Host System Requirements](https://www.linuxfromscratch.org/lfs/view/stable/chapter02/hostreqs.html) | |
| [`wget-list-sysv`](provided/wget-list-sysv) | [Chapter 3.1 - Introduction](https://www.linuxfromscratch.org/lfs/view/stable/chapter03/introduction.html) | |
| [`lfs.bash_profile`](provided/lfs.bash_profile) | [Chapter 4.4 - Setting Up the Environment](https://www.linuxfromscratch.org/lfs/view/stable/chapter04/settingenvironment.html) | `/home/lfs/.bash_profile` |
| [`lfs.bashrc`](provided/lfs.bashrc) | [Chapter 4.4 - Setting up the Environment](https://www.linuxfromscratch.org/lfs/view/stable/chapter04/settingenvironment.html) | `/home/lfs/.bashrc` |


## License

> Copyright © 1999-2023, Gerard Beekmans
>
> All rights reserved.
>
> This book is licensed under a [Creative Commons License](https://www.linuxfromscratch.org/lfs/view/development/appendices/creat-comm.html).
>
> Computer instructions may be extracted from the book under the [MIT License](https://www.linuxfromscratch.org/lfs/view/development/appendices/mit.html).
>
> Linux® is a registered trademark of Linus Torvalds.
>
> *- [LFS License Page](https://www.linuxfromscratch.org/lfs/view/development/appendices/licenses.html)*

All files in the [`provided`](provided/) directory of this repository are directly extracted from the LFS book or its directly referenced sources.
