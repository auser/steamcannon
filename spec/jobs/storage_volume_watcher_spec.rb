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

describe StorageVolumeWatcher do
  before(:each) do
    @instance_watcher = StorageVolumeWatcher.new
  end

  it "should try to destroy volumes marked for destruction" do
    @instance_watcher.should_receive(:destroy_volumes_pending_destroy)
    @instance_watcher.run
  end


  it "should attempt to destroy any pending_destroy storage_volumes" do
    storage_volume = mock_model(StorageVolume)
    storage_volume.should_receive(:real_destroy)
    StorageVolume.stub!(:pending_destroy).and_return([storage_volume])
    @instance_watcher.destroy_volumes_pending_destroy
  end


end
