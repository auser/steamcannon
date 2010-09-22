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

class InstanceService < ActiveRecord::Base
  belongs_to :instance
  belongs_to :service

  def name
    service.name
  end

  def configure
    send("configure_#{name}") if respond_to?("configure_#{name}")
  end

  protected

  def cloud_specific_hacks
    "Cloud::#{instance.cloud.name.camelize}".constantize
  end

  def configure_jboss_as
    config = cloud_specific_hacks.multicast_config(instance).to_json
    instance.agent_client(service.name).configure(config)
  end
end
