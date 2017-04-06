require_relative 'kopf-msgclt'

a='ws://msgsrv/msg/ws'

msgclt_run(a) do |a,d,t|
  if d.is_a? String
    d=[d]
  else
    d=[]
  end
  # puts "#{a.inspect} #{d.inspect}" if a[0] == 'bridge'
  if a == ['bridge','trigger','rfd']
    $jobset.kick('rfd',*d)
  elsif a == ['bridge','trigger','baseline']
    $jobset.kick('baseline',*d)
  end
end
