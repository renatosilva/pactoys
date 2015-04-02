#!/bin/bash

if [[ "${1}" = "${1:+help}" ]]; then echo "
    Pacboy 2015.4.2
    Copyright (C) 2015 Renato Silva
    Licensed under BSD

This is a pacman wrapper for MSYS2 which handles the package prefixes
automatically, and provides human-friendly commands for common tasks.

Usage:
    $(basename "$0") [command] [pacman_options] [pacman_arguments]
    For 64-bit MSYS2, name:i means i686-only
    For 64-bit MSYS2, name:x means x86_64-only
    For MSYS shell, name:m means mingw-w64
    For all shells, name: disables any translation

Commands:
    sync        Shorthand for --sync
    update      Shorthand for --sync --refresh --sysupgrade
    refresh     Shorthand for --sync --refresh
    find        Shorthand for --sync --search
    packages    Shorthand for --sync --list
    files       Shorthand for --query --list
    info        Shorthand for --query --info
    remove      Shorthand for --remove --recursive
    syncfile    Shorthand for --upgrade
"
exit 1
fi

architecture=$(uname -m)
pacman_arguments=()
arguments=()

for argument in "${@}"; do
    if [[ -n "${command}" ]]; then
        arguments+=("${argument}")
        continue
    fi
    case "${argument}" in
        sync)        command="${argument}"; pacman_arguments+=(--sync) ;;
        update)      command="${argument}"; pacman_arguments+=(--sync --refresh --sysupgrade) ;;
        refresh)     command="${argument}"; pacman_arguments+=(--sync --refresh) ;;
        find)        command="${argument}"; pacman_arguments+=(--sync --search) ;;
        packages)    command="${argument}"; pacman_arguments+=(--sync --list) ;;
        files)       command="${argument}"; pacman_arguments+=(--query --list) ;;
        info)        command="${argument}"; pacman_arguments+=(--query --info) ;;
        remove)      command="${argument}"; pacman_arguments+=(--remove --recursive) ;;
        syncfile)    command="${argument}"; pacman_arguments+=(--upgrade) ;;
        *)           arguments+=("${argument}")
    esac
done
for argument in "${arguments[@]}"; do
    case "${argument}" in
    *\\*) pacman_arguments+=("${argument}") ;;
     */*) pacman_arguments+=("${argument}") ;;
      -*) pacman_arguments+=("${argument}") ;;
      *:) pacman_arguments+=("${argument%:}") ;;
     *:i) pacman_arguments+=(mingw-w64-i686-${argument%:i}) ;;
     *:x) pacman_arguments+=(mingw-w64-x86_64-${argument%:x}) ;;
     *:m) pacman_arguments+=(mingw-w64-x86_64-${argument%:m} mingw-w64-i686-${argument%:m}) ;;
       *) [[ "${command}"       = find     ]] && { pacman_arguments+=(${argument}); continue; }
          [[ "${command}"       = packages ]] && { pacman_arguments+=(${argument}); continue; }
          [[ "${command}"       = syncfile ]] && { pacman_arguments+=(${argument}); continue; }
          [[ "${MSYSTEM}"      != MINGW*   ]] && { pacman_arguments+=(${argument}); continue; }
          [[ "${architecture}" != x86_64   ]] && { pacman_arguments+=(mingw-w64-${architecture}-${argument}); continue; }
          pacman_arguments+=(mingw-w64-x86_64-${argument} mingw-w64-i686-${argument})
    esac
    [[ "${argument}" =~ -h|--help ]] && echo "did you mean '$(basename "$0") help'?"
done

[[ "${command}" =~ update|refresh && -f /usr/bin/pkgfile ]] && pkgfile --update
pacman --color auto "${pacman_arguments[@]}"
