require "hashids"
require "lockbox"
require "sqlite3"
require "sequel"

class Legacy
  class NotAHash < StandardError; end

  def self.db()
    return @db if defined?(@db)
    lockbox = Lockbox.new(key: ENV["LOCKBOX_KEY"])
    en_path = File.join(__dir__, "..", "db", "encrypted.sqlite")
    de_path = File.join(__dir__, "..", "db", "decrypted.sqlite")
    File.binwrite(de_path, lockbox.decrypt(File.binread(en_path)))
    @db = Sequel.sqlite de_path
  end

  def self.hash_to_id(h)
    raise NotAHash unless h.is_a?(String)
    hashids.decode(h).first
  end

  def self.hashids()
    return @hashids if defined?(@hashids)
    @hashids = Hashids.new ENV['HASHIDS_SALT']
  end

  def self.paste(h)
    paste = db[:pastes].where(:id => hash_to_id(h))
    (paste.count == 1) ? paste : nil
  end
end

