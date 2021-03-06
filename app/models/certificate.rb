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


class Certificate < ActiveRecord::Base
  belongs_to :certifiable, :polymorphic => true

  validates_presence_of :cert_type, :certificate, :keypair

  CA_TYPE = 'ca'
  CLIENT_TYPE = 'client'
  SERVER_TYPE = 'server'
  ENCRYPTION_TYPE = 'encryption'

  # The keypair accessors encrypt/decrypt the private keys as needed.
  def keypair=(keypair)
    if APP_CONFIG[:certificate_password]
      keypair = OpenSSL::PKey::RSA.new(keypair).
        export(OpenSSL::Cipher::DES.new(:EDE3, :CBC),
               APP_CONFIG[:certificate_password])
    end
    super(keypair)
  end

  def keypair
    keypair = super
    if APP_CONFIG[:certificate_password]
      keypair = OpenSSL::PKey::RSA.new(keypair, APP_CONFIG[:certificate_password])
    end
    keypair
  end

  def to_rsa_keypair
    @to_rsa_keypair ||= OpenSSL::PKey::RSA.new(keypair)
  end

  def to_x509_certificate
    @to_x509_certificate ||= OpenSSL::X509::Certificate.new(certificate)
  end

  def to_public_pem_file
    filename = "/tmp/cert_#{id}_#{Rails.env}.pem"
    File.open(filename, 'w') { |file| file.write(certificate) } unless File.exists?(filename)
    filename
  end
  
  class << self
    def ca_certificate
      @ca_certificate ||= Certificate.find_by_cert_type(Certificate::CA_TYPE) || generate_ca_certificate
    end

    def client_certificate
      @client_certificate ||= Certificate.find_by_cert_type(Certificate::CLIENT_TYPE) || generate_client_certificate
    end
    
    def encryption_certificate
      @encryption_certificate ||= Certificate.find_by_cert_type(Certificate::ENCRYPTION_TYPE) || generate_encryption_certificate
    end
    
    def generate_server_certificate(certifiable)
      options = {
        # use the certifiable id as the serial. According to RFC 2459,
        # the serial must be unique for the CA, but it doesn't really
        # matter for our usage, since we both produce and consume all
        # of the certs.
        :serial => certifiable.id,
        :subject => "CN=#{certifiable.public_address}, O=SteamCannon Instance, CN=SteamCannon Agent",
        :extensions => [
                        [ "basicConstraints", "CA:FALSE" ],
                        [ "keyUsage", "digitalSignature,keyEncipherment" ],
                        [ "extendedKeyUsage", "serverAuth" ]
                       ]
      }

      cert, keypair = generate_certificate(options)

      Certificate.create(:cert_type => Certificate::SERVER_TYPE,
                         :certifiable => certifiable,
                         :certificate => cert.to_pem,
                         :keypair => keypair.to_pem)

    end
    
    # Encrypts and Base64 encodes str
    def encrypt(str)
      Base64.encode64(Certificate.encryption_certificate.to_rsa_keypair.public_encrypt(str))
    end
    
    # Assumes str is a Base64 encoded string encrypted with our public key
    def decrypt(str)
      Certificate.encryption_certificate.to_rsa_keypair.private_decrypt(Base64.decode64(str))
    end

    protected

    def generate_ca_certificate
      options = {
        :serial => 0,
        :self_signed => true,
        :subject => "O=SteamCannon Instance, CN=CA",
        :extensions => [
                        [ "basicConstraints", "CA:TRUE", true ],
                        [ "keyUsage", "cRLSign,keyCertSign", true ]
                       ]
      }

      cert, keypair = generate_certificate(options)

      Certificate.create(:cert_type => Certificate::CA_TYPE,
                         :certificate => cert.to_pem,
                         :keypair => keypair.to_pem)
    end

    def generate_client_certificate
      options = {
        :serial => 1,
        :subject => "O=SteamCannon Instance, CN=Client",
        :extensions => [
                        [ "basicConstraints", "CA:FALSE", true ],
                        [ "keyUsage", "nonRepudiation, digitalSignature, keyEncipherment", true ],
                        ["extendedKeyUsage", "clientAuth"]
                       ]
      }

      cert, keypair = generate_certificate(options)

      Certificate.create(:cert_type => Certificate::CLIENT_TYPE,
                         :certificate => cert.to_pem,
                         :keypair => keypair.to_pem)
    end

    def generate_encryption_certificate
      options = {
        :serial => 1,
        :subject => "O=SteamCannon Instance, CN=Encryption",
        :extensions => [
                        [ "basicConstraints", "CA:FALSE", true ],
                        [ "keyUsage", "keyEncipherment", true ]
                       ]
      }

      cert, keypair = generate_certificate(options)

      Certificate.create(:cert_type => Certificate::ENCRYPTION_TYPE,
                         :certificate => cert.to_pem,
                         :keypair => keypair.to_pem)
    end

    def generate_certificate(options)
      keypair = OpenSSL::PKey::RSA.new(1024)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2 #x509v3 is 2 here. v1 is 0
      cert.serial = options[:serial]
      cert.subject = OpenSSL::X509::Name.parse(options[:subject])
      cert.issuer = options[:self_signed] ? cert.subject : ca_certificate.to_x509_certificate.subject
      cert.not_before = Time.now
      cert.not_after = Time.now + (10*365*24*60*60) #10 years
      cert.public_key = keypair.public_key

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = options[:self_signed] ? cert.subject : ca_certificate.to_x509_certificate
      options[:extensions] ||= []
      options[:extensions] << ["subjectKeyIdentifier", "hash"]
      cert.extensions = options[:extensions].collect do |extension|
        ef.create_extension(*extension)
      end

      cert.sign(options[:self_signed] ? keypair : ca_certificate.to_rsa_keypair, OpenSSL::Digest::SHA1.new)

      [cert, keypair]
    end

  end
end
