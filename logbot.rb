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

# Helpers
helpers do
    def is_admin?(nick)
        if not options.has_key?[:admins] or options[:admins].empty?
            # Everyone is an admin!
            return true
        end

        options[:admins].each do |admin_nick|
            if admin_nick == nick
                return true
            end
        end

        return false
    end
end

on :connect do
    if not options.has_key?(:channels) or options[:channels].empty?
        join '#logbot'
    else
        options[:channels].each {|c| join c}
    end
end

# Commands
on :channel, /^\!(help|quit|part|join)([ \t]+[^ ]+)*/ do
    if is_admin?(nick)
        case matches[0]
            when "help"
                help_message(nick)
            when "quit"
                quit "Requested to quit"
            when "part"
                part channel
            when "join"
                join matches[1]
        end
    end
end

# Logging
on :channel, /^[^!]/ do
    now = Time.now
    if not File.directory?(now.year.to_s)
        Dir.mkdir(now.year.to_s)
    end
    if not File.directory?("%d/%02d" % [now.year, now.month])
        Dir.mkdir("%d/%02d" % [now.year, now.month])
    end
    logfile_name = "%d/%02d/%d-%02d-%02d.%s.log" % [now.year, now.month, now.year, now.month, now.day, channel]
    timestamp = "%02d:%02d:%02d" % [now.hour, now.min, now.sec]
    File.open(logfile_name, "a") {|f| f.puts "#{timestamp} <#{nick}> #{message}"}
end
