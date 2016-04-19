require_relative 'src/jobset.rb'

js=JobSet.new(false)
ps=JobSet.new(true)

cfgfile='test.cfg'

ARGV.each do |a|
  cfgfile=a
end

puts "Config: #{cfgfile}"

while true do
  begin
    cfg=JSON.parse(File.read(cfgfile))
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
