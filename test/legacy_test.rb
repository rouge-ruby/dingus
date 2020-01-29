# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "dotenv/load"

require_relative "../lib/legacy"

class LegacyTest < Minitest::Test
  def setup
  end

  def teardown
    Legacy.instance_variables.each { |ivar| Legacy.remove_instance_variable ivar }
  end

  def test_hash_to_ids_with_valid_hash
    assert_equal 1, Legacy.hash_to_id("4j")
  end

  def test_hash_to_ids_with_invalid_hash
    assert_nil Legacy.hash_to_id("aaa")
  end

  def test_hash_to_ids_with_not_a_hash
    assert_raises(Legacy::NotAHash) { Legacy.hash_to_id(4) }
  end
end
