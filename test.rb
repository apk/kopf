require_relative 'src/jobset.rb'

js=JobSet.new(false)
ps=JobSet.new(true)

while true do
  begin
    cfg=JSON.parse(File.read('test.cfg'))
    ps.load_json(cfg['procs'])
    js.load_json(cfg['jobs'])
  rescue => e
    puts "E: #{e.inspect}"
    e.backtrace.each do |b|
      puts ":: #{b}"
    end
  end

  sleep (10)

end
