require "date"
require "gdbm"
require "hashids"
require "lockbox"

class Legacy
  class NotAHash < StandardError; end

  def self.db()
    return @loaded if defined?(@loaded)
    lockbox = Lockbox.new(key: ENV["LOCKBOX_KEY"])
    en_path = File.join(__dir__, "..", "db", "encrypted.db")
    de_path = File.join(__dir__, "..", "db", "decrypted.db")
    File.binwrite(de_path, lockbox.decrypt(File.binread(en_path)))
    @loaded = de_path
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
    paste = GDBM.open(db, 0666, GDBM::READER) do |db|
              db[hash_to_id(h).to_s]
            end

    return nil if paste.nil?

    fields = paste.split("\t", 5)
    { :id => fields[0].to_i,
      :created_at => DateTime.parse(fields[1]), #, "%Y-%m-%d %H:%M:%S.%6N"),
      :language => fields[3],
      :source => fields[4] }
  end
end
