# speaking to CouchDB server
module Couchquilt
  class CouchClient
    def initialize(server_name)
      @server_name = server_name
    end

    # initiates a GET request and returns the JSON parsed response
    def get(path)
      response = RestClient.get(url_for(path))
      JSON.parse(response) rescue response
    rescue RestClient::ResourceNotFound
      nil
    end

    # initiates a PUT request and returns true if it was successful
    def put(path, payload = {})
      RestClient.put url_for(path), payload.to_json
      true
    end

    # initiates a DELETE request and returns true if it was successful
    def delete(path)
      RestClient.delete url_for(path)
      true
    rescue
      false
    end

    # initiates a HEAD request to +url+ and returns true if the resource exists
    def head(path)
      RestClient.head url_for(path)
      true
    rescue RestClient::ResourceNotFound
      false
    end

    private

    def url_for(path)
      File.join(@server_name, path)
    end
  end
end
