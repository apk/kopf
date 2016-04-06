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

  def initialize(cfg,jobset)
    @jobset=jobset
    @cfg=cfg

    @thread=nil
    @need=nil

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

  def start_thread
    @mutex.synchronize do

      unless @thread
        @thread=Thread.new do
          begin
            cfg=nil
            need=nil
            @mutex.synchronize do

              while not @need
                cfg=@cfg
                return unless cfg
                t=nil
                if cfg.period
                  t=cfg.period+@last_start
                end
                if cfg.pause
                  u=cfg.pause+@last_end
                  t = u unless t and t > u
                end
                return unless t
                t+=cfg.rand*rand if cfg.rand
                dt=t-now_f
                break if dt < 0.05
                begin
                  @mutex.sleep(dt)
                rescue Exception =>e
                  puts e.inspect
                end
              end

              cfg=@cfg
              return unless cfg
              need=@need
              @need=nil
            end

            cmd=cfg.cmd
            if cmd
              puts "+++ #{Time.now.to_s} #{cfg.title}"
              STDOUT.flush
              if cmd.is_a? String
                need.each do |n|
                  cmd=cmd+' '+n
                end
              else
                cmd=cmd+need
              end
              @last_start=now_f
              system(*cmd)
              @last_end=now_f
              puts "--- #{Time.now.to_s} #{cfg.title} #{(@last_end-@last_start).to_i}"
              STDOUT.flush
            else
              puts "=== #{Time.now.to_s} #{cfg.title}"
              STDOUT.flush
              @last_start=now_f
              @last_end=now_f
            end
            cfg.trigger(@jobset)

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
