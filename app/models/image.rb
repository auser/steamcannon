class Image < ActiveRecord::Base
  belongs_to :image_role
  has_many :platform_versions, :through => :platform_version_images
  has_many :instances

  validates_presence_of :image_role
end
