require 'net/smtp'

class Mailer

  def initialize(from,name=nil,mailhost:'mailhost')
    @from=from
    @name=from
    @host=mailhost
    if name
      @name="#{name} <#{from}>"
    end
  end

  def send(to, subject, body)
    msg="From: #{@name}
To: #{to}
Auto-submitted: auto-generated
Subject: #{subject}

"+body+"

--
Run at #{Dir.getwd} #{ENV['HOSTNAME']}
"

    begin
      Net::SMTP.start(@host) do |smtp|
        smtp.send_message(msg, @from, to)
      end
    rescue => e
      puts "Mail error sending from #{@from.inspect} to #{to.inspect} via #{@host.inspect}: #{e.inspect}"
    end

  end

end
