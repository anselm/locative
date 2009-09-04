class AdminUsersController < ApplicationController
  before_filter :require_admin
  layout "admin"
  active_scaffold :user do |config|
    config.label = 'Users <a href="/notes_admin">Notes</a> <a href="/relations_admin">Relations</a>'
    config.columns = [:login, :email, :login_count, :last_login_at, :admin ]
    list.sorting = {:login => 'ASC'}
  end
end
