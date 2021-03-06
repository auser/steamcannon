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

ActionController::Routing::Routes.draw do |map|
  map.resources :cloud_profiles,
    :member => { :cloud_settings_block => :get, :validate_cloud_credentials => :get },
    :collection => { :validate_cloud_credentials => :get }

  map.resources :account_requests, :collection => { :invite => :post, :ignore => :post }

  map.resources :artifacts, :member => { :status => :post } do |artifacts|
    artifacts.resources :artifact_versions, :member => { :status => :get }
  end
  map.resources :platforms
  map.resources :hardware_profiles, :only => [ :index, :show ]
  map.resources :realms, :only => [ :index, :show ]
  map.resources :environments,
                :member => {:start => :post, :stop => :post, :clone => :post,
                            :instance_states => :get, :deltacloud => :get,
                            :usage => :get},
                :collection => {:status => :get} do |environment|

    environment.resources :images, :only => [ :index, :show ]
    environment.resources :instances, :member => {:stop => :post, :status => :post, :clone => :post}, :only => [:show, :index, :create] do |instance|
      instance.resources :instance_services, :member => {:logs => :get}, :only => []
    end

    environment.resources :storage_volumes, :member => {:status => :post}, :only => [:destroy]
    environment.resources :deployments, :member => {:status => :post, :undeploy => :post}
  end

  map.with_options :controller => 'events' do |events|
    events.events_for_subject '/events/:subject_id', :action => 'index'
    events.partial_events_for_subject '/partial_events/:subject_id', :action => 'partial_index'
  end

  map.resources :users, :member => {:assume_user => :get, :promote => :post, :demote => :post}
  map.resources :cloud_instances, :only => [:index, :destroy]

  map.resource :user_session
  map.resource :account, :controller => "users"
  map.resource :dashboard, :controller => "dashboard"

  map.new_user_from_token '/signup/:token', :controller => "users", :action => "new"

  map.resources :password_resets

  map.api '/api.:format', :controller => 'api', :action=>'index'

  # map.forgot_password '/forgot_password', :controller => 'PasswordResets', :action => "new"
  # map.reset_password '/reset_password', :controller => 'PasswordResets', :action => "create"
  # map.edit_password '/edit_password/:id', :controller => 'PasswordResets', :action => "edit"
  # map.change_password '/change_password/:id', :controller => 'PasswordResets', :action => "update"

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "dashboard", :action => "show"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  # map.connect ':controller/:action/:id'
  # map.connect ':controller/:action/:id.:format'
end
