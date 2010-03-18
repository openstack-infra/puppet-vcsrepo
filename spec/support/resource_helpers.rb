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

end

Spec::Example::ExampleGroupFactory.register(:provider, ProviderExampleGroup)

def describe_provider(type_name, provider_name, options = {}, &block)
  provider_class = Puppet::Type.type(type_name).provider(provider_name)
  describe(provider_class, options.merge(:type => :provider), &block)
end
