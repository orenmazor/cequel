# -*- encoding : utf-8 -*-
require File.expand_path('../../spec_helper', __FILE__)

describe Cequel::Schema::Keyspace do
  let(:connection) do
    Cequel.connect(config)
  end
  let(:keyspace) { connection.schema }
  let(:release_version) { connection.release_version }

  describe 'creating keyspace' do
    before do
      connection.configure(config)
      connection.schema.drop! if connection.schema.exists?
    end

    let(:keyspace_name) do
      test_env_number = ENV['TEST_ENV_NUMBER']
      test_env_number ?
        "cequel_schema_test_#{test_env_number}" :
        "cequel_schema_test"
    end

    let(:basic_config) do
      {
        host: Cequel::SpecSupport::Helpers.host,
        port: Cequel::SpecSupport::Helpers.port,
        keyspace: keyspace_name
      }
    end

    let(:schema_config) do
      if release_version.starts_with? '3.'
        connection.client.execute("SELECT * FROM system_schema.keyspaces WHERE keyspace_name = '#{keyspace_name}'").first
      else
        connection.client.execute("SELECT * FROM system.schema_keyspaces WHERE keyspace_name = '#{keyspace_name}'").first
      end
    end

    context 'with default options' do
      let(:config) { basic_config }

      it 'uses default keyspace configuration' do
        keyspace.create!
        if release_version.starts_with? '3.'
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>true,
            "replication"=>{
              "class"=>"org.apache.cassandra.locator.SimpleStrategy",
              "replication_factor"=>"1"
            }
          })
        else
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>true,
            "strategy_class"=>"org.apache.cassandra.locator.SimpleStrategy",
            "strategy_options"=>"{\"replication_factor\":\"1\"}"
          })
        end
      end
    end

    context 'with explicit options' do
      let(:config) { basic_config }

      it 'uses specified options' do
        keyspace.create! replication: { class: "SimpleStrategy", replication_factor: 2 }
        if release_version.starts_with? '3.'
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>true,
            "replication"=>{
              "class"=>"org.apache.cassandra.locator.SimpleStrategy",
              "replication_factor"=>"2"
            }
          })
        else
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>true,
            "strategy_class"=>"org.apache.cassandra.locator.SimpleStrategy",
            "strategy_options"=>"{\"replication_factor\":\"2\"}"
          })
        end
      end
    end

    context 'keeping compatibility' do
      let(:config) { basic_config }

      it 'accepts class and replication_factor options' do
        keyspace.create! class: "SimpleStrategy", replication_factor: 2
        if release_version.starts_with? '3.'
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>true,
            "replication"=>{
              "class"=>"org.apache.cassandra.locator.SimpleStrategy",
              "replication_factor"=>"2"
            }
          })
        else
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>true,
            "strategy_class"=>"org.apache.cassandra.locator.SimpleStrategy",
            "strategy_options"=>"{\"replication_factor\":\"2\"}"
          })
        end
      end

      it "raises an error if a class other than SimpleStrategy is given"  do
        expect {
          keyspace.create! class: "NetworkTopologyStrategy", replication_factor: 2
        }.to raise_error(RuntimeError)
      end
    end

    context 'with custom replication options' do
      let(:config) {
        basic_config.merge(replication: { class: "SimpleStrategy", replication_factor: 3 })
      }

      it 'uses default keyspace configuration' do
        keyspace.create!
        if release_version.starts_with? '3.'
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>true,
            "replication"=>{
              "class"=>"org.apache.cassandra.locator.SimpleStrategy",
              "replication_factor"=>"3"
            }
          })
        else
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>true,
            "strategy_class"=>"org.apache.cassandra.locator.SimpleStrategy",
            "strategy_options"=>"{\"replication_factor\":\"3\"}"
          })
        end
      end
    end

    context 'with another custom replication options' do
      let(:config) {
        basic_config.merge(replication: { class: "NetworkTopologyStrategy", datacenter1: 3, datacenter2: 2 })
      }

      it 'uses default keyspace configuration' do
        keyspace.create!
        if release_version.starts_with? '3.'
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>true,
            "replication"=>{
              "class"=>"org.apache.cassandra.locator.NetworkTopologyStrategy",
              "datacenter1"=>"3",
              "datacenter2"=>"2"
            }
          })
        else
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>true,
            "strategy_class"=>"org.apache.cassandra.locator.NetworkTopologyStrategy",
            "strategy_options"=>"{\"datacenter1\":\"3\",\"datacenter2\":\"2\"}"
          })
        end
      end
    end

    context 'with custom durable_write option' do
      let(:config) {
        basic_config.merge(durable_writes: false)
      }

      it 'uses default keyspace configuration' do
        keyspace.create!
        if release_version.starts_with? '3.'
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>false,
            "replication" => {
              "class"=>"org.apache.cassandra.locator.SimpleStrategy",
              "replication_factor"=>"1"
            }
          })
        else
          expect(schema_config).to eq({
            "keyspace_name"=>keyspace_name,
            "durable_writes"=>false,
            "strategy_class"=>"org.apache.cassandra.locator.SimpleStrategy",
            "strategy_options"=>"{\"replication_factor\":\"1\"}"
          })
        end
      end
    end
  end # describe 'creating keyspace'
end
