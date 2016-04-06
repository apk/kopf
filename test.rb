require_relative 'src/jobset.rb'

js=JobSet.new

while true do
  begin
    js.load(File.read('test.cfg'))
  rescue => e
    puts "E: #{e.inspect}"
    e.backtrace.each do |b|
      puts ":: #{b}"
    end
  end

  sleep (10)

end
