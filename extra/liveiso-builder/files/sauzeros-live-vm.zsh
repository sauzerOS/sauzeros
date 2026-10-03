#compdef sauzeros-live-vm

_arguments -s \
  '(-r --rootfs)'{-r,--rootfs}'[rootfs to boot]:rootfs directory:_directories' \
  '(-i --image)'{-i,--image}'[working disk image]:image file:_files' \
  '(-m --memory)'{-m,--memory}'[guest memory]:size (4G):' \
  '(-c --cpus)'{-c,--cpus}'[guest CPUs]:count:' \
  '(-s --free)'{-s,--free}'[free space in the image]:size (8G):' \
  '(-k --kernel)'{-k,--kernel}'[kernel to boot]:kernel:_files' \
  '(-a --append)'{-a,--append}'[extra kernel command line arguments]:arguments:' \
  '(--fresh)--reuse[reuse an existing image without asking]' \
  '(--reuse)--fresh[recreate the image from the rootfs without asking]' \
  '(--no-gl)--gl[3D acceleration through virgl (default)]' \
  '(--gl --venus)--no-gl[plain virtio-vga, no 3D]' \
  '(--no-gl)--venus[3D plus Vulkan in the guest (Venus)]' \
  '--relative-mouse[relative mouse the window captures, for games]' \
  '--uefi[boot through UEFI firmware instead of the BIOS]' \
  '--display[QEMU display]:display:(gtk sdl spice)' \
  '(- *)'{-h,--help}'[show usage]'
