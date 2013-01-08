require 'cxxproject_gcov/gcov'
require 'cxxproject_gcov/html_export'

cxx_plugin do |ruby_dsl, building_blocks, log|

  def handle_has_sources(building_block)
    if building_block.kind_of?(Cxxproject::HasSources)
      building_block.collect_sources_and_toolchains.each do | source, toolchain |
        cd(building_block.project_dir, :verbose => false) do
          sh "gcov -l -p -o \"#{File.join(building_block.project_dir, building_block.get_object_file(source))}\" \"#{source}\""
        end
      end
    end
  end

  def find_absolute_files(gcov_files)
    return gcov_files.select{|f|f.index('###')}.map{|f|'/' + f.match(/.*###(.*)/)[1].gsub('#', '/').gsub('.gcov', '')}
  end

  def is_absolute?(file)
    return file[0] == '/'
  end

  def find_building_block_for_source(building_blocks, to_find)
    building_blocks.each do |building_block|
      building_block.collect_sources_and_toolchains.each do |source, toolchain|
        h = File.join(building_block.project_dir, source)
        if h === to_find
          return building_block
        end
      end
    end
    return nil
  end

  def find_file(file, building_blocks)
    with_sources = building_blocks.select {|bb|bb.kind_of?(Cxxproject::HasSources)}
    source, visited = Gcov.calc_source_and_visited(file)
    if not visited
      bb = find_building_block_for_source(with_sources, source)
      return [source, bb]
    else
      if is_absolute?(visited)
        return [visited, nil]
      else
        bb = find_building_block_for_source(with_sources, source)
        if bb
          return [Gcov.simplify_path(File.join(bb.project_dir, visited)), bb]
        else
          raise "could not find building block for #{source}"
        end
      end
    end
  end

  directory ruby_dsl.build_dir

  desc 'run gcov'
  task :gcov => ruby_dsl.build_dir do
    excludes = Gcov.excludes
    sh 'find . -name "*.gcov" -delete'
    Cxxproject::sorted_building_blocks.each do |building_block|
      handle_has_sources(building_block)
    end

    gcovs_for_files = {}
    bb_for_files = {}
    gcov_files = Dir.glob('**/*.gcov')
    gcov_files.each do |f|
      f = File.join(Dir.pwd, f)
      file, bb = find_file(f, Cxxproject::sorted_building_blocks)
      raise "could not find file for #{f}" unless file

      bb_for_files[file] = bb
      gcovs_for_files[file] = [] unless gcovs_for_files.has_key?(file)
      gcovs_for_files[file] << f
    end
    
    gcovs_for_files = gcovs_for_files.delete_if do | key, value |
      excludes.any? do | i |
        key.match(i)
      end
    end

    gcovs_for_files.each do | file, gcovs |
      gcovs_for_files[file] = Gcov.merge_gcovs(gcovs.map{|i|Gcov.parse_gcov_string(File.read(i))})
    end


    HtmlExport.new('out/gcov/html', gcovs_for_files, Dir.pwd + '/')
  end

end
