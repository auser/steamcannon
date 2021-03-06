#
# Copyright 2010 Red Hat, Inc.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.

require 'spec_helper'

describe AgentClient do
  before(:each) do
    @instance = Factory.build(:instance)
    @instance.stub!(:public_address).and_return('1.2.3.4')
    @client = AgentClient.new(@instance, :mock)
  end

  after(:each) do
    APP_CONFIG[:use_ssl_with_agents] = true
  end

  describe "agent_url" do
    it "should create the proper url for the agent" do
      @client.send(:agent_url).should == "https://#{@instance.public_address}:#{AgentClient::AGENT_PORT}"
    end

    it "should create a secure url when ssl is enabled" do
      @client.send(:agent_url).should =~ %r{https://}
    end

    it "should create a non-secure url when ssl is disabled" do
      APP_CONFIG[:use_ssl_with_agents] = false
      @client.send(:agent_url).should =~ %r{http://}
    end

  end

  describe "connection" do
    before(:each) do
      cert = mock(Certificate,
                  :to_x509_certificate => 'x509',
                  :to_rsa_keypair => 'rsa',
                  :to_public_pem_file => 'pem')
      Certificate.stub!(:client_certificate).and_return(cert)
      Certificate.stub!(:ca_certificate).and_return(cert)
      @client.stub!(:verify_ssl?).and_return(false)
    end

    after(:each) do
      APP_CONFIG[:use_ssl_with_agents] = true
    end

    it "should include the ssl options if ssl enabled" do
      @client.stub!(:agent_url).and_return('url')
      RestClient::Resource.should_receive(:new).with('url',
                                                     {
                                                       :ssl_client_cert => 'x509',
                                                       :ssl_client_key => 'rsa',
                                                       :ssl_ca_file => 'pem',
                                                       :verify_ssl => false
                                                     })
      @client.send(:connection)
    end


    it "should not include the ssl options if ssl disabled" do
      APP_CONFIG[:use_ssl_with_agents] = false
      @client.stub!(:agent_url).and_return('url')
      RestClient::Resource.should_receive(:new).with('url', {})
      @client.send(:connection)
    end

  end

  describe "api_version" do
    it "should retrieve the agent api version" do
      @client.should_receive(:get).with('api_version')
      @client.api_version
    end
    
    it "should return a Versionomy::Value" do
      @client.should_receive(:get).with('api_version')
      @client.api_version.should be_an_instance_of(Versionomy::Value)
    end
    
    it "should fall back to 0.9 if version call fails" do
      @client.should_receive(:get).with('api_version').and_raise(AgentClient::RequestFailedError.new('boom'))
      @client.api_version.should == Versionomy.parse('0.9')
    end


    it "should fall back to 0.9 if version call returns nil" do
      @client.should_receive(:get).with('api_version').and_return(nil)
      @client.api_version.should == Versionomy.parse('0.9')
    end

    it "should cache the api version" do
      @client.should_receive(:get).with('api_version').once
      @client.api_version
      @client.api_version
    end
  end
  
  describe "agent_status" do
    it "should attempt to configure the agent if successful" do
      @client.stub!(:get).and_return({ })
      @client.stub!(:agent_configured?).and_return(false)
      @client.should_receive(:configure_agent)
      @client.agent_status
    end
  end

  describe "agent_services" do
    it "should extract the services from the result" do
      services = [{'name' => 'name', 'full_name' => 'full_name' }]
      @client.stub!(:call).and_return({ "services" => [{'name' => 'name', 'full_name' => 'full_name' }] })
      @client.agent_services.should == services
    end
  end

  describe "execute_request" do

    context "when the request raises an exception" do
      before(:all) do
        @raising_proc = lambda { raise Errno::ECONNREFUSED }
      end

      it "should raise an exception" do
        lambda do
          @client.send(:execute_request, &@raising_proc)
        end.should raise_error(AgentClient::RequestFailedError)
      end

      it "should include the original exception in the new exception" do
        begin
          @client.send(:execute_request, &@raising_proc)
        rescue AgentClient::RequestFailedError => ex
          ex.wrapped_exception.class.should == Errno::ECONNREFUSED
        end
      end
    end

    it "should allow blank responses" do
      lambda do
        @client.send(:execute_request, &lambda { "" })
      end.should_not raise_error
    end
  end

  describe "service actions" do
    before(:each) do
      @connection = mock("connection")
      @resource = mock("resource")
      @client.stub!(:connection).and_return(@connection)
    end

    %w{ status artifacts }.each do |action|
      it "the local #{action} action should :get the remote #{action} action" do
        @resource.should_receive(:get).with({}).and_return('{}')
        @connection.should_receive(:[]).with("/services/mock/#{action}").and_return(@resource)
        @client.send(action)
      end
    end

    %w{ start stop restart }.each do |action|
      it "the local #{action} action should :post to the remote #{action} action" do
        @resource.should_receive(:post).with('', {}).and_return('{}')
        @connection.should_receive(:[]).with("/services/mock/#{action}").and_return(@resource)
        @client.send(action)
      end
    end

    it "the local artifact action should :get the remote artifact action" do
      @resource.should_receive(:get).with({}).and_return('{}')
      @connection.should_receive(:[]).with("/services/mock/artifacts/1").and_return(@resource)
      @client.artifact(1)
    end

    it "the local deploy_artifact action should :post to the remote deploy_artifact action" do
      @resource.should_receive(:post).with({:artifact => 'the_file'}, {}).and_return('{}')
      @connection.should_receive(:[]).with("/services/mock/artifacts").and_return(@resource)
      @client.should_receive('deployment_payload').and_return('the_file')
      artifact = mock('artifact')
      @client.deploy_artifact(artifact)
    end

    it "the local undeploy_artifact action should :delete to the remote undeploy_artifact action" do
      @resource.should_receive(:delete).with({}).and_return('{}')
      @connection.should_receive(:[]).with("/services/mock/artifacts/1").and_return(@resource)
      @client.undeploy_artifact(1)
    end

    it "the local configure action should :post to the remote configure action" do
      @resource.should_receive(:post).with({:config => {}}, {}).and_return('{}')
      @connection.should_receive(:[]).with("/services/mock/configure").and_return(@resource)
      @client.configure({})
    end

    describe 'fetch_log' do
      before(:each) do
        @client.stub!(:service_get)
      end
      
      context 'when the agent api version is less than 1.0' do
        before(:each) do
          @client.should_receive(:api_version).and_return(Versionomy.parse('0.9'))
        end
        
        it "should not encode the log_id" do
          CGI.should_not_receive(:escape)
          @client.fetch_log('log', 1, 2)
        end
      end

      context 'when the agent api version is equal to 1.0' do
        before(:each) do
          @client.should_receive(:api_version).and_return(Versionomy.parse('1.0'))
        end
        
        it "should encode the log_id" do
          CGI.should_receive(:escape).twice.and_return('log')
          @client.fetch_log('log', 1, 2)
        end
      end

      context 'when the agent api version is greater than 1.0' do
        before(:each) do
          @client.should_receive(:api_version).and_return(Versionomy.parse('1.0.1'))
        end
        
        it "should encode the log_id" do
          CGI.should_receive(:escape).twice.and_return('log')
          @client.fetch_log('log', 1, 2)
        end
      end
    end
  
  end

  describe "deployment_payload" do
    before(:each) do
      @artifact = mock('artifact')
    end

    it "should attempt pull deployment if supported" do
      @artifact.should_receive(:supports_pull_deployment?).and_return(true)
      @artifact.should_receive(:pull_deployment_url).and_return('pull_url')
      expected = { :location => 'pull_url' }.to_json
      @client.send(:deployment_payload, @artifact).should == expected
    end

    it "should fall back to push deployment" do
      @artifact.should_receive(:supports_pull_deployment?).and_return(false)
      @artifact.should_receive(:deployment_file).and_return('the_file')
      @client.send(:deployment_payload, @artifact).should == 'the_file'
    end
  end
end
