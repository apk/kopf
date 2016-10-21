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

    t=now_f
    @last_start=t
    @last_end=t

    @mutex=Mutex.new

    start_thread
  end

  def set_cfg(cfg)
    @mutex.synchronize do
      @cfg=cfg
      @thread.wakeup if @thread
    end
  end

  def kick(*a)
    @mutex.synchronize do
      @need||=[]
      @need+=a
      @thread.wakeup if @thread
    end
    start_thread
  end

  def cron(a)
    @cfg.cron(a,self) if @cfg
  end

  def start_thread
    @mutex.synchronize do

      unless @thread
        @thread=Thread.new do
          begin
            cfg=nil
            need=nil
            @mutex.synchronize do

              while true
                # Loop until it is time to run,
                # or we're gone.
                cfg=@cfg
                return unless cfg

                # Handle idle time. jobs have no idle default,
                # procs wait 30s between executions, unles
                # configured otherwise.
                idle=(cfg.idle || (@auto ? 30 : nil))
                now=now_f
                t=nil
                if idle
                  t=idle+@last_end
                  t=nil if t < now # Gone already.
                end
                # If t is set, we need to wait
                # at least til then.

                break if @need and not t

                if cfg.period
                  u=cfg.period+@last_start
                  t = u unless t and t > u
                end
                if cfg.pause
                  u=cfg.pause+@last_end
                  t = u unless t and t > u
                end

                # If we have neither period nor pause,
                # there is nothing to wait for. (If
                # we're still in idle, t won't be nil.)
                return unless t

                # Now wait for t to occur.
                t+=cfg.rand*rand if cfg.rand
                dt=t-now
                break if dt < 0.05
                begin
                  @mutex.sleep(dt)
                rescue Exception => e
                  puts e.inspect
                end
              end

              cfg=@cfg
              return unless cfg
              need=@need
              @need=@auto
            end

            # begin
            cmd=cfg.cmd
            if cmd
              dir=cfg.dir

              if cfg.logstart
                puts "+++ #{Time.now.to_s} #{cfg.title}"
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
                f.each_line do |l|
                  if cfg.logoutput
                    puts "        #{cfg.title}: #{l}"
                  end
                  if cfg.mailto
                    output.push(l)
                  end
                end
              end

              if cfg.mailto and not output.empty?
                cfg.mailto.each do |m|
                  begin
                    mailer=Mailer.new(cfg.mailfrom || m)
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

            else

              if cfg.logstart
                puts "=== #{Time.now.to_s} #{cfg.title}"
                STDOUT.flush
              end
              @last_start=now_f
              @last_end=now_f

            end

            cfg.trigger(@jobset)
            # rescue => e
            # puts "E: #{e.inspect}"
            # puts "B: #{e.backtrace.inspect}"
            # end

          ensure
            @mutex.synchronize do
              @thread=nil
            end
          end

          start_thread
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
