#!/bin/bash

if [[ "${1}" = "${1:+help}" ]]; then echo "
    Pacboy 2015.6.21
    Copyright (C) 2015 Renato Silva
    Licensed under BSD

This is a pacman wrapper for MSYS2 which handles the package prefixes
automatically, and provides human-friendly commands for common tasks.

Usage:
    $(basename "$0") [command] [pacman_options] [pacman_arguments]
    For 64-bit MSYS2, name:i means i686-only
    For 64-bit MSYS2, name:x means x86_64-only
    For MSYS shell, name:m means mingw-w64
    For all shells, name: disables any translation for name
    For all shells, repository::name means repository/name

Commands:
    sync        Shorthand for --sync or --upgrade
    update      Shorthand for --sync --refresh --sysupgrade
    refresh     Shorthand for --sync --refresh
    find        Shorthand for --sync --search
    packages    Shorthand for --sync --list
    files       Shorthand for --query --list [--file]
    info        Shorthand for --query --info [--file]
    remove      Shorthand for --remove --recursive
"
exit 1
fi

parse_mingw_argument() {
    [[ "${command}"  = sync     && -n "${file_argument}" ]] && { pacman_argument=(${argument}); return; }
    [[ "${command}"  = files    && -n "${file_argument}" ]] && { pacman_argument=(${argument}); return; }
    [[ "${command}"  = info     && -n "${file_argument}" ]] && { pacman_argument=(${argument}); return; }
    [[ "${command}"  = find     ]] && { pacman_argument=(${argument}); return; }
    [[ "${command}"  = packages ]] && { pacman_argument=(${argument}); return; }
    [[ "${MSYSTEM}" != MINGW*   ]] && { pacman_argument=(${argument}); return; }
    [[ "${machine}" != x86_64   ]] && { pacman_argument=(mingw-w64-${architecture}-${argument}); return; }
    [[ "${command}"  = files    ]] && { pacman_argument=(mingw-w64-${architecture}-${argument}); return; }
    [[ "${command}"  = info     ]] && { pacman_argument=(mingw-w64-${architecture}-${argument}); return; }
    pacman_argument=(mingw-w64-x86_64-${argument} mingw-w64-i686-${argument})
}

realname() {
    test -f "${1}" && { echo "${1}"; return; }
    pacman -Q "${1}"     > /dev/null 2>&1 && { echo "${1}";     return; }
    pacman -Q "${1}-git" > /dev/null 2>&1 && { echo "${1}-git"; return; }
    pacman -Q "${1}-svn" > /dev/null 2>&1 && { echo "${1}-svn"; return; }
    pacman -Q "${1}-hg"  > /dev/null 2>&1 && { echo "${1}-hg";  return; }
    pacman -Q "${1}-cvs" > /dev/null 2>&1 && { echo "${1}-cvs"; return; }
    pacman -Q "${1}-bzr" > /dev/null 2>&1 && { echo "${1}-bzr"; return; }
    echo "${1}"
}

machine=$(uname -m)
pacman_arguments=()
arguments=()
case "${MSYSTEM}" in
    MINGW32) architecture='i686' ;;
    MINGW64) architecture='x86_64' ;;
    *)       architecture="${machine}"
esac

for argument in "${@}"; do
    if [[ -n "${command}" ]]; then
        arguments+=("${argument}")
        continue
    fi
    case "${argument}" in
        sync)        command="${argument}"; pacman_command='--sync' ;;
        update)      command="${argument}"; pacman_command='--sync --refresh --sysupgrade' ;;
        refresh)     command="${argument}"; pacman_command='--sync --refresh' ;;
        find)        command="${argument}"; pacman_command='--sync --search' ;;
        packages)    command="${argument}"; pacman_command='--sync --list' ;;
        files)       command="${argument}"; pacman_command='--query --list' ;;
        info)        command="${argument}"; pacman_command='--query --info' ;;
        remove)      command="${argument}"; pacman_command='--remove --recursive' ;;
        *)           arguments+=("${argument}")
    esac
done

for argument in "${arguments[@]}"; do
    if [[ "${argument}" = *::* ]]; then
        repository="${argument%::*}/"
        argument="${argument##*::}"
    fi
    case "${command}" in
        sync)  test -f "${argument}" && { file_argument='true'; pacman_command='--upgrade'; } ;;
        files) test -f "${argument}" && { file_argument='true'; pacman_command="${pacman_command} --file"; } ;;
        info)  test -f "${argument}" && { file_argument='true'; pacman_command="${pacman_command} --file"; } ;;
    esac
    case "${argument}" in
    *\\*) pacman_argument=("${argument}") ;;
     */*) pacman_argument=("${argument}") ;;
      -*) pacman_argument=("${argument}") ;;
      *:) pacman_argument=("${argument%:}") ;;
     *:i) pacman_argument=(mingw-w64-i686-${argument%:i}) ;;
     *:x) pacman_argument=(mingw-w64-x86_64-${argument%:x}) ;;
     *:m) pacman_argument=(mingw-w64-x86_64-${argument%:m} mingw-w64-i686-${argument%:m}) ;;
       *) parse_mingw_argument ;;
    esac
    [[ "${argument}" =~ ^-h|--help$ ]] && echo "did you mean '$(basename "$0") help'?"
    for pacman_argument in "${pacman_argument[@]}"; do
        [[ "${command}" =~ ^files|info|remove$ ]] && pacman_argument=$(realname "${pacman_argument}")
        pacman_arguments+=("${repository}${pacman_argument}")
    done
    unset file_argument
    unset repository
done

case "${command}" in
    update|refresh) test -f /usr/bin/pkgfile && pkgfile --update
                    pacman --color auto $pacman_command "${pacman_arguments[@]}" ;;
    files)          pacman --color auto $pacman_command "${pacman_arguments[@]}" | grep --invert-match '/$' ;;
    *)              pacman --color auto $pacman_command "${pacman_arguments[@]}"
esac
