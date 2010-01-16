class UsersController < ApplicationController

  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:search, :show, :edit, :update]
  
  def new
    @user = User.new
  end
  
  def show
    @user = @current_user
  end

  def edit
    @user = @current_user
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end
  
  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to account_url
    else
      render :action => :edit
    end
  end

  def index
    # TODO PAGINATION
    # TODO KEEP AS AN ADMINISTRATIVE ROLE
    @users = User.all
  end

  def search
    # this is a debugging support method to provide a boring list view of your posts filtered by minimal criteria
    @notes = Note.find(:all , :conditions => { :owner_id=> @current_user.id }, :order => "created_at DESC" )
    render :template => 'notes/search' 
  end

end
