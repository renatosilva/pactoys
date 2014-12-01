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

native_tests=("repman.exe"
              "repman.exe list"
              "repman.exe add renatosilva http://renatosilva.me/msys2"
              "repman.exe list"
              "pacman --sync --list renatosilva"
              "repman.exe remove renatosilva"
              "repman.exe list"
              "repman.exe add"
              "repman.exe add renatosilva"
              "repman.exe remove renatosilva"
              "repman.exe list extra arguments"
              "repman.exe hello")

ruby_tests=("ruby /usr/bin/repman --help"
            "ruby /usr/bin/repman --list"
            "ruby /usr/bin/repman --add renatosilva --url http://renatosilva.me/msys2"
            "ruby /usr/bin/repman --list"
            "pacman --sync --list renatosilva"
            "ruby /usr/bin/repman --remove renatosilva"
            "ruby /usr/bin/repman --list"
            "ruby /usr/bin/repman --add"
            "ruby /usr/bin/repman --add renatosilva"
            "ruby /usr/bin/repman --remove renatosilva"
            "ruby /usr/bin/repman --list extra arguments"
            "ruby /usr/bin/repman --hello")

for test in "${native_tests[@]}"; do
    echo -e "${green_color}\$ $test${normal_color}"
    $test
    echo
done

for test in "${ruby_tests[@]}"; do
    echo -e "${purple_color}\$ $test${normal_color}"
    $test
    echo
done
