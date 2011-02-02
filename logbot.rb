#!/usr/bin/env ruby
require 'rubygems'
require 'yaml'
require 'isaac'

$options = YAML.load(File.open('logbot.yaml'))
$future_messages = {}

if $options.has_key?(:logdir)
    Dir.chdir($options[:logdir])
end

configure do |c|
    c.nick = $options[:nick]
    c.server = $options[:server]
    c.port = $options[:port] 
    c.ssl = $options[:ssl]
    c.password = $options[:password]
    c.verbose = $options.has_key?(:verbose) ? $options[:verbose] : false
end

# Helpers
helpers do
    def is_admin?(nick)
        if not $options.has_key?(:admins) or $options[:admins].empty?
            # Everyone is an admin!
            return true
        end

        $options[:admins].each do |admin_nick|
            if admin_nick == nick
                return true
            end
        end

        return false
    end

    def help_message(nick)
        msg nick, "logbot understands !quit, !join #channel, !part, !future, and !help."
        msg nick, "!part will leave the channel in which the command is heard."
        msg nick, "!future nickname message will leave a message for nickname,"
        msg nick, "to be delivered the next time they join the channel."
        msg nick, "only admins can use !quit, !join, and !part."
    end

    def store_future(from, to, message)
        if not $future_messages.has_key?(to)
            $future_messages[to] = []
        end
        $future_messages[to] << {:from => from, :message => message}
    end

    def has_future?(nick)
        return $future_messages.has_key?(nick)
    end

    def get_future(nick)
        if $future_messages.has_key?(nick)
            return $future_messages[nick]
        else
            return []
        end
    end
end

on :connect do
    if not $options.has_key?(:channels) or $options[:channels].empty?
        join '#logbot'
    else
        $options[:channels].each {|c| join c}
    end
end

# Commands
on :channel, /^\!(help|quit|part|join|future)([ \t]+.*)*$/ do
    if is_admin?(nick)
        case match[0]
            when "quit"
                quit "Requested to quit"
            when "part"
                part channel
            when "join"
                join match[1]
        end
    end

    case match[0]
        when "help"
            help_message(nick)
        when "future"
            to_nick = match[1].split(' ')[0]
            future_message = match[1].split(' ')[1..-1]
            store_future(nick, to_nick, future_message)
            msg channel, "#{nick}: i'll tell #{to_nick} when i see them."
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

on :join do
    if nick != $options[:nick]
        msg channel, "yo #{nick}"
        if has_future?(nick)
            msg channel, "#{nick}: got a message for you"
            get_future(nick).each do |future|
                msg channel, "#{future[:from]} said to tell you #{future[:message]}"
            end
        end
    end
end
