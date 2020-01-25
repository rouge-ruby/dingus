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
    id = latest if id == :latest
    cache[id] ||= load(id)
  end

  def self.latest
    versions.first
  end

  def self.load(id)
    raise UnavailableVersion unless available?(id)

    fetch id unless dir?(id)

    MUTEX.synchronize do
      Object.send(:remove_const, :Rouge) rescue NameError
      load_silently id

      # These need to be preloaded while the correct `Rouge` is in the global scope,
      # because they assume the existence of a global `Rouge` object. In the future
      # we'll handle these differently (i.e. with a yaml file, like the Apache lexer),
      # so it won't be necessary to add to this list.
      #
      # The `rescue`s are for the cases where the lexer isn't defined in the current
      # version.
      Rouge::Lexers::Lua.builtins rescue nil
      Rouge::Lexers::PHP.builtins rescue nil
      Rouge::Lexers::VimL.keywords rescue nil
      Rouge::Lexers::Gherkin.builtins rescue nil
      Rouge::Lexers::Matlab.builtins rescue nil
      Rouge::Lexers::Mathematica.builtins rescue nil

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
