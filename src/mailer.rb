require 'net/smtp'

class Mailer

  def initialize(from)
    @from=from
  end

  def send(to, subject, body)
    msg="From: #{@from}
To: #{to}
Subject: #{subject}

"+body+"

--
Run at #{Dir.getwd} #{ENV['HOSTNAME']}
"

    begin
      Net::SMTP.start('localhost') do |smtp|
        smtp.send_message(msg, @from, to)
      end
    rescue => e
      puts "Mail error sending to #{to}: #{e.inspect}"
    end

  end

end
