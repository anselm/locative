ActionController::Routing::Routes.draw do |map|
 
  map.resources :admin_notes, :active_scaffold => true
  map.resources :admin_relations, :active_scaffold => true
  map.resources :admin_users, :active_scaffold => true

  map.resource :account, :controller => "users"
  map.resource :user_session
  map.resources :users
  map.about 'about', :controller => 'index', :action => 'about'
  map.signup 'signup', :controller => 'users', :action => 'new'
  map.signin 'signin', :controller => 'user_sessions', :action => 'new'
  map.signout 'signout', :controller => 'user_sessions', :action => 'destroy'
 
  map.json  'json', :controller => 'index', :action => 'json' 
  map.xml   'xml', :controller => 'index', :action => 'xml' 

  # map.connect 'notes/:number', :controller => 'notes', :action => 'search'
  map.resources :notes, :collection => { :search => [:get, :post] }
  map.resources :notes
 
  # general activities
  # map.admin 'admin', :controller => 'notes', :action => 'admin'
  map.root :controller => 'index', :action => 'index'
 
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

end

