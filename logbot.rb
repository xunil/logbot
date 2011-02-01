#!/usr/bin/env ruby
require 'rubygems'
require 'yaml'
require 'isaac'

options = YAML.load(File.open('logbot.yaml'))

if options.has_key?(:logdir)
    Dir.chdir(options[:logdir])
end

configure do |c|
    c.nick = options[:nick]
    c.server = options[:server]
    c.port = options[:port] 
    c.ssl = options[:ssl]
    c.password = options[:password]
end

on :connect do
    join '#logbot'
end

on :channel, /^\!/ do
    case message
        when /^\!quit/
            quit "Requested to quit"
    end
end

on :channel, /^[^!]/ do
    now = Time.now
    year = now.year
    month = now.month
    day = now.day
    if not File.directory?(year.to_s)
        Dir.mkdir(year.to_s)
    end
    if not File.directory?("%d/%02d" % [year, month])
        Dir.mkdir("%d/%02d" % [year, month])
    end
    logfile_name = "%d/%02d/%d-%02d-%02d.%s.log" % [year, month, year, month, day, channel]
    timestamp = "%02d:%02d:%02d" % [now.hour, now.min, now.sec]
    File.open(logfile_name, "a") {|f| f.puts "#{timestamp} <#{nick}> #{message}"}
end
