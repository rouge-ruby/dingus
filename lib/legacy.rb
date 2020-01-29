require "hashids"

class Legacy
  class NoID < StandardError; end
  class NotAHash < StandardError; end

  def self.hash_to_id(h)
    raise NotAHash unless h.is_a?(String)
    hashids.decode(h).first
  end

  def self.hashids()
    return @hashids if defined?(@hashids)
    @hashids = Hashids.new ENV['HASHIDS_SALT']
  end
end

