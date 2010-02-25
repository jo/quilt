module Couchquilt
  # proxy sends all requests to QuiltFS
  # used for printing debug information
  class DebuggedFS
    def initialize(server_name)
      @quilt = FS.new(server_name)
    rescue => e
      STDERR.puts e.message, e.backtrace
    end

    (FS.public_instance_methods - public_instance_methods).each do |method|
      class_eval <<-STR
        def #{method}(*args)
          @quilt.#{method}(*args)
        rescue => e
          STDOUT.puts "#{method}", args.inspect, e.class, e.message, e.backtrace
        end
      STR
    end
  end
end
