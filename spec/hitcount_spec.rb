require 'cxxproject_gcov/gcov'

describe Gcov::Hitcount do

  def dead_count
    Gcov::Hitcount.new('#####')
  end
  def five_count
    Gcov::Hitcount.new('5')
  end
  def ignored_count
    Gcov::Hitcount.new('-')
  end

  it 'should parse dead code lines' do
    dead_count.count.should eq(:DEAD_CODE)
  end
  it 'should parse ignored lines' do
    ignored_count.count.should eq(:IGNORED)
  end
  it 'should parse counted lines' do
    five_count.count.should eq(5)
  end

  it 'should join dead with counted' do
    dead_count.join(five_count).count.should eq(5)
  end
  it 'should join two counted lines' do
    five_count.join(five_count).count.should eq(10)
  end
  it 'should join ignored with counted lines' do
    ignored_count.join(five_count).count.should eq(5)
  end

end
