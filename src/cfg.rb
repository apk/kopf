require_relative "cron"

class Cfg

  class StatFileSet
    def initialize(files,cfg)
      @cfg=cfg
      @files=files||[]
      @stat=mapstat
    end

    def check
      stat=mapstat
      if stat != @stat
        @stat=stat
        return true
      end
      return false
    end

    def mapstat
      @files.map do |f|
        begin
          unless f[0] == '/'
            d=@cfg.dir
            if d
              f=d+'/'+f
            end
          end
          s=File::Stat.new(f)
          s=[s.mtime,s.size]
        rescue Errno::ENOENT
          s=nil
        rescue => e
          s=e.inspect
        end
      end
    end
  end

  def check(r,x,c)
    throw ArgumentError.new("#{x}(#{r.inspect}) is not a number") unless r.is_a? c
    r
  end

  def to_s
    @conf.inspect
  end

  def get_bool(x,dfl)
    r=@conf[x]
    r=dfl if r == nil
    if r != true and r != false
      throw ArgumentError.new("#{x}(#{r.inspect}) is not a bool")
    end
    r
  end

  def get_opt_str(x)
    r=@conf[x]
    if r
      check(r,x,String)
    end
  end

  def get_opt_str_def(x)
    r=@conf[x] || (@defcon && @defcon[x])
    if r
      check(r,x,String)
    end
  end

  def get_str(x)
    check(@conf[x],x,String)
  end

  def get_opt_strlist(x)
    r=get_opt_str_or_list(x)
    (r.is_a? String) ? [r] : r
  end

  def is_str_or_list(r)
    if r.is_a? String
      return r
    elsif r.is_a? Array
      r.each do |v|
        unless v.is_a? String
          return nil
        end
      end
      return r
    else
      return nil
    end
  end

  def get_opt_str_or_list(x)
    r=@conf[x]
    if r == nil
      return r
    else
      r=is_str_or_list(r)
      unless r
        throw ArgumentError.new("#{x}(#{r.inspect}) is not a string or string list")
      end
      return r
    end
  end

  def get_opt_int(x)
    r=@conf[x]
    if r
      check(r,x,Numeric)
    end
  end

  def get_int(x)
    check(@conf[x],x,Numeric)
  end

  attr_reader :title, :cmd, :dir, :idle, :pause, :period, :rand
  attr_reader :mailto, :mailfrom, :mailhost, :logstart, :logoutput

  def initialize(name,json,defcfg)
    @conf=json
    @defcon=defcfg
    @title=get_opt_str('title')||name
    @cmd=get_opt_str_or_list('command')
    @dir=get_opt_str('dir')
    @idle=get_opt_int('idle')
    @pause=get_opt_int('pause')
    @period=get_opt_int('period')
    @rand=get_opt_int('random')
    @mailto=get_opt_strlist('mail-to')
    @mailfrom=get_opt_str_def('mail-from')
    @mailhost=get_opt_str_def('mailhost')
    @logstart=get_bool('log-start',true)
    @logoutput=get_bool('log-output',false)

    @trigger=@conf['trigger']
    if @trigger
      unless is_str_or_list(@trigger)
        unless @trigger.is_a? Hash
          throw ArgumentError.new("(#{@trigger.inspect}) is not a string or string list, or hash of such")
        end
        @trigger.each_pair do |k,v|
          unless k.is_a? String and is_str_or_list(v)
            throw ArgumentError.new("(#{@trigger.inspect}) is not a string or string list, or hash of such")
          end
        end
      end
    end

    @restart_files=StatFileSet.new(get_opt_strlist('restart-on-file'),self)
    @hup_files=StatFileSet.new(get_opt_strlist('hup-on-file'),self)

    cron=@conf['cron']
    res=cron
    if cron
      if is_str_or_list(res)
        if res.is_a? String
          res=[res]
        end
        c={}
        res.each do |d|
          c[d]=[]
        end
        res=c
      end
      unless res.is_a? Hash
        throw ArgumentError.new("(#{cron.inspect}) is not a string or string list, or hash of such")
      end
      c={}
      res.each_pair do |k,v|
        unless k.is_a? String and is_str_or_list(v)
          throw ArgumentError.new("(#{cron.inspect}) is not a string or string list, or hash of such")
        end
        c[CronEntry.new(k)]=v
      end
      res=c
    end
    @cron=res
  end

  def trigger(jobset)
    if @trigger
      if @trigger.is_a? Hash
        @trigger.each_pair do |k,v|
          if v.is_a? Array
            jobset.kick(k,*v)
          else
            jobset.kick(k,v)
          end
        end
      elsif @trigger.is_a? Array
        @trigger.each do |a|
          jobset.kick(a)
        end
      else
        jobset.kick(@trigger)
      end
    end
  end

  def checks(job)
    s=@hup_files.check
    if @restart_files.check
      job.kill
    elsif s
      job.hup
    end
  end

  def cron(a,job)
    if @cron
      @cron.each_pair do |k,v|
        if k.match(*a)
          job.kick(*v)
        end
      end
    end
  end

end
