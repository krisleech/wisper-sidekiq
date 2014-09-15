class Subscriber
  def self.it_happened(message)
    # sleep(10)
    File.open('/Users/kris/out', 'w') do |file|
      file.puts "pid: #{Process.gid}"
    end
  end
end
