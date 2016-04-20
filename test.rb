require_relative 'src/jobset.rb'

def diag(s)
  STDERR.puts "    #{Time.now.to_s}: #{s}"
end

js=JobSet.new(false)
ps=JobSet.new(true)

$jobset=js # Dirty, but for now for the plugins

cfgfile='test.cfg'

ARGV.each do |a|
  cfgfile=a
end

cfgdir='.'
if cfgfile =~ /\/([^\/]+)/
  cfgdir=$'
  cfgfile=$1
end

Dir.chdir cfgdir

puts "Config: #{cfgfile}"

tm=nil
while true
  begin
    s=File.stat(cfgfile)
    if s.mtime != tm
      diag "Config #{cfgfile.inspect} changed..."
      tm=s.mtime
      cfg=JSON.parse(File.read(cfgfile))
      ps.load_json(cfg['procs'])
      js.load_json(cfg['jobs'])

      reqs=cfg['requires']
      if reqs
        if reqs.is_a? String
          reqs=[reqs]
        end
        if reqs.is_a? Array
          reqs.each do |r|
            if r.is_a? String
              diag "Load: #{r.inspect}"
              require './'+r
            end
          end
        end
      end
    end
  rescue => e
    puts "E: #{e.inspect}"
    e.backtrace.each do |b|
      puts ":: #{b}"
    end
  end
  sleep 10
end
