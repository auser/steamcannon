# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|
  # Specify a custom renderer if needed.
  # The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
  # The renderer can also be specified as option in the render_navigation call.
  # navigation.renderer = Your::Custom::Renderer
  navigation.renderer = SimpleNavigation::Renderer::List

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  navigation.selected_class = 'selected'

  # Item keys are normally added to list items as id.
  # This setting turns that off
  # navigation.autogenerate_item_ids = false

  # You can override the default logic that is used to autogenerate the item ids.
  # To do this, define a Proc which takes the key of the current item as argument.
  # The example below would add a prefix to each key.
  # navigation.id_generator = Proc.new {|key| "my-prefix-#{key}"}

  # The auto highlight feature is turned on by default.
  # This turns it off globally (for the whole plugin)
  # navigation.auto_highlight = false

  # Define the primary navigation
  navigation.items do |primary|
    # Add an item to the primary navigation. The following params apply:
    # key - a symbol which uniquely defines your navigation item in the scope of the primary_navigation
    # name - will be displayed in the rendered navigation. This can also be a call to your I18n-framework.
    # url - the address that the generated item links to. You can also use url_helpers (named routes, restful routes helper, url_for etc.)
    # options - can be used to specify attributes that will be included in the rendered navigation item (e.g. id, class etc.)
    #
    # primary.item :key_1, 'name', url, options

    # # Add an item which has a sub navigation (same params, but with block)
    # primary.item :key_2, 'name', url, options do |sub_nav|
    #   # Add an item to the sub navigation (same params again)
    #   sub_nav.item :key_2_1, 'name', url, options
    # end

    # # You can also specify a condition-proc that needs to be fullfilled to display an item.
    # # Conditions are part of the options. They are evaluated in the context of the views,
    # # thus you can use all the methods and vars you have available in the views.
    # primary.item :key_3, 'Admin', url, :class => 'special', :if => Proc.new { current_user.admin? }
    # primary.item :key_4, 'Account', url, :unless => Proc.new { logged_in? }

    # you can also specify a css id or class to attach to this particular level
    # works for all levels of the menu
    # primary.dom_id = 'menu-id'
    # primary.dom_id = 'dashboard-tabs'
    # primary.dom_class = 'ui-tabs ui-widget ui-widget-content ui-corner-all ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header'
    primary.dom_class = 'nav'

    # You can turn off auto highlighting for a specific level
    # primary.auto_highlight = false
    primary.auto_highlight = false

    primary.item :dashboard, 'Dashboard', root_path
    primary.item :artifacts, 'Artifacts', artifacts_path
    #primary.item :deployments, 'deployments', deployments_path
    primary.item :environments, 'Environments', environments_path
    primary.item :cloud_profiles, 'Cloud Profiles', cloud_profiles_path
    primary.item :users, 'Users', users_path, :if => lambda { current_user and current_user.organization_admin? }
    # primary.item :platforms, 'Platforms', platforms_path, :if => lambda { current_user and current_user.superuser? }
    primary.item :account_requests, 'Account Requests', account_requests_path, :if => lambda { invite_only_mode? and current_user and current_user.superuser? }
  end

end
