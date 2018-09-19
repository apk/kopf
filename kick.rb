require 'socket'

if ARGV.size < 1
  puts "Need job argument"
  exit 1
end

Socket.unix("sock") do |sock|
  puts "Connection open..."
  sock.puts "kick "+ARGV.join(' ')
  sock.flush
  sleep 1   # TODO: There is something borken in the receiver - EOF overrides reading?
  sock.shutdown
  sock.each_line do |r|
    puts '* '+r
  end
end
