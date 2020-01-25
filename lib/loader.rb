require "thread"

class Loader
  class UnavailableVersion < StandardError; end

  MUTEX = Mutex.new
  TMP_DIR = ENV["ROUGE_VER_DIR"] || File.join(Bundler.root, "tmp", "rouge")

  Bundler.mkdir_p TMP_DIR

  def self.available?(ver)
    return false if ver < "1.1.0"
    versions.include? ver
  end

  def self.cache
    @cache ||= {}
  end

  def self.dir(ver)
    File.join TMP_DIR, ver
  end

  def self.dir?(ver)
    Dir.exist? dir(ver)
  end

  def self.fetch(ver)
    Dir.chdir(TMP_DIR) do
      %x(gem fetch rouge -v #{ver})
      %x(gem unpack rouge-#{ver}.gem)
      File.delete "rouge-#{ver}.gem"
    end
  end

  def self.get(ver)
    ver = latest if ver == :latest
    cache[ver] ||= load(ver)
  end

  def self.latest
    versions.first
  end

  def self.load(ver)
    raise UnavailableVersion unless available?(ver)

    fetch ver unless dir?(ver)

    MUTEX.synchronize do
      Object.send(:remove_const, :Rouge) rescue NameError
      load_silently ver
      patch_load Rouge
      Rouge.const_set(:Rouge, Rouge)
      Object.send(:remove_const, :Rouge)
    end
  end

  def self.load_silently(ver)
    old_verbose = $VERBOSE
    $VERBOSE = nil
    Kernel.load(File.join(TMP_DIR, "rouge-#{ver}", "lib/rouge.rb"))
    $VERBOSE = old_verbose
  end

  def self.patch_load(rouge)
    rouge::Lexer.define_singleton_method(:load) do |filename|
      Loader::MUTEX.synchronize do
        Object.const_set(:Rouge, rouge)
        super filename
        Object.send(:remove_const, :Rouge)
      end
    end
  end

  def self.versions
    path = File.join TMP_DIR, "available_versions"
    if File.exist?(path) && (Time.now - File.mtime(path) < 86400)
      version_nums = (defined? @versions) ? @versions : File.readlines(path, chomp: true)
    else
      response = %x(gem query --versions --all -r -e rouge)
      version_nums = response.scan(/\d+\.\d+\.\d+/)
      File.write path, version_nums.join("\n")
    end

    @versions = version_nums
  end
end
