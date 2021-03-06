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


class InstanceServiceWatcher

  def run
    verify_verifying_instance_services
    configure_configuring_instance_services
    confirm_pending_deployment_instance_services
  end

  def configure_configuring_instance_services
    # TODO: This is a bit inefficient to do one at a time
    InstanceService.configuring.each { |i| i.configure_service }
  end

  def verify_verifying_instance_services
    # TODO: This is a bit inefficient to do one at a time
    InstanceService.verifying.each { |i| i.verify_service }
  end
  
  def confirm_pending_deployment_instance_services
    DeploymentInstanceService.pending.each(&:confirm_deploy)
  end
end
