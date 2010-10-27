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


class UsersController < ResourceController::Base
  navigation :users

  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_open_signup_mode_or_token, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update, :validate_cloud_credentials, :cloud_defaults_block]
  before_filter :require_superuser, :only => [:assume_user]
  before_filter :require_superuser_to_edit_other_user, :only => [:edit, :update]
  skip_before_filter :require_complete_profile, :except => [:show]

  new_action.before do
    object.email = @account_request.email if @account_request
  end
  
  edit.before do
    flash[:error] = "Please complete your profile before continuing." unless current_user.profile_complete?
  end

  update.before do
    if params && params[:user]
      if params[:user][:cloud_password].blank?
        params[:user].delete(:cloud_password)
      else
        current_user.cloud_password_dirty = true
      end
    end
  end

  create do
    flash { "Account registered" }
    after { @account_request.accept! if @account_request }
    wants.html { redirect_stored_or_default root_url }
  end

  update do
    flash { "Account updated" }
    wants.html do
      # lets us share this action between self managed accounts and
      # admin'ed users
      if object == current_user
        redirect_stored_or_default account_url
      else
        redirect_to object_url
      end

    end
  end

  def assume_user
    UserSession.create(object)
    flash[:notice] = "You have assumed the account of '#{object.email}'. You will need to logout and back in to return to your account."
    redirect_to root_path
  end

  def validate_cloud_credentials
    update_cloud_credentials_from_params
    valid = object.cloud.valid_credentials?
    render(generate_json_response(valid ? :ok : :error))
  end

  def cloud_defaults_block
    update_cloud_credentials_from_params
    render(:partial => 'users/cloud_defaults', :locals => { :user => object })
  end

  protected
  def object
    super || current_user
  end

  def collection
    end_of_association_chain.visible_to_user(current_user)
  end

  def require_superuser_to_edit_other_user
    if !current_user.superuser? and current_user != object
      flash[:error] = "You don't have the proper rights to edit that user."
      redirect_to new_user_session_path
    end
  end

  def require_open_signup_mode_or_token
    if !open_signup_mode?
      if params[:token] and
          @account_request = AccountRequest.invited.find_by_token(params[:token])
        flash[:notice] = "Please create an account to continue."
      else
        flash[:error] = "You can't create a new user."
        redirect_to new_user_session_path
      end
    end
  end

  def update_cloud_credentials_from_params
    object.cloud_username = params[:cloud_username] if params[:cloud_username]
    object.cloud_password = params[:cloud_password] if params[:cloud_password]
  end
end
