class Subscriber
  def self.it_happened(message)
    File.open('/tmp/shared', 'w') do |file|
      file.puts "pid: #{Process.pid}"
    end
  end
end
