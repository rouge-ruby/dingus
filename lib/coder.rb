class Coder
  DEFAULT_ROTATION = 6
  BOUND = 0x10000

  def self.decode(text, rotation = DEFAULT_ROTATION)
    return text if text.empty? || rotation == 0
    text.codepoints.map do |n|
      ((n - rotation) % BOUND).chr(Encoding::UTF_8)
    end.join
  end

  def self.encode(text, rotation = DEFAULT_ROTATION)
    return text if text.empty? || rotation == 0
    text.codepoints.map do |n|
      ((n + rotation) % BOUND).chr(Encoding::UTF_8)
    end.join
  end
end
