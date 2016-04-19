class Cfg

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

  attr_reader :title, :cmd, :idle, :pause, :period, :rand
  attr_reader :mailto, :mailfrom, :logstart, :logoutput

  def initialize(name,json)
    @conf=json
    @title=get_opt_str('title')||name
    @cmd=get_opt_str_or_list('command')
    @idle=get_opt_int('idle')
    @pause=get_opt_int('pause')
    @period=get_opt_int('period')
    @rand=get_opt_int('random')
    @mailto=get_opt_strlist('mail-to')
    @mailfrom=get_opt_strlist('mail-from')
    @logstart=get_bool('log-start',true)
    @logoutput=get_bool('log-output',false)

    @trigger=@conf['trigger']
    if @trigger
      unless is_str_or_list(@trigger)
        unless @trigger.is_a? Hash
        throw ArgumentError.new("(#{@trigger.inspect}) is not a string or string list, or hash of such")
          @trigger.each_pair do |k,v|
            unless k.is_a? String and is_str_or_list(v)
              throw ArgumentError.new("(#{@trigger.inspect}) is not a string or string list, or hash of such")
            end
          end
        end
      end
    end
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

end
