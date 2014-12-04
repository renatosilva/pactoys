#!/bin/bash

# Tests for Repman
# Copyright (C) 2014 Renato Silva
# Licensed under GPLv2 or later

config="/etc/pacman.d/repman.conf"
if [[ -e $config ]]; then
    mv $config $config.bak
    trap "mv $config.bak $config" EXIT
fi
if [[ -t 1 ]]; then
    green_color="\e[0;32m"
    purple_color="\e[1;35m"
    normal_color="\e[0m"
fi

runtest() {
    for test in "${tests[@]}"; do
        command="${test%%::*}"
        arguments="${test#*::}"
        [[ "$command" = repman ]] && command="$2"
        echo -e "${1}\$ ${command} ${arguments}${normal_color}"
        $command $arguments
        echo
    done
}

tests=(repman::
         grep::"repman /etc/pacman.conf"
       repman::"list"
         grep::"repman /etc/pacman.conf"
       repman::"add renatosilva http://renatosilva.me/msys2"
       repman::"list"
       pacman::"--sync --list renatosilva"
       repman::"remove renatosilva"
       repman::"list"
       repman::"add"
       repman::"add renatosilva"
       repman::"remove renatosilva"
       repman::"list extra arguments"
       repman::"hello")

runtest "${green_color}"  "repman.exe"
runtest "${purple_color}" "ruby /usr/bin/repman"
