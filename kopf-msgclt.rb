require 'rubygems'
require 'websocket-client-simple'
require 'json'

def msgclt_run(a,&blk)

  Thread.new do
    while true
      sleep 7
      begin

        ws = WebSocket::Client::Simple.connect a

        ws.on :message do |msg|
          begin
            j=JSON.parse(msg.data)
            blk.call(j['a'], j['d'], j['t'])
          rescue => e
            diag "E: #{e.inspect}"
            bt=e.backtrace
            if bt
              bt.each do |b|
                diag b.inspect
              end
            end
          end
        end

        ws.on :open do
          diag "ws: Opened"
          # ws.send 'hello!!!'
        end

        ws.on :close do |e|
          diag "ws: Closed #{e.inspect}"
          p e
          ws=nil
        end

        ws.on :error do |e|
          diag "ws: Error! #{e.inspect}"
          p e
          ws=nil
        end

        diag "ws: init"

        cnt=0
        while ws do
          cnt+=1
          if cnt > 20
            ws.send Time.now.to_s
            cnt=0
          end
          sleep 5
        end
      rescue => e
        diag "ws: error #{e.inspect}"
      end
    end
  end
end
