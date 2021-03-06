# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ojanalyzer/version'

Gem::Specification.new do |spec|
  spec.name          = "ojanalyzer"
  spec.version       = OJAnalyzer::VERSION
  spec.authors       = ["hadrori"]
  spec.email         = ["hadrori.hs@gmail.com"]

  spec.summary       = "Online Judge Analyzer"
  spec.description   = "Online Judge Analyzer"
  spec.homepage      = "https://github.com/hadrori/ojanalyzer"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"

  spec.add_dependency "sqlite3", "~> 1.3"
  spec.add_dependency "activerecord", "~> 5.0"
  spec.add_dependency "activerecord-import", "~> 0.16"
  spec.add_dependency "nokogiri", "~> 1.6"
  spec.add_dependency "faraday", "~> 0.9"
  spec.add_dependency "faraday_middleware", "~> 0.10"
end
