require_relative 'src/jobset.rb'

js=JobSet.new

while true do
  begin
    js.load(File.read('test.cfg'))
  rescue => e
    puts "E: #{e.inspect}"
  end

  sleep (10)

end
