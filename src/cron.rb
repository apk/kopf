class CronEntry

  class Range
    def initialize(e)
      @skip=nil
      if e =~ /\/([1-9][0-9]*)$/
        @skip=$1.to_i
        e=$`
      end
      if e =~ /^([0-9]+)-([0-9]+)$/
        @start=$1.to_i
        @end=$2.to_i
      elsif e =~ /^([0-9]+)$/
        @start=$1.to_i
        @end=(@skip ? 60 : @start)
      elsif e == '*'
        @start=0
        @end=60 # Enough for everything practical
      else
        throw ArgumentError.new("bad data #{e.inspect}")
      end
      @skip ||= 1
    end

    def match(v)
      if v >= @start and v <= @end
        v-=@start
        if v % @skip == 0
          return true
        end
      end
      return false
    end
  end

  class Expr
    def initialize(s)
      @inv=false
      if s =~ /^!/
        @inv=true
        s=$'
      end
      @ranges=s.split(/,/).map do |e|
        Range.new(e)
      end
    end

    def match(v)
      if @ranges.any? { |x| x.match(v) }
        !@inv
      else
        @inv
      end
    end
  end

  def initialize(s)

    # a; b - multiple entries
    # a #c - comment
    # 1 to 5 ents in pattern, one is minute,
    # two is hour, minute, then day of month, month, day of week
    # all non-* must match

    #  */2
    #  0-4/2
    #  0-4/2,5
    #  1-5,9-12

    if s =~ /#/
      s=$`
    end

    @entlist=s.split(/;/).map do |e|
      a=e.strip.split(/\s+/)
    
      if a.size > 5
        throw ArgumentError.new("too many ents in #{e.inspect}")
      end
      if a.size < 1
        throw ArgumentError.new("too few ents in #{e.inspect}")
      end

      a.map do |ae|
        Expr.new(ae)
      end
    end
  end

  def match(hr,mn,dy,mo,wk)
    @entlist.any? do |e|
      if e.size == 1
        e[0].match(mn)
      else
        e.size < 1 or
        (e[0].match(hr) and
         (e.size < 2 or 
          (e[1].match(mn) and
           (e.size < 3 or
            (e[2].match(dy) and
             (e.size < 4 or
              (e[3].match(mo) and
               (e.size < 5 or
                (e[4].match(wk))))))))))
      end
    end
  end
end
