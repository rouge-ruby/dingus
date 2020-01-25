require "thread"

class Loader
  class UnavailableVersion < StandardError; end

  MUTEX = Mutex.new
  TMP_DIR = ENV["ROUGE_VER_DIR"] || File.join(Bundler.root, "tmp", "rouge")

  Bundler.mkdir_p TMP_DIR

  def self.available?(id)
    return false if id < "1.1.0"
    versions.include? id
  end

  def self.cache
    @cache ||= {}
  end

  def self.dir(id)
    File.join TMP_DIR, id
  end

  def self.dir?(id)
    Dir.exist? dir(id)
  end

  def self.fetch(id)
    Dir.chdir(TMP_DIR) do
      %x(gem fetch rouge -v #{id})
      %x(gem unpack rouge-#{id}.gem)
      File.delete "rouge-#{id}.gem"
    end
  end

  def self.get(id)
    cache[id] ||= load(id)
  end

  def self.latest
    versions.first
  end

  def self.load(id)
    id = latest if id == :latest

    raise UnavailableVersion unless available?(id)

    fetch id unless dir?(id)

    MUTEX.synchronize do
      Object.send(:remove_const, :Rouge) rescue NameError
      load_silently id
      Rouge.const_set(:Rouge, Rouge)
      Object.send(:remove_const, :Rouge)
    end
  end

  def self.load_silently(id)
    old_verbose = $VERBOSE
    $VERBOSE = nil
    Kernel.load(File.join(TMP_DIR, "rouge-#{id}", "lib/rouge.rb"))
    $VERBOSE = old_verbose
  end

  def self.versions
    path = File.join TMP_DIR, "available_versions"
    if File.exist?(path) && (Time.now - File.mtime(path) <= 86400)
      version_nums = (defined? @versions) ? @versions : File.readlines(path, chomp: true)
    else
      response = %x(gem query --versions --all -r -e rouge)
      version_nums = response.scan(/\d+\.\d+\.\d+/)
      File.write path, version_nums.join("\n")
    end

    @versions = version_nums
  end
end
