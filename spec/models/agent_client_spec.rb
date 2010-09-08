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
    @instance.stub!(:public_dns).and_return('1.2.3.4')
    @client = AgentClient.new(@instance)
  end

  after(:each) do
    APP_CONFIG[:use_ssl_with_agents] = true
  end
  
  describe "agent_url" do
    it "should create the proper url for the agent" do
      @client.send(:agent_url).should == "https://#{@instance.public_dns}:#{AgentClient::AGENT_PORT}"
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
    
    it "should not include any options if ssl is disabled" do
      @client.stub!(:agent_url).and_return('url')
      RestClient::Resource.should_receive(:new).with('url', {})
      APP_CONFIG[:use_ssl_with_agents] = false
      @client.send(:connection)
    end

    it "should include the ssl options if ssl is enabled" do
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
  end

  describe "status" do
    it "should attempt to configure the agent if successful" do
      @client.stub!(:get).and_return({ "status" => "ok" })
      @client.stub!(:agent_configured?).and_return(false)
      @client.should_receive(:configure_agent)
      @client.status
    end

    # it "should attempt to configure the client if successful" do
    #   @client.stub!(:get).and_return({ "status" => "ok" })
    #   @client.should_receive(:configure_client)
    #   @client.status
    # end
  end
end
