require "oci_config_reader/version"

module OCR
  class Error < StandardError; end
  def self.version
  	OCR::VERSION
  end

  def self.oci_config_data
    oci_config_path = "#{Dir.home}/.oci/config"
    oci_config_data = {}

    file = File.open(oci_config_path)
    file_data = file.readlines.map(&:chomp)
    file_data.each do |line|
      if line !=~ /[DEFAULT]/
        oci_config_data["user"] = "#{line.match(/(?<==).+/)}" if line =~ /user/
        oci_config_data["fingerprint"] = "#{line.match(/(?<==).+/)}" if line =~ /fingerprint/
        oci_config_data["key_file"] = "#{line.match(/(?<==).+/)}" if line =~ /key_file/
        oci_config_data["tenancy"] = "#{line.match(/(?<==).+/)}" if line =~ /tenancy/
        oci_config_data["region"] = "#{line.match(/(?<==).+/)}" if line =~ /region/
      end
    end
    return oci_config_data
  end
end
