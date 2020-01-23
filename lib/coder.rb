class Coder
  def self.encode(text, rotation = 6)
    return text if text.empty? || rotation == 0
    bound = 0x10000
    text.codepoints.map do |n|
      ((n + rotation + bound) % bound).chr(Encoding::UTF_8)
    end.join
  end
end
