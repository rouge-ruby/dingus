require 'monitor'

class TimeCache
  def initialize(timeout)
    @timeout = timeout
    @hash = {}
    @times = {}
    @lock = Monitor.new
  end

  def synchronize(&b)
    @lock.synchronize(&b)
  end

  def owned?
    @lock.mon_owned?
  end

  def fetch(k)
    now = Time.now.to_i

    time = @times[k]
    return @hash[k] unless time.nil? || now > time + @timeout

    @lock.synchronize do
      time = @times[k]

      # double check in case we loaded while waiting for the lock
      if time.nil? || now > time + @timeout
        @hash[k] = yield @hash
        @times[k] = now
      end

      @hash[k]
    end
  end

  def unsafe_set_with_time!(k, v, time)
    @hash[k] = v
    @times[k] = time.to_i
  end

  def delete(k)
    @lock.synchronize { @times.delete(k) }
  end

  def []=(k, v)
    @lock.synchronize do
      @hash[k] = v
      @times[k] = Time.now.to_i
    end
  end

  def [](k)
    now = Time.now.to_i
    time = @times[k]
    return nil if time.nil? || now > time + @timeout

    @hash[k]
  end

  def clear
    @lock.synchronize do
      @hash.clear
      @times.clear
    end
  end
end
