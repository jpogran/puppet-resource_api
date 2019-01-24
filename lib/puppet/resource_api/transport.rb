require 'puppet/resource_api/puppet_context'

# Remote target transport API
module Puppet::ResourceApi::Transport
  def register(schema)
    raise Puppet::DevError, 'requires a hash as schema, not `%{other_type}`' % { other_type: schema.class } unless schema.is_a? Hash
    raise Puppet::DevError, 'requires a `:name`' unless schema.key? :name
    raise Puppet::DevError, 'requires `:desc`' unless schema.key? :desc
    raise Puppet::DevError, 'requires `:connection_info`' unless schema.key? :connection_info
    raise Puppet::DevError, '`:connection_info` must be a hash, not `%{other_type}`' % { other_type: schema[:connection_info].class } unless schema[:connection_info].is_a?(Hash)

    @transports ||= {}
    raise Puppet::DevError, 'Transport `%{name}` is already registered.' % { name: schema[:name] } unless @transports[schema[:name]].nil?
    @transports[schema[:name]] = Puppet::ResourceApi::TransportSchemaDef.new(schema)
  end
  module_function :register # rubocop:disable Style/AccessModifierDeclarations

  def connect(name, connection_info)
    validate(name, connection_info)
    require "puppet/transport/#{name}"
    class_name = name.split('_').map { |e| e.capitalize }.join
    context = Puppet::ResourceApi::PuppetContext.new(@transports[name])
    Puppet::Transport.const_get(class_name).new(context, connection_info)
  end
  module_function :connect # rubocop:disable Style/AccessModifierDeclarations

  def self.validate(name, connection_info)
    @transports ||= {}
    require "puppet/transport/schema/#{name}" unless @transports.key? name
    transport_schema = @transports[name]
    raise Puppet::DevError, 'Transport for `%{target}` not registered' % { target: name } if transport_schema.nil?

    transport_schema.check_schema(connection_info)
    transport_schema.validate(connection_info)
  end
end
