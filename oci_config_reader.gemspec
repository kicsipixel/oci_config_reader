require_relative 'lib/oci_config_reader/version'

Gem::Specification.new do |spec|
  spec.name          = "oci_config_reader"
  spec.version       = OciConfigReader::VERSION
  spec.authors       = ["Szabolcs Toth"]
  spec.email         = ["tsz@purzelbaum.hu"]

  spec.summary       = %q{A Ruby gem to read out oci config data.}
  spec.description   = %q{A simple gem to read data from oci config file. So in Ruby sample codes you don't need to write down/copy-paste the same information again-and-again.}
  spec.homepage      = "https://github.com/kicsipixel/oci_config_reader"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kicsipixel/oci_config_reader"
  spec.metadata["changelog_uri"] = "https://github.com/kicsipixel/oci_config_reader"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
