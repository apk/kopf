require 'socket'

Socket.unix("sock") {|sock|
  puts "Connection open..."
  t = Thread.new do
    sock.each_line do |r|
      puts '* '+r
    end
    puts "EOF"
  end
  STDIN.each_line do |l|
    sock.write(l)
    sock.flush
  end
  puts "Done"
  sock.shutdown
  t.join
}
