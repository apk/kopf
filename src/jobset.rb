require 'json'

require_relative 'cfg'
require_relative 'runner'

class JobSet

  def initialize
    @jobs={}
  end

  def load(txt)
    json=JSON.parse(txt)

    newcfg={}
    json.each_pair do |k,v|
      newcfg[k]=Cfg.new(k,v)
    end

    newcfg.each_pair do |n,c|
      p=@jobs[n]
      if p
        p.set_cfg(c)
      else
        @jobs[n]=Runner.new(c)
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

  def kick(n)
    j=@jobs[n]
    j.kick if j
  end

end
