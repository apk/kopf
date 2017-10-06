require_relative 'mailer'

class Runner

  @@joinlist||=[]

  def now_f
    Time.now.to_f
  end

  def dead
    @mutex.synchronize do
      return (not @thread and not @cfg)
    end
  end

  def initialize(cfg,jobset,auto)
    @auto=(auto ? [] : nil)

    @jobset=jobset
    @cfg=cfg

    @thread=nil
    @need=@auto
    @needtime=now_f

    @last_start=nil
    @last_end=nil
    @cnt=0

    @mutex=Mutex.new

    start_thread
  end

  def set_cfg(cfg)
    @mutex.synchronize do
      @cfg=cfg
      @thread.wakeup if @thread
    end
  end

  def kill
    puts "RESTART: #{@cfg.title}"
    Process.kill('TERM', @pid)
  end

  def hup
    puts "HUP: #{@cfg.title}"
    Process.kill('HUP', @pid)
  end

  def kick(*a)
    @mutex.synchronize do
      unless @need
        @need=[]
        @needtime=now_f
      end
      @need+=a
      @thread.wakeup if @thread
    end
    start_thread
  end

  def cron(a)
    @cfg.cron(a,self) if @cfg
  end

  def checks
    @cfg.checks(self) if @cfg
  end

  class Next
    def initialize
      @t=nil
    end

    def shorten(val,start)
      if val
        u=val+start
        @t=u unless @t and @t < u
      end
    end

    def extend(val,start,dflt=nil)
      if val
        if dflt and not start
          start=dflt
          val=val*rand
        end
        if start
          u=val+start
          @t=u unless @t and @t > u
        end
      end
    end

    def add(val)
      @t+=val if @t
    end

    def clear?
      @t==nil
    end

    def pt
      @t
    end

  end

  def exec
    cfg=nil
    need=nil
    rnd=rand # Want a contant value per round
    @mutex.synchronize do

      while true
        # Loop until it is time to run,
        # or we're gone.
        cfg=@cfg
        return false unless cfg

        now=now_f
        t=Next.new

        if cfg.period or cfg.pause
          t.extend(cfg.period,@last_start,@needtime)
          t.extend(cfg.pause,@last_end,@needtime)
          t.add(cfg.rand*rnd) if cfg.rand
        end

        if @need
          # Handle idle time. Jobs run immediately when kicked
          # and no idle time is set; procs wait 10s between
          # executions by default.
          #
          # idle only applies when triggered or a proc
          # (where @need is also set).
          idle=(cfg.idle || (@auto ? 10 : 0))
          t.shorten(idle,@needtime)
        end

        # If we have nothing to wait for (not even
        # in the past, i.e. 'idle' is over), we are
        # a job without configured times, and can stop when
        # not '@need'ed.

        if t.clear?
          break if @need # Execute need
          return false # Stop and wait for trigger
        end

        # Now wait for t to occur.
        dt=t.pt-now
        break if dt < 0.05
        begin
          @mutex.sleep(dt)
        rescue => e
          puts 'E:'+e.inspect
        end
      end

      cfg=@cfg
      return false unless cfg
      need=@need
      @need=nil
    end

    # begin
    cmd=cfg.cmd
    if cmd
      dir=cfg.dir

      @cnt+=1
      if cfg.logstart
        puts "+++ #{Time.now.to_s} #{cfg.title} ##{@cnt}"
        STDOUT.flush
      end
      if need
        if cmd.is_a? String
          need.each do |n|
            cmd=cmd+' '+n
          end
        else
          cmd=cmd+need
        end
      end

      @last_start=now_f
      output=[]
      opts={ err: [:child, :out] }
      opts[:chdir]=dir if dir
      IO.popen(cmd,'r',opts) do |f|
        @pid=f.pid
        f.each_line do |l|
# Doing partial mail output sometime?
# In a separate thread?
          if cfg.logoutput
            puts "        #{cfg.title}: #{l}"
            STDOUT.flush
          end
          if cfg.mailto
            output.push(l)
          end
        end
        @pid=nil
      end

      if cfg.mailto and not output.empty?
        cfg.mailto.each do |m|
          begin
            mailer=Mailer.new(cfg.mailfrom || m, mailhost: cfg.mailhost)
            mailer.send(m,
                        ("#{ENV['USER']||ENV['LOGNAME']}@#{ENV['HOSTNAME']}:"+
                         " Job '#{cfg.title}' output"),
                        output.join("\n"))
          rescue => e
            puts "E: #{e.inspect}"
            puts "B: #{e.backtrace.inspect}"
          end
        end
      end

      @last_end=now_f
      if cfg.logstart
        puts "--- #{Time.now.to_s} #{cfg.title} #{(@last_end-@last_start).to_i}"
        STDOUT.flush
      end

      if $$ == 1
        while true
          begin
            break unless Process.waitpid(-1,Process::WNOHANG)
          rescue => e
            break
          end
        end
      end

    else

      if cfg.logstart
        puts "=== #{Time.now.to_s} #{cfg.title}"
        STDOUT.flush
      end
      @last_start=now_f
      @last_end=now_f

    end
    # Set so we always wait 'idle' after a run.
    @needtime=now_f

    if @auto and not @need
      @need=@auto
    end

    cfg.trigger(@jobset)

    true
  end

  def start_thread
    @mutex.synchronize do

      unless @thread
        @thread=Thread.new do
          need=false
          begin

            need=exec

          rescue => e
            puts "Thread died by #{e.inspect}"
            begin
              e.backtrace.each do |f|
                puts 'L: '+f
              end
            rescue => ee
              puts "Double died by #{ee.inspect}"
            end
            sleep 1
          ensure
            @mutex.synchronize do
              @thread=nil
            end
          end

          start_thread if need
          while true do
            c=@@joinlist.shift
            break unless c
            c.join
          end
          @@joinlist.push(Thread.current)
        end
      end
    end
  end
end
