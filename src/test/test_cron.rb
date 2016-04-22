require 'test/unit'

require_relative '../cron'

class ExprTests < Test::Unit::TestCase

  def xpn(p,m=60)
    e=CronEntry::Expr.new(p)
    0.upto(m).select { |v| e.match(v) }
  end

  def test_expr
    assert_equal(xpn('*/15'), [0,15,30,45,60])
    assert_equal(xpn('7/15'), [7,22,37,52])
    assert_equal(xpn('!5',7), [0,1,2,3,4,6,7])
    assert_equal(xpn('!3-5',7), [0,1,2,6,7])
    assert_equal(xpn('2-4,6',7), [2,3,4,6])
    assert_equal(xpn('!2-4,6',7), [0,1,5,7])
    assert_equal(xpn('*,6',7), [0,1,2,3,4,5,6,7])
    assert_equal(xpn('*',7), [0,1,2,3,4,5,6,7])
    assert_equal(xpn('2-4,12-14'), [2,3,4,12,13,14])
  end

  def mpx(p,f,m=60)
    e=CronEntry.new(p)
    0.upto(m).select do |v|
      t=[1,2,3,4,5]
      t[f]=v
      e.match(*t)
    end
  end

  def test_list
    assert_equal(mpx('1-4; * 7/30; 10-12 # comment',1),
                 [1,2,3,4,7,10,11,12,37])
    assert_equal(mpx('* * 6 * *',2,7),
                 [6])
    assert_equal(mpx('* * 1-5,7 * *',2,7),
                 [1,2,3,4,5,7])
    assert_equal(mpx('* * * * 6',4,7),
                 [6])
    assert_equal(mpx('* * * * 1-5,7',4,7),
                 [1,2,3,4,5,7])
    assert_equal(mpx('* * * * !6',4,7),
                 [0,1,2,3,4,5,7])
    assert_equal(mpx('3-6; * 7/30; * * 3 * !6 # comment',4,7),
                 [0,1,2,3,4,5,7])
    assert_equal(mpx('4,6,5 * * *',0,7),
                 [4,5,6])
    assert_equal(mpx('* 4,6,5 * *',1,7),
                 [4,5,6])
    assert_equal(mpx('* * 4,6,5 * *',2,7),
                 [4,5,6])
    assert_equal(mpx('* * * 4,6,5 *',3,7),
                 [4,5,6])
    assert_equal(mpx('* * * * 4,6,5',4,7),
                 [4,5,6])
  end
    
end
