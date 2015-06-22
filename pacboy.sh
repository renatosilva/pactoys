#!/bin/bash

if [[ "${1}" = "${1:+help}" ]]; then echo "
    Pacboy 2015.6.22
    Copyright (C) 2015 Renato Silva
    Licensed under BSD

This is a pacman wrapper for MSYS2 which handles the package prefixes
automatically, and provides human-friendly commands for common tasks.

Usage:
    $(basename "$0") [command] [arguments]
    Arguments will be passed to pacman or pkgfile after translation:

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
    origin      Shorthand for --query --owns or pkgfile
    remove      Shorthand for --remove --recursive
    debug       Verbose output for the above commands.
"
exit 1
fi

parse_mingw_argument() {
    [[ "${command}"  = sync     && -n "${file_argument}" ]] && { raw_argument=(${argument}); return; }
    [[ "${command}"  = files    && -n "${file_argument}" ]] && { raw_argument=(${argument}); return; }
    [[ "${command}"  = info     && -n "${file_argument}" ]] && { raw_argument=(${argument}); return; }
    [[ "${command}"  = origin   ]] && { raw_argument=(${argument}); return; }
    [[ "${command}"  = find     ]] && { raw_argument=(${argument}); return; }
    [[ "${command}"  = packages ]] && { raw_argument=(${argument}); return; }
    [[ "${MSYSTEM}" != MINGW*   ]] && { raw_argument=(${argument}); return; }
    [[ "${machine}" != x86_64   ]] && { raw_argument=(mingw-w64-${architecture}-${argument}); return; }
    [[ "${command}"  = files    ]] && { raw_argument=(mingw-w64-${architecture}-${argument}); return; }
    [[ "${command}"  = info     ]] && { raw_argument=(mingw-w64-${architecture}-${argument}); return; }
    raw_argument=(mingw-w64-x86_64-${argument} mingw-w64-i686-${argument})
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

arguments=()
raw_arguments=()
pacman='pacman --color auto'
machine=$(uname -m)
case "${MSYSTEM}" in
    MINGW32) architecture='i686' ;;
    MINGW64) architecture='x86_64' ;;
    *)       architecture="${machine}"
esac

for argument in "${@}"; do
    if [[ "${argument}" = debug && -z "${debug}" ]]; then
        debug='true'
        continue
    fi
    if [[ -n "${command}" ]]; then
        arguments+=("${argument}")
        continue
    fi
    case "${argument}" in
        sync)        command="${argument}"; raw_command="${pacman} --sync" ;;
        update)      command="${argument}"; raw_command="${pacman} --sync --refresh --sysupgrade" ;;
        refresh)     command="${argument}"; raw_command="${pacman} --sync --refresh" ;;
        find)        command="${argument}"; raw_command="${pacman} --sync --search" ;;
        packages)    command="${argument}"; raw_command="${pacman} --sync --list" ;;
        files)       command="${argument}"; raw_command="${pacman} --query --list" ;;
        info)        command="${argument}"; raw_command="${pacman} --query --info" ;;
        remove)      command="${argument}"; raw_command="${pacman} --remove --recursive" ;;
        origin)      command="${argument}"; raw_command='pkgfile' ;;
        *)           arguments+=("${argument}")
    esac
done

for argument in "${arguments[@]}"; do
    if [[ "${argument}" = *::* ]]; then
        repository="${argument%::*}/"
        argument="${argument##*::}"
    fi
    case "${command}" in
        sync)   test -f "${argument}" && { file_argument='true'; raw_command="${pacman} --upgrade"; } ;;
        origin) test -f "${argument}" && { file_argument='true'; raw_command="${pacman} --query --owns"; } ;;
        files)  test -f "${argument}" && { file_argument='true'; raw_command="${raw_command} --file"; } ;;
        info)   test -f "${argument}" && { file_argument='true'; raw_command="${raw_command} --file"; } ;;
    esac
    case "${argument}" in
    *\\*) raw_argument=("${argument}") ;;
     */*) raw_argument=("${argument}") ;;
      -*) raw_argument=("${argument}") ;;
      *:) raw_argument=("${argument%:}") ;;
     *:i) raw_argument=(mingw-w64-i686-${argument%:i}) ;;
     *:x) raw_argument=(mingw-w64-x86_64-${argument%:x}) ;;
     *:m) raw_argument=(mingw-w64-x86_64-${argument%:m} mingw-w64-i686-${argument%:m}) ;;
       *) parse_mingw_argument ;;
    esac
    [[ "${argument}" =~ ^-h|--help$ ]] && echo "did you mean '$(basename "$0") help'?"
    for raw_argument in "${raw_argument[@]}"; do
        [[ "${command}" =~ ^files|info|remove$ ]] && raw_argument=$(realname "${raw_argument}")
        raw_arguments+=("${repository}${raw_argument}")
    done
    unset file_argument
    unset repository
done

if [[ -z "${raw_command}" ]]; then
    raw_command="${pacman}"
fi

if [[ -n "${debug}" ]]; then
    if [[ -t 1 ]]; then
        blue="\e[1;34m"
        white="\e[1;37m"
        normal='\e[0m'
    fi
    echo -e "${blue}::${white}" Executing ${raw_command} "${raw_arguments[@]}${normal}" >&2
fi

case "${command}" in
    update|refresh) ${raw_command} "${raw_arguments[@]}" ; pkgfile --update ;;
    files)          ${raw_command} "${raw_arguments[@]}" | grep --invert-match '/$' ;;
    *)              ${raw_command} "${raw_arguments[@]}"
esac
