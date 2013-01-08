require 'ostruct'

module Gcov
  @@excludes = []
  class << self
    def excludes
      @excludes = [] unless @excludes
      return @excludes
    end
    def excludes=(e)
      @excludes = e
    end
  end

  class FileStatistics
    attr_reader :total_lines_of_code
    def initialize(lines)
      @total_lines_of_code = lines.select{|i|i.hit_count.counts?}.size
      @dead_lines_of_code = lines.select{|i|i.hit_count.count == :DEAD_CODE}.size
      @ignored_lines_of_code = lines.select{|i|i.hit_count.count == :IGNORED}.size
    end
    def covered_lines
      return @total_lines_of_code - @dead_lines_of_code
    end
    def coverage
      covered = covered_lines()
      result = (100 * (covered.to_f / @total_lines_of_code)).to_i
      if covered < @total_lines_of_code
        if result == 100
          result = 99
        end
      end
      return result
    end
  end

  class Hitcount
    attr_reader :count
    def counts?
      if @count == :DEAD_CODE
        return true
      elsif @count == :IGNORED
        return false
      else
        return true
      end
    end

    def initialize(s)
      if s.match('#+')
        @count = :DEAD_CODE
      elsif s == '-'
        @count = :IGNORED
      else
        @count = s.to_i
      end
    end
    def join(other)
      if @count == :DEAD_CODE
        if other.count == :DEAD_CODE
        elsif other.count == :IGNORED
        else
          @count = other.count
        end
      elsif @count == :IGNORED
        if other.count == :DEAD_CODE
          @count = :DEAD_CODE
        elsif other.count == :IGNORED
        else
          @count = other.count
        end
      else
        if other.count == :DEAD_CODE
        elsif other.count == :IGNORED
        else
          @count += other.count
        end
      end
      self
    end
  end
  
  def self.match_to_line(match)
=begin
lines look like this:
    4:   30:    }
    -:   31:
#####:   32:    void Timestamp::unused() {
=end
    hit_count = Hitcount.new(match[1].strip)
    line_number = match[2].strip.to_i
    code = match[3]
    OpenStruct.new({:hit_count => hit_count, :line_number => line_number, :code => code})
  end

  def self.parse_gcov_string(str)
    line_regexp = Regexp.new('(.*?):(.*?):(.*)')
    matches = str.each_line.map{|i|i.match(line_regexp)}
    return matches.map{|match|match_to_line(match)}.delete_if{|line|line.line_number == 0}
  end
  
  def self.simplify_path(p)
    path_elements = p.split('/')
    path_elements = path_elements.delete_if{|i|i == '.'}
    new_elements = []
    path_elements.each do |i|
      if i == '..'
        if new_elements.size > 0
          new_elements.pop
        else
          new_elements << i
        end
      else
        new_elements << i
      end
    end
    return new_elements.join('/')
  end

  def self.replace_hash_with_slash(f)
    f.gsub('#', '/')
  end

  def self.get_source_file(file)
    res = ''
    if not file.index('#')
      # no #
      res = file
    elsif file.index('##')
      # two or more ##
      res = replace_hash_with_slash(file[0...file.index('##')])
    else
      # one #
      res = replace_hash_with_slash(file)
    end
    return simplify_path(res.gsub('.gcov', ''))
  end

  def self.get_other_file(file)
    res = ''
    if not file.index('#')
      # no #
      return nil
    elsif file.index('##')
      # 2 or 3 ###
      res = simplify_path(replace_hash_with_slash(file[file.index('##')+2..-1]).gsub('.gcov', ''))
    else
      return nil
    end
  end

  def self.calc_source_and_visited(s)
    return [get_source_file(s), get_other_file(s)]
  end

  # gcovs is array of gov-files
  # gcov-files are arrays of lines
  # lines are [Hitcount, linenr, content]
  def self.merge_gcovs(gcovs)
    gcovs.inject do |one,other|
      one.zip(other).map do |a,b|
        OpenStruct.new({:hit_count => a.hit_count.join(b.hit_count), :line_number => a.line_number, :code => a.code})
      end
    end
  end

end
