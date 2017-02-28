require_relative 'src/jobset.rb'

def diag(s)
  STDOUT.puts "    #{Time.now.to_s}: #{s}"
  STDOUT.flush
end

js=JobSet.new(false)
ps=JobSet.new(true)

$jobset=js # Dirty, but for now for the plugins

cfgfile=nil

def grep_procs(x)
  r=0
  File.popen('ps ax','r') do |f|
    f.each_line do |l|
      if l.index($0)
        r+=1
      end
    end
  end
  r > 1
end

logdir='log'

ARGV.each do |a|
  case a
  when /^--logdir=/
    logdir=$'
  when '--cron'
    if grep_procs(' '+$0)
      exit
    end
    Dir.chdir($0.sub(/\/[^\/]+$/,''))
    begin
      Dir.mkdir(logdir)
    rescue => e
      # nix
    end
    exit! if fork
    lf=File.open(logdir+'/runner.log','a')
    $stdout.reopen(lf)
    $stderr.reopen(lf)
    $stdin.reopen('/dev/null','r')
  when /^-/
    puts "Extra option #{a.inspect} ignored"
  else
    if cfgfile
      puts "Extra argument #{a.inspect} ignored"
    else
      cfgfile=a
    end
  end
end

cfgfile||='kopf.cfg'

cfgdir='.'
if cfgfile =~ /\/([^\/]+)$/
  cfgdir=$`
  cfgfile=$1
end

Dir.chdir cfgdir

puts "Config: #{cfgfile}"
STDOUT.flush

tm=nil
first=true
while true
  begin
    s=File.stat(cfgfile)
    if s.mtime != tm
      diag "Config #{cfgfile.inspect} changed..." unless first
      first=false
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
    STDOUT.flush
  end
  t=Time.now.to_i
  sleep (60 - (t % 60))
  t=Time.now
  js.cron(t.hour, t.min, t.day, t.month, t.wday)
end
