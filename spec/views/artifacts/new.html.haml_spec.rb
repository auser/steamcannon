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

describe "/artifacts/new.html.haml" do
  include ArtifactsHelper

  def current_user

  end
  before(:each) do
    assigns[:artifact] = stub_model(Artifact,
                                    :new_record? => true,
                                    :name => "value for name"
                                    )
    template.stub(:current_user).and_return(mock(User, :cloud_profiles => []))
  end

  it "renders new artifact form" do
    render

    response.should have_tag("form[action=?][method=post]", artifacts_path) do
      with_tag("input#artifact_name[name=?]", "artifact[name]")
      with_tag("textarea#artifact_description[name=?]", "artifact[description]")
    end
  end

  it "should have a cancel link" do
    render
    response.should have_tag("a[href=?]", artifacts_path)
  end
end
