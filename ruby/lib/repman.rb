#!/usr/bin/env ruby
# Encoding: UTF-8

##
##     Pacman Repository Manager 2014.12.2
##     Copyright (c) 2014 Renato Silva
##     Licensed under GNU GPLv2 or later
##
## This program manages pacman repositories. It uses a separate included file
## /etc/pacman.d/pacrep.conf instead of /etc/pacman.conf. Options:
##
##         --add=NAME     Add a repository and refresh database, requires --url.
##         --remove=NAME  Remove a repository and refresh database.
##         --url=VALUE    Set repository location.
##     -l, --list         List all repositories.
##

$0 = __FILE__
require 'inifile'
require 'easyoptions'
options = EasyOptions.options

repository_name = (options[:add] or options[:remove])
EasyOptions.finish '--url is required' if options[:add] and not options[:url]
EasyOptions.finish 'cannot add and remove repository at the same time' if options[:add] and options[:remove]

pacman_file = '/etc/pacman.conf'
config_file = '/etc/pacman.d/repman.conf'
config = (IniFile.load(config_file) or IniFile.new(:filename => config_file))
include_regex = /^\s*Include\s+=\s+#{config_file}/

begin
    File.open(pacman_file, 'a') do |file|
        file.puts("\nInclude = #{config_file}")
    end if not File.readlines(pacman_file).grep(include_regex).any?
rescue
    EasyOptions.finish "could not check #{pacman_file}"
end

if options[:add] then
    config[repository_name] = {
        'Server'   => options[:url],
        'SigLevel' => 'Optional'
    }
    config.write
    system('pacman --sync --refresh')
    exit
end

if options[:remove] then
    repository = config[repository_name]
    EasyOptions.finish "could not find repository #{repository_name}" if not repository or repository.empty?
    config.delete_section(repository_name)
    config.write
    system('pacman --sync --refresh')
    exit
end

if options[:list] then
    config.each_section do |repository_name|
        repository = config[repository_name]
        puts repository_name
        puts "\tServer: #{repository['Server']}"
        puts "\tSigLevel: #{repository['SigLevel']}"
    end
end
