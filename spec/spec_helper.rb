require 'pathname'
dir = Pathname.new(__FILE__).parent
$LOAD_PATH.unshift(dir, dir + 'lib', dir + '../lib')

require 'mocha'
require 'puppet'
gem 'rspec', '=1.2.9'
require 'spec/autorun'

module Helpers

  def fixture(name, ext = '.txt')
    File.read(File.join(File.dirname(__FILE__), 'fixtures', name.to_s + ext))
  end
  
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.include(Helpers)
end

# We need this because the RAL uses 'should' as a method.  This
# allows us the same behaviour but with a different method name.
class Object
    alias :must :should
end
