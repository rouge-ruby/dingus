# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"

require_relative "../lib/loader"

class LoaderTest < Minitest::Test
  def setup
    Loader.send(:remove_const, :TMP_DIR)
    Loader.const_set(:TMP_DIR, File.join("test", "data"))
  end

  def teardown
    FileUtils.rm_r Dir.glob(File.join(Loader::TMP_DIR, "*"))
    Loader.instance_variables.each { |ivar| Loader.remove_instance_variable ivar }
  end

  def test_available?
    refute Loader.available? "1.0.0"
    refute Loader.available? "0.1.0"
  end

  def test_dir
    assert_equal File.join(Loader::TMP_DIR, "1.1.0"), Loader.dir("1.1.0")
  end

  def test_dir?
    refute Loader.dir?("0")

    FileUtils.mkdir File.join(Loader::TMP_DIR, "0")
    assert Loader.dir?("0")
  end

  def test_fetch
    gem_path = File.join(Loader::TMP_DIR, "rouge-1.1.0")
    Loader.fetch "1.1.0"
    assert Dir.exist?(gem_path)
  end

  def test_listing(ver = "0.0.1")
    result = Loader.listing
    assert_equal Array, result.class
    assert_equal ver, result.last
  end

  def test_listing_with_file
    listing_path = File.join Loader::TMP_DIR, "available_versions"
    File.write listing_path, "0.0.3\n0.0.2"
    test_listing "0.0.2"
  end

  def test_load_with_valid_id
    rouge = Loader.load "1.1.0"
    assert_equal "1.1.0", rouge.version
  end

  def test_load_with_invalid_id
    assert_raises(Loader::UnavailableVersion) { Loader.load("0") }
  end
end
