# Makepatch

Makepatch is a patch manager for pacman packages.

## Examples

Initialize working directory:

```bash
tar xf tarball.tar.gz
makepatch init extracted
```

Edit existing patches:

```bash
vim patches/001/some/source/file.c
makepatch diff 001
makepatch refresh
```

Create new patches:

```bash
cp -r patches/{001,002}
vim patches/002/edit/files.c
makepatch diff 002 > 002-name.patch
```
