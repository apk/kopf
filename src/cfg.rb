class Cfg

  def check(r,x,c)
    throw ArgumentError.new("#{x}(#{r.inspect}) is not a number") unless r.is_a? c
    r
  end

  def to_s
    @conf.inspect
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
    r=@conf[x]
    if r == nil
      return r
    elsif r.is_a? String
      return [r]
    elsif r.is_a? Array
      r.each do |v|
        unless v.is_a? String
          throw ArgumentError.new("#{x}(#{r.inspect}) is not a string")
        end
      end
    else
      throw ArgumentError.new("#{x}(#{r.inspect}) is not a string or string list")
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

  attr_reader :title, :cmd, :pause, :period, :rand, :mails

  def initialize(name,json)
    @conf=json
    @title=get_opt_str('title')||name
    @cmd=get_str('command')
    @pause=get_opt_int('pause')
    @period=get_opt_int('period')
    @rand=get_opt_int('random')
    @mails=get_opt_strlist('mail-to')
  end

end
