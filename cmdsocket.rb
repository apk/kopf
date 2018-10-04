require 'socket'

def handle_socket(conn)
  Thread.new do
    conn.puts "kopf!"
    conn.flush
    conn.each_line do |line|
      a=line.split
      if a[0]=='kick' && a.size > 1
        begin
          $jobset.kick(*a[1..-1])
          conn.puts 'ok (or not)'
        rescue => e
          conn.puts "Error: #{e.inspect}"
        rescue Exception => e
          conn.puts "Exc: #{e.inspect}"
        end
      else
        conn.puts "wat? #{line.inspect}"
      end
      conn.flush
    end
    puts "End of socket"
    conn.close
  end
end

Thread.new do
  sockpath=$plugin_params['cmdsocket']||{}
  sockpath=sockpath['socket-path']||'sock'
  begin
    File.unlink(sockpath)
  rescue Errno::ENOENT
    #
  rescue => e
    puts "unlink sock: #{e.inspect}"
  end

  socket = UNIXServer.open(sockpath)

  while true
    handle_socket(socket.accept)
  end
end
