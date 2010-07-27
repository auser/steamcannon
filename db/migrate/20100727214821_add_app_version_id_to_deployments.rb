class AddAppVersionIdToDeployments < ActiveRecord::Migration
  def self.up
    add_column :deployments, :app_version_id, :integer
  end

  def self.down
    remove_column :deployments, :app_version_id
  end
end
