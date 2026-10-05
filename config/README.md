# Fedora Asahi configuration notes

Fedora 44 is the initial target because it is the current Fedora Asahi
reference release and the Bazzite 44 build line.

Asahi package sources used by the image:
- @asahi/kernel
- @asahi/u-boot
- @asahi/mesa
- @asahi/fedora-remix-scripts

Keep these as COPR enables in the build rather than committing generated
repository files. This keeps repository metadata and signing-key handling
with Fedora/COPR.
