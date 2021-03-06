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

Factory.define :certificate do |cert|
  cert.cert_type Certificate::CA_TYPE
  cert.certificate 'the cert'
  cert.keypair 'the keypair'
end

Factory.define :ca_certificate, :parent => :certificate do |cert|
end

Factory.define :client_certificate, :parent => :certificate do |cert|
  cert.cert_type Certificate::CLIENT_TYPE
end

Factory.define :encryption_certificate, :parent => :certificate do |cert|
  cert.cert_type Certificate::ENCRYPTION_TYPE
end

Factory.define :server_certificate, :parent => :certificate do |cert|
  cert.cert_type Certificate::SERVER_TYPE
end
