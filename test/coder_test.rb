# frozen_string_literal: true

require "minitest/autorun"

require_relative "../lib/coder"

class CoderTest < Minitest::Test
  def setup
  end

  def test_encode_with_no_rotation
    assert_equal "abc", Coder.encode("abc", 0)
  end

  def test_encode_with_custom_rotation
    assert_equal "def", Coder.encode("abc", 3)
  end

  def test_encode_with_empty_string
    assert_equal "", Coder.encode("")
  end

  def test_encode_with_latin
    assert_equal "ghi", Coder.encode("abc")
  end

  def test_encode_with_symbols
    assert_equal "E'-", Coder.encode("?!'")
  end

  def test_encode_with_japanese
    assert_equal "ヌタノ", Coder.encode("テスト")
  end
end
