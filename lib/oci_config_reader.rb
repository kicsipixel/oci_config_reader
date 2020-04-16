require "oci_config_reader/version"

module OciConfigReader
  class Error < StandardError; end
  def self.version
  	OciConfigReader::VERSION
  end
end
