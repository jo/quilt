module Couchquilt
  # proxy sends all requests to QuiltFS
  # used for printing debug information
  class DebuggedFS
    def initialize(server_name)
      @quilt = FS.new(server_name)
    end

    private

    # delegates all method calls to the QuiltFS
    def method_missing(name, *path_and_payload)
      @quilt.send name, *path_and_payload
    rescue => e
      STDERR.puts name, path_and_payload, e.class, e.message, e.backtrace
    end
  end
end
