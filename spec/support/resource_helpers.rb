class ProviderExampleGroup < Spec::Example::ExampleGroup

  attr_reader :resource
  
  before :each do
    resource_hash = example_group_hierarchy.inject({}) do |memo, klass|
      memo.merge(klass.options[:resource] || {})
    end
    full_hash = resource_hash.merge(:provider => described_class.name)
    @resource = described_class.resource_type.new(full_hash)
  end
  
  subject { described_class.new(@resource) }
  alias :provider :subject

  def _(name)
    resource.value(name)
  end

  class << self

    def field(field, &block)
      ResourceField.new(self, field, &block)
    end

    # call-seq:
    #
    #   given(:ensure)
    #   given(:ensure => :present)
    def context_with(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      if args.empty?
        text = options.map { |k, v| "#{k} => #{v.inspect}" }.join(' and with ')
        context("and with #{text}", {:resource => options}, &block)
      else
        text = args.join(', ')
        placeholders = args.inject({}) { |memo, key| memo.merge(key => 'an-unimportant-value') }
        context("and with a #{text}", {:resource => placeholders}, &block)
      end
    end

    def context_without(field, &block)
      context("and without a #{field}", &block)
    end
      
  end

end

Spec::Example::ExampleGroupFactory.register(:provider, ProviderExampleGroup)

def describe_provider(type_name, provider_name, options = {}, &block)
  provider_class = Puppet::Type.type(type_name).provider(provider_name)
  describe(provider_class, options.merge(:type => :provider), &block)
end
