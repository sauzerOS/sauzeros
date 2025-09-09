# 🌌 SauzerOS

**⚠️ Disclaimer:**  Nobody should use this, and if you do, you are on your own.  

## 📚 Based On

- [Kiss Linux](https://kisslinux.github.io/)  
- [Linux From Scratch (LFS, BLFS, MLFS, GLFS, ALFS)](https://www.linuxfromscratch.org)  
- [Arch Linux](https://archlinux.org/)  

---

## 🖥 Features

- Multilib, source-based  
- **Systemd / Glibc**  
- **Xlibre**  
- **Xfce4**  
- **Steam**  
- **Wine**  
- **Flatpak**  
- **Nvidia**  

All packages are built with Nvidia GPU in mind.  
*This is just Arch from source but worse*  
If you want a usable system use [CachyOS](https://cachyos.org) or [Arch Linux](https://archlinux.org/).  

## ⚒️ Build Process

> Any liveCD with basic build tools should work.  
> Examples: EndeavourOS, Fedora, Mint.  
> Requirements: [Host System Requirements (LFS)](https://www.linuxfromscratch.org/~thomas/multilib-m32/chapter02/hostreqs.html)  

### 1️⃣ Build a clean multilib toolchain in `/newroot` (MLFS Chapters 5–6)

git clone https://github.com/sauzeros /repo/sauzeros  
cd /repo/sauzeros/bootstrap  
sudo LFS=/newroot ./lfs-user  
./hokuto LIST  

### 2️⃣ Chroot into /newroot
sudo LFS=/newroot ./chroot  

At this stage you are inside a clean multilib environment with just enough tools
to use kiss for building the full system.

### Set the target partition/folder for the new system
export KISS_ROOT=/target  
cd /repo/sauzeros/core  
kiss b sauzeros-base binutils gcc.... (will be replaced by base-system)  
(not yet implemented)  
kiss b base-system  
kiss b desktop-system  

⚖️ Licensing

All packages retain their original licenses.
All unique content is licensed under WTFPL.
