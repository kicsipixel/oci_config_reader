#
#
# Origin of the file: https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/signingrequests.htm#RubySigningSample
#
#

require 'base64'
require 'digest'
require 'openssl'
require 'time'
require 'uri'
require 'json'

# gem 'oci_config_reader'
require 'oci_config_reader'

# gem 'terminal-table'
require 'terminal-table'

# gem 'httparty', '~> 0.13.0'
require 'httparty'

user = OciConfigReader.oci_config_data["user"]
fingerprint = OciConfigReader.oci_config_data["fingerprint"]
key_file = OciConfigReader.oci_config_data["key_file"]
tenancy = OciConfigReader.oci_config_data["tenancy"]

# Version 1.0.1
class Client
    include HTTParty
    attr_reader :signer

    def initialize(key_id, private_key)
        @signer = Signer.new(key_id, private_key)
    end

    # nothing to sign for :options

    [:get, :head, :delete].each do |method|
        define_method(method) do |uri, headers: {}|
            self.signer.sign(method, uri, headers, body: nil)
            self.class.send(method, uri, :headers => headers)
        end
    end

    [:put, :post].each do |method|
        define_method(method) do |uri, headers: {}, body: ""|
            self.signer.sign(method, uri, headers, body)
            self.class.send(method, uri, :headers => headers, :body => body)
        end
    end
end


class Signer
    class << self
        attr_reader :headers
    end

    attr_reader :key_id, :private_key

    generic_headers = [:"date", :"(request-target)", :"host"]
    body_headers = [
        :"content-length", :"content-type", :"x-content-sha256"]
    @headers = {
        get: generic_headers,
        head: generic_headers,
        delete: generic_headers,
        put: generic_headers + body_headers,
        post: generic_headers + body_headers
    }

    def initialize(key_id, private_key)
        @key_id = key_id
        @private_key = private_key
    end

    def sign(method, uri, headers, body)
        uri = URI(uri)
        path = uri.query.nil? ? uri.path : "#{uri.path}?#{uri.query}"
        self.inject_missing_headers(headers, method, body, uri)
        signature = self.compute_signature(headers, method, path)
        unless signature.nil?
            self.inject_authorization_header(headers, method, signature)
        end
    end

    def inject_missing_headers(headers, method, body, uri)
        headers["content-type"] ||= "application/json"
        headers["date"] ||= Time.now.utc.httpdate
        headers["accept"] ||= "*/*"
        headers["host"] ||= uri.host
        if method == :put or method == :post
            body ||= ""
            headers["content-length"] ||= body.length.to_s
            headers["x-content-sha256"] ||= Digest::SHA256.base64digest(body)
        end
    end

    def inject_authorization_header(headers, method, signature)
        signed_headers = self.class.headers[method].map(&:to_s).join(" ")
        headers["authorization"] = [
            %(Signature version="1"),
            %(headers="#{signed_headers}"),
            %(keyId="#{self.key_id}"),
            %(algorithm="rsa-sha256"),
            %(signature="#{signature}")
        ].join(",")
    end

    def compute_signature(headers, method, path)
        return if self.class.headers[method].empty?
        signing_string = self.class.headers[method].map do |header|
            if header == :"(request-target)"
                "#{header}: #{method.downcase} #{path}"
            else
                "#{header}: #{headers[header.to_s]}"
            end
        end.join("\n")
        signature = self.private_key.sign(
            OpenSSL::Digest::SHA256.new,
            signing_string.encode("ascii"))
        Base64.strict_encode64(signature)
    end
end


api_key = [tenancy, user, fingerprint].join("/")
private_key = OpenSSL::PKey::RSA.new(File.read(key_file))
client = Client.new(api_key, private_key)

headers = {
    # Uncomment to use a fixed date
    # "date" => "Thu, 05 Jan 2014 21:31:40 GMT"
}

# GET with query parameters
uri = "https://iaas.eu-frankfurt-1.oraclecloud.com/20160918/instances?compartmentId=%{compartment_id}"
uri = uri % {
    :compartment_id => "ocid1.compartment.oc1..aaaaaaaa4ifadwjtf3uez2sawspmre5yartoh3jq6afwvihv3zddug3m3nda".sub(":", "%3A")
}
response = client.get(uri, headers: headers)

# Create a table
response_data = JSON.parse(response&.body || "{}")
AD = response_data[0]["availabilityDomain"]
server_name = response_data[0]["displayName"]
fault_domain = response_data[0]["faultDomain"]
region = response_data[0]["region"]
shape = response_data[0]["shape"]
ocpus = response_data[0]["shapeConfig"]["ocpus"]
memory = response_data[0]["shapeConfig"]["memoryInGBs"]
cpu_type = response_data[0]["shapeConfig"]["processorDescription"]

rows = []
rows << [server_name, fault_domain, region, shape, ocpus, cpu_type, memory]
table = Terminal::Table.new :title => AD, :headings => ["Server name", "Fault domain", "Region", "Shape", "OCPU", "OCPU type", "Memory in GB"], :rows => rows

puts table
