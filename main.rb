#!/opt/rh-ng/ruby-200/root/usr/bin/ruby

require 'rubygems'
require 'websocket-client-simple'
require 'json'

require_relative 'src/jobset.rb'

Dir.chdir __dir__

$jobset=JobSet.new

def diag(s)
  STDERR.puts "    #{Time.now.to_s}: #{s}"
end

def proc_msg(x)
  begin
    j=JSON.parse(x)
    if j['a'] == ['bridge','trigger','rfd']
      $jobset.kick('rfd')
    elsif j['a'] == ['bridge','trigger','baseline']
      $jobset.kick('baseline')
    end
  rescue => e
    diag "E: #{e.inspect}"
  end
end

a='ws://msgsrv:3042/msg/ws'

ws = WebSocket::Client::Simple.connect a

ws.on :message do |msg|
  proc_msg(msg.data)
end

ws.on :open do
  diag "Opened"
  # ws.send 'hello!!!'
end

ws.on :close do |e|
  diag "Closed"
  p e
end

ws.on :error do |e|
  diag "Error!"
  p e
end

tm=nil
fn='main.cfg'
loop do
  sleep 6
  begin
    s=File.stat(fn)
    if s.mtime != tm
      diag "config changed..."
      tm=s.mtime
      $jobset.load(File.read(fn))
    end
  rescue => e
    diag "E: #{e.inspect}"
  end
end
