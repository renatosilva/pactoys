# Pacboy

Pacboy is a pacman wrapper for MSYS2 which manages the package prefixes automatically and provides easy commands for common tasks.

```
repman add renatosilva http://renatosilva.me/msys2
pacman --sync pacboy
```

## Examples

Under MinGW shell, for 64-bit MSYS2, install both `mingw-w64-i686-python2-nuitka` and `mingw-w64-i686-python2-nuitka`, or just the i686 version for 32-bit MSYS2:

```
pacboy sync python2-nuitka
```

Remove `mingw-w64-x86_64-perl` and unnecessary dependencies under any shell:

```
pacboy remove perl:x
```

Show information and list files from `coreutils` under MinGW shell:

```
pacboy coreutils: info
pacboy coreutils: files
```

Install MinGW and MSYS versions of libiconv from a configured repository named `mozilla`:

```
pacboy sync mozilla::libiconv
pacboy sync mozilla::libiconv:
```

## License and copyright

Copyright (c) 2015 Renato Silva.
Licensed under the terms of the [3-clause BSD license](LICENSE).
