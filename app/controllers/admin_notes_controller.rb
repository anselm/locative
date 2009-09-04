class AdminNotesController < ApplicationController
  before_filter :require_admin
  layout "admin"
  active_scaffold :note do |config|
    config.label = '<a href="/users_admin">Users</a> Notes <a href="/relations_admin">Relations</a>'
    config.columns = [:title, :link, :description, :lon, :lat, :rad, :tagstring ]
    #config.ignore_columns.add [ :created_at, :updated_at ]
    list.sorting = {:updated_at => 'ASC'}
    columns[:title].label = "Title"
  end
end

