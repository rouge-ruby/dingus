# frozen_string_literal: true

require 'open-uri'
require 'json'
require_relative 'time_cache'

class Loader
  class UnavailableVersion < StandardError; end

  TMP_DIR = File.expand_path(ENV['ROUGE_VER_DIR'] || File.join(Bundler.root, 'tmp', 'rouge'))
  MAX_VERSIONS = 5
  CACHE = TimeCache.new(60 * 60 * 24)

  Bundler.mkdir_p(TMP_DIR)

  def self.setup!
    Dir.chdir TMP_DIR do
      if File.exist?('available_versions')
        CACHE.unsafe_set_with_time!(
          'available_versions',
          File.readlines('available_versions', chomp: true),
          File.mtime('available_versions'),
        )
      end

      Dir.children('.').each do |child|
        next unless File.directory?(child)
        child =~ /\Arouge-(.*)/ or next
        key = $1
        CACHE.unsafe_set_with_time!(key, unsafe_load(key), File.mtime(child))
      end
    end
  end

  def self.available?(ver)
    return true if ver == 'main'
    return false if ver < '1.1.0'

    versions.include?(ver)
  end

  def self.dir(ver)
    File.join(TMP_DIR, "rouge-#{ver}")
  end

  def self.dir?(ver)
    Dir.exist?(dir(ver))
  end

  def self.fetch(ver)
    if ver == 'main'
      Dir.chdir(TMP_DIR) do
        unless Dir.exist?('rouge-main')
          Kernel.system 'git clone https://github.com/rouge-ruby/rouge rouge-main'
        end

        Dir.chdir('rouge-main') do
          # Kernel.system 'git fetch && git reset --hard origin/main'
          CACHE['main_hash'] = `git rev-parse origin/main`[0..7]
        end
      end
    else
      Dir.chdir(TMP_DIR) do
        next if Dir.exist?("rouge-#{ver}")
        Kernel.system "gem fetch rouge -v #{ver}"
        Kernel.system "gem unpack rouge-#{ver}.gem"
        File.delete("rouge-#{ver}.gem")
      end
    end
  end

  def self.get(ver)
    ver = latest if ver == :latest
    CACHE.fetch(ver) { load(ver) }
  end

  def self.latest
    versions.first
  end

  def self.display_for(version)
    return "main (#{main_hash})" if version == 'main'
    version
  end

  def self.main_hash
    get('main')
    @main_hash
  end

  def self.load(ver)
    raise "BUG" unless CACHE.owned?
    unsafe_load(ver)
  end

  def self.unsafe_load(ver)
    raise UnavailableVersion unless available?(ver)

    fetch ver unless dir?(ver)

    begin
      Object.send(:remove_const, :Rouge)
    rescue StandardError
      NameError
    end

    load_silently ver

    if Rouge.respond_to?(:eager_load!)
      begin
      Rouge.eager_load!
      rescue
        require 'pry'
        binding.pry
      end
    else
      patch_load Rouge
    end

    Rouge.const_set(:Rouge, Rouge)
    Object.send(:remove_const, :Rouge)
  end

  def self.load_silently(ver)
    dir = "#{TMP_DIR}/rouge-#{ver}"
    $LOADED_FEATURES.reject! { |f| f.start_with?(dir) }

    old_verbose = $VERBOSE
    $VERBOSE = nil
    require("#{dir}/lib/rouge.rb")
    $VERBOSE = old_verbose
  end

  # [jneen] this is a kludge, remove when we no longer have to
  # support versions that don't have #eager_load!
  def self.patch_load(rouge)
    cache = CACHE

    # when loading new files from within this rouge version,
    # temporarily set the global Rouge constant
    impl = proc do |filename|
      cache.synchronize do
        Object.const_set(:Rouge, rouge)
        super filename
        Object.send(:remove_const, :Rouge)
      end
    end

    # for Kernel::load calls
    stub_kernel = Module.new

    stub_kernel.define_singleton_method(:load, &impl)
    rouge::Lexer.define_singleton_method(:load, &impl)

    rouge.const_set(:Kernel, stub_kernel)
  end

  def self.versions
    CACHE.fetch('available_versions') do
      response = URI.open('https://rubygems.org/api/v1/versions/rouge.json')
      versions = JSON.load(response).first(MAX_VERSIONS).map { |v| v['number'] } + ['main']
      File.write("#{TMP_DIR}/available_versions", versions.join("\n"))
      versions
    end
  end
end

Loader.setup!

