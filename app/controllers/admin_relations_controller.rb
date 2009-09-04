require 'note.rb'

class AdminRelationsController < ApplicationController
  before_filter :require_admin
  layout "admin"
  active_scaffold :relation do |config|
    config.label = '<a href="/users_admin">Users</a> <a href="/notes_admin">Notes</a> Relations'
  end
end

