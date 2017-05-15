require 'json'

require_relative 'cfg'
require_relative 'runner'

class JobSet

  def initialize(auto)
    @auto=auto
    @jobs={}
  end

  def load(txt)
    load_json(JSON.parse(txt))
  end

  def load_json(json)

    newcfg={}
    if json
      json.each_pair do |k,v|
        newcfg[k]=Cfg.new(k,v)
      end
    end

    newcfg.each_pair do |n,c|
      p=@jobs[n]
      if p
        p.set_cfg(c)
      else
        @jobs[n]=Runner.new(c,self,@auto)
      end
    end
    @jobs.each_pair do |n,j|
      j.set_cfg(nil) unless newcfg[n]
    end
    cleanup
  end

  def cleanup
    @jobs.delete_if do |n,j|
      j.dead
    end
  end

  def kick(n, *a)
    j=@jobs[n]
    j.kick(*a) if j
  end

  def cron(*a)
    @jobs.each do |k,v|
      v.cron(a)
    end
  end

  def checks
    @jobs.each do |k,v|
      v.checks
    end
  end

end
