require 'cgi'
require 'cxxproject_gcov/gcov'
class HtmlExport

  def initialize(out_dir, gcov_for_files, base_dir)
    @out_dir = out_dir
    @gcov_for_files = gcov_for_files
    @base_dir = base_dir
    export_css()
    export_toc()
    export_sources()
  end
  def export_css()
    open_for_write(File.join(@out_dir, 'gcov.css')) do |out|
      data = File.read(File.join(File.dirname(__FILE__), 'gcov.css'))
      out.puts(data)
    end
  end
  def export_toc
    output_file_name = File.join(@out_dir, 'index.html')
    open_for_write(output_file_name) do |out|
      out.puts("<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"gcov.css\"></head><body>")
      
      out.puts("<table><tr><th>Sourcefile</th><th>Loc</th><th>Coverage in %</th></tr>")
      total_lines = 0
      total_covered_lines = 0
      @gcov_for_files.each do |file, coverage|
        puts "working on #{file}"
        relative_file = file.gsub(@base_dir, '')
        stats = Gcov::FileStatistics.new(coverage)
        total_lines += stats.total_lines_of_code
        total_covered_lines += stats.covered_lines
        coverage = stats.coverage
        covered_style = coverage == 100 ? 'covered' : 'not_covered'
        out.puts("<tr class=\"#{covered_style}\"><td><a href=\"#{relative_file}.html\">#{relative_file}</a></td><td>#{stats.total_lines_of_code}</td><td>#{coverage}</td></tr>")
      end
      covered = (100 * (total_covered_lines.to_f / total_lines)).to_i
      out.puts("<tr><td>TOTAL</td><td>#{total_lines}</td><td>#{covered}</td></tr>")
      out.puts("</table>")
      out.puts("</body></html>")
    end
  end

  def export_sources
    @gcov_for_files.each do |file, coverage|
      relative_file = file.gsub(@base_dir, '')
      output_file_name = File.join(@out_dir, relative_file + '.html')
      path_to_stylesheet = calc_path_to_stylesheet(output_file_name, @out_dir)
      if path_to_stylesheet.size > 0
        path_to_stylesheet = File.join(path_to_stylesheet, 'gcov.css')
      else
        path_to_stylesheet = 'gcov.css'
      end
      open_for_write(output_file_name) do |out|
        out.puts("<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"#{path_to_stylesheet}\"></head><body><pre>")
        coverage.each do |line|
          line_number = sprintf("%5d:", line.line_number)
          count_state = count_state_to_css_class(line.hit_count)
          out.puts("<span class=\"#{count_state} linenumber\">#{line_number}</span><span class=\"#{count_state}\">#{CGI.escape_html(line.code)}</span>")
        end
        out.puts("</pre></body></html>")
      end
    end
  end

  def ensure_dir_for_file(output_file_name)
    FileUtils.mkdir_p(File.dirname(output_file_name))
  end

  def open_for_write(output_file_name)
    ensure_dir_for_file(output_file_name)
    File.open(output_file_name, 'w') do |out|
      yield out
    end
  end

  def count_state_to_css_class(hit_count)
    mapping = {:DEAD_CODE => 'dead_code', :IGNORED => 'ignored_code'}
    if mapping.has_key?(hit_count.count)
      return mapping[hit_count.count]
    else
      return 'used_code'
    end
  end

  def calc_path_to_stylesheet(output, base)
    count = output.split('/').size - base.split('/').size - 1
    return ('../' * count)[0...-1]
  end

end
