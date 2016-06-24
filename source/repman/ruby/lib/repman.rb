#!/usr/bin/env ruby
# Encoding: UTF-8

##
##     Pacman Repository Manager 16.1
##     Copyright (c) 2014, 2016 Renato Silva
##     Licensed under BSD
##
## This program manages pacman repositories. It uses a separate included file
## /etc/pacman.d/repman.conf instead of /etc/pacman.conf. Usage:
##
##     repman add NAME URL  Add a repository and refresh database.
##     repman remove NAME   Remove a repository and refresh database.
##     repman list          List all repositories.
##

$0 = __FILE__
require 'fileutils'
require 'tempfile'
require 'inifile'
require 'easyoptions'
if ARGV.empty?
    puts EasyOptions.documentation
    exit
end

class Repository
    def initialize(name, url, siglevel)
        @name = name
        @url = url
        @siglevel = siglevel
    end
    def save(config)
        config[@name] = { 'Server' => @url, 'SigLevel' => @siglevel }
        config.write
    end
    def remove(config)
        config.delete_section(@name)
        config.write
    end
    def self.load(config, name)
        return nil unless config.has_section?(name)
        siglevel = config[name]['SigLevel']
        url = config[name]['Server']
        self.new(name, url, siglevel)
    end
    def self.all(config)
        config.sections.map do |name|
            Repository.load(config, name)
        end
    end
    attr_accessor :name
    attr_accessor :url
    attr_accessor :siglevel
end

pacman_file = '/etc/pacman.conf'
config_file = '/etc/pacman.d/repman.conf'
command, name, url = EasyOptions.arguments
include_regex = /^\s*Include\s+=\s+#{config_file}/
config = (IniFile.load(config_file) or IniFile.new(:filename => config_file).write)
repository = Repository.new(name, url, 'Optional')

begin
    File.open(pacman_file, 'a') do |file|
        file.puts("\n# Automatically included by repman")
        file.puts("Include = #{config_file}")
    end if not File.readlines(pacman_file).grep(include_regex).any?
rescue
    EasyOptions.finish "could not check #{pacman_file}"
end

case command
when 'add'
    EasyOptions.finish 'name and URL required' unless url
    temp_config = IniFile.new(:filename => Tempfile.new('repman').path)
    repository.save(temp_config)
    system("pacman --sync --refresh --config #{temp_config.filename}") and repository.save(config) or
    EasyOptions.finish "could not add repository #{name}"
when 'remove'
    EasyOptions.finish 'name is required' unless name
    repository = Repository.load(config, name)
    repository and FileUtils.rm_f("/var/lib/pacman/sync/#{name}.db") and repository.remove(config) or
    EasyOptions.finish "could not remove repository #{name}"
when 'list' then
    EasyOptions.finish "extra arguments to #{command} command" if EasyOptions.arguments[1]
    Repository.all(config).each do |repository|
        puts repository.name
        puts "\tServer: #{repository.url}"
        puts "\tSigLevel: #{repository.siglevel}"
    end
else
    EasyOptions.finish "unknown command #{command}"
end
