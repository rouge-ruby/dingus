# frozen_string_literal: true

class Demo
  class InvalidVersion < StandardError; end

  attr_reader :rouge, :lexer, :source

  def initialize(ver = :latest, lang = nil, source = nil)
    @rouge = set_version ver
    @original_ver = ver
    @lexer = set_lexer lang
    @source = set_source source
  end

  def all_lexers
    rouge::Lexer.all.sort_by(&:tag)
  end

  def lexer_count
    all_lexers.count
  end

  def result
    if rouge::Formatter.find('html_debug')
      rouge.highlight source, lexer, 'html_debug'
    else
      rouge.highlight source, lexer, 'html'
    end
  end

  def version
    return 'main' if main?
    rouge.version
  end

  def main?
    @original_ver == 'vmain'
  end

  def display_version
    return "main (git: #{Loader.main_hash})" if main?
    version
  end

  private

  def set_version(ver)
    return Loader.get(ver) if ver == :latest

    raise InvalidVersion unless ver.is_a?(String) && ver[0] == 'v'

    Loader.get ver.slice(1..-1)
  end

  def set_lexer(lang)
    return all_lexers.sample if lang.nil?

    rouge::Lexer.find(lang) || all_lexers.sample
  end

  def set_source(source)
    source || lexer.demo
  end
end
