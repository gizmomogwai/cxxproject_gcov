require 'cxxproject_gcov/gcov'

describe Gcov do

  it '1' do
    Gcov.calc_source_and_visited('/home/ckoestlin/_projects/ptp/src/ptp#timestamp.cpp##.#ptp#timestamp.h.gcov').should eq(['/home/ckoestlin/_projects/ptp/src/ptp/timestamp.cpp', 'ptp/timestamp.h'])
  end

  it '2' do
    Gcov.calc_source_and_visited('/home/ckoestlin/_projects/ptp/test/timestamp_test.cpp##..#src#.#ptp#timestamp.h.gcov').should eq(['/home/ckoestlin/_projects/ptp/test/timestamp_test.cpp', '../src/ptp/timestamp.h'])
  end


  it 'should work' do
    Gcov.calc_source_and_visited('test/timestamp_test2.cpp###usr#include#c++#4.6#bits#char_traits.h.gcov').should eq(['test/timestamp_test2.cpp', '/usr/include/c++/4.6/bits/char_traits.h'])
  end

  it 'should work for ' do
    Gcov.calc_source_and_visited('src/ptp#timestamp.cpp##.#ptp#timestamp.h.gcov').should eq(['src/ptp/timestamp.cpp', 'ptp/timestamp.h'])
  end

  it 'should also work' do
    Gcov.calc_source_and_visited('/home/gizmo/Dropbox/Documents/_projects/cxx with space/examples/gtest/small-tests2.cpp##gtest-1.6.0#fused-src#gtest#gtest.h.gcov').should eq(['/home/gizmo/Dropbox/Documents/_projects/cxx with space/examples/gtest/small-tests2.cpp', 'gtest-1.6.0/fused-src/gtest/gtest.h'])
  end

  it 'should simplify . in the middle' do
    Gcov.simplify_path('test/./test2').should eq('test/test2')
  end

  it 'should simplify . at the start' do
    Gcov.simplify_path('./test/test2').should eq('test/test2')
  end

  it 'should remove .. in the middle' do
    Gcov.simplify_path('test/../test2').should eq('test2')
  end

  it 'should parse gcov file strings' do
data = 
<<-eos
        -:    0:Source:ptp/timestamp.cpp
        -:    0:Graph:/home/ckoestlin/_projects/ptp/src/../out/objects/ptp/ptp/timestamp.gcno
        -:    0:Data:/home/ckoestlin/_projects/ptp/src/../out/objects/ptp/ptp/timestamp.gcda
        -:    0:Runs:1
        -:    0:Programs:1
        -:    1:#include <ptp/timestamp.h>
        -:    2:
        -:    3:namespace ptp
        -:    4:{
        -:    5:
        1:    6:    Delta Timestamp::deltaTo(const Timestamp &other) const
        -:    7:    {
        1:    8:        return Delta(other.mSeconds - mSeconds, other.mNanoSeconds - mNanoSeconds);
        -:    9:    }
        -:   10:
        4:   11:    Timestamp Timestamp::add(const Delta &other) const
        -:   12:    {
        4:   13:        Timestamp res(mSeconds + other.mSeconds, mNanoSeconds + other.mNanoSeconds);
        4:   14:        res.normalize();
        4:   15:        return res;
        -:   16:    }
        -:   17:
        4:   18:    void Timestamp::normalize()
        -:   19:    {
       10:   20:        while (mNanoSeconds >= ONE_SECOND_IN_NANOSECONDS)
        -:   21:        {
        2:   22:            ++mSeconds;
        2:   23:            mNanoSeconds -= ONE_SECOND_IN_NANOSECONDS;
        -:   24:        }
        9:   25:        while (mNanoSeconds < 0)
        -:   26:        {
        1:   27:            --mSeconds;
        1:   28:            mNanoSeconds += ONE_SECOND_IN_NANOSECONDS;
        -:   29:        }
        4:   30:    }
        -:   31:
    #####:   32:    void Timestamp::unused() {
    #####:   33:        mSeconds++;
    #####:   34:        mNanoSeconds++;
    #####:   35:    }
        -:   36:
        -:   37:}
eos
    result = Gcov.parse_gcov_string(data)
    result.size.should eq(37)
    result[5].hit_count.count.should eq(1)
    result[5].line_number.should eq(6)
    result[5].code.strip.should start_with('Delta')
    
    result[4].hit_count.count.should eq(:IGNORED)
    result[4].line_number.should eq(5)
    result[4].code.should eq('')

    result[31].hit_count.count.should eq(:DEAD_CODE)
    result[31].line_number.should eq(32)
    result[31].code.strip.should start_with('void Timestamp::unused')
  end

  it 'should merge gcov files' do
    lines = ['5:10:test', '7:10:test'].map{|i|Gcov.parse_gcov_string(i)}
    lines[0][0].hit_count.count.should eq(5)
    lines[1][0].hit_count.count.should eq(7)
    result = Gcov.merge_gcovs(lines)
    result[0].hit_count.count.should eq(12)
    result[0].line_number.should eq(10)
    result[0].code.should eq('test')
  end

  it 'excludes should work' do
    Gcov.excludes.should_not be_nil
    Gcov.excludes << 'test'
    Gcov.excludes.should eq(['test'])
  end

end
