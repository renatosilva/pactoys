# Pacboy

Pacboy is a pacman wrapper for MSYS2 which manages the package prefixes automatically and provides easy commands for common tasks. It also supports autocompletion of package and repository names.

```
repman add renatosilva http://packages.renatosilva.net
pacman --sync pacboy
```

## Examples

Under MinGW shell, for 64-bit MSYS2, install both `mingw-w64-x86_64-python2-nuitka` and `mingw-w64-i686-python2-nuitka`, or just the i686 version for 32-bit MSYS2:

```
pacboy sync python2-nuitka
```

Remove `mingw-w64-x86_64-perl` and unnecessary dependencies under any shell:

```
pacboy remove perl:x
```

Show information and list files from `mingw-w64-x86_64-libmongoose-git` under 64-bit MinGW shell:

```
pacboy libmongoose info
pacboy libmongoose files
```

List content and install a package file:

```
pacboy files repman-git-r23.87bf865-1-x86_64.pkg.tar.xz
pacboy sync  repman-git-r23.87bf865-1-x86_64.pkg.tar.xz
```

Install MinGW and MSYS versions of libiconv from a configured repository named `mozilla`, with debug output enabled:

```
pacboy debug sync mozilla::libiconv
pacboy debug sync mozilla::libiconv:
```

Find packages that provide a specific file:

```
pacboy origin rsync.exe
pacboy origin /usr/bin/rsync.exe
```

## License and copyright

Copyright (c) 2015, 2016 Renato Silva.
Licensed under the terms of the [3-clause BSD license](LICENSE).
