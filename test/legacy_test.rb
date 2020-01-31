# frozen_string_literal: true

require "minitest/autorun"
require "dotenv/load"

require_relative "../lib/legacy"

class LegacyTest < Minitest::Test
  def setup
  end

  def teardown
    Legacy.instance_variables.each { |ivar| Legacy.remove_instance_variable ivar }
  end

  def test_database_opening
    assert_equal "String", Legacy.db.class.to_s
  end

  def test_database_successful_retrieval
    res = Legacy.paste "4j"
    assert_equal 1, res[:id]
    assert_equal 1428722903, res[:created_at].to_time.to_i
  end

  def test_database_unsuccessful_retrieval
    res = Legacy.paste "aaa"
    assert_nil res
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
