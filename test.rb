require_relative 'src/jobset.rb'

require 'etc'

def diag(*s)
  unless s.size == 1 and s[0].is_a? String
    s=s.map{|x| x.inspect }
  end
  s=s.map{|x| ' '+x }.join('')
  STDOUT.puts "    #{Time.now.to_s}:#{s}"
  STDOUT.flush
end

def subrek(dir, components, name, cfg)
  # puts "subrek(#{dir.inspect}, #{components.inspect}, #{name.inspect})"
  if components.empty?
    # puts "   - end #{dir} #{name}"
    subcfg=JSON.parse(File.read(dir))
    %w( jobs procs ).each do |t|
      ents=subcfg[t]
      if ents
        ents.each do |k,v|
          cfg[t]||={}
          cfg[t][name+k]=v
        end
      end
    end
  else
    n=components[0]
    # puts "n #{n.inspect}"
    if n =~ /\A([^\*]*)\*([^\*]*)\Z/
      pre=$1
      post=$2
      # puts "#{pre.inspect} * #{post.inspect}"
      if File.directory?(dir)
        Dir.entries(dir).each do |e|
          if e.length > pre.length + post.length
            if e.start_with? pre and e.end_with? post
              subname=e[pre.length..-post.length-1]
              # puts "    take #{e.inspect} as #{subname.inspect}"
              subrek(File.join(dir,e), components[1..-1], name+subname+'/', cfg)
            end
          end
        end
      end
    end
  end
end

def do_subdirs(path, cfg)
  subrek('.',path.split('/'),'',cfg)
end

js=JobSet.new(false)
ps=JobSet.new(true)

$jobset=js # Dirty, but for now for the plugins

cfgfile=nil

def grep_procs(x)
  r=0
  File.popen('ps ax','r') do |f|
    f.each_line do |l|
      if l.index(x)
        r+=1
      end
    end
  end
  # We must exactly see ourselves. If we see
  # more the daemon is already running, if we
  # see less, we don't detect ourselves which
  # is bad.
  r != 1
end

logdir='log'

case ARGV[0]
when '--cron'
  ARGV.shift
  # Check if we already find ourselves (where
  # we need to consider that this invocation
  # must be discounted. We grep for the 'ruby'
  # in front b/c on NetBSD there is also the
  # /bin/sh -c with our path in it during the
  # cron execution. Systems are hard.
  exit if grep_procs('ruby '+$0+' --cron')

  # Start executing in the dir we are in.
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
when '--log'
  # Just run with redirected log,
  # mostly for good citizenship
  # with systemd (and its strange logging).
  ARGV.shift

  begin
    Dir.mkdir(logdir)
  rescue => e
    # nix
  end
  lf=File.open(logdir+'/runner.log','a')
  $stdout.reopen(lf)
  $stderr.reopen(lf)
  $stdin.reopen('/dev/null','r')
when /\A--user=([a-z][-0-9a-z]*)\Z/
  begin
    u=Etc.getpwnam($1)
    Process::Sys.setregid(u.gid,u.gid)
    Process::Sys.setreuid(u.uid,u.uid)
  rescue => e
    puts "Uid assumption failed: #{e.inspect}"
    exit 9
  end
  ARGV.shift
when /\A--su=([a-z][-0-9a-z]*)\Z/
  begin
    name=$1
    u=Etc.getpwnam(name)
    Process::Sys.setregid(u.gid,u.gid)
    Process::Sys.setreuid(u.uid,u.uid)
    ENV['HOME']=u.dir
    ENV['LOGNAME']=name
    ENV['USER']=name
  rescue => e
    puts "Uid assumption failed: #{e.inspect}"
    exit 9
  end
  ARGV.shift
end

ARGV.each do |a|
  case a
  when /^--logdir=/
    logdir=$'
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

      subdirs=cfg['.d']
      if subdirs.is_a? String
        do_subdirs(subdirs,cfg)
      end
      defcfg=cfg['config']
      ps.load_json(cfg['procs'],defcfg)
      js.load_json(cfg['jobs'],defcfg)

      # TODO: The parameters should somehow be part of the requires section
      # Hash, name is plugin, value is parameter (hash again, or anything).
      $plugin_params=cfg['plugin-params']||{}

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
  ps.checks
end
