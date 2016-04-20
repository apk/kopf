require 'rubygems'
require 'websocket-client-simple'
require 'json'

def proc_msg(x)
  begin
    j=JSON.parse(x)
    a=j['a']
    d=j['d']
    if d.is_a? String
      d=[d]
    else
      d=[]
    end
    # puts "#{a.inspect} #{d.inspect}" if a[0] == 'bridge'
    if a == ['bridge','trigger','rfd']
      $jobset.kick('rfd',*d)
    elsif a == ['bridge','trigger','baseline']
      $jobset.kick('baseline',*d)
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
