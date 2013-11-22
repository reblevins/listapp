require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'builder'
require 'sinatra/content_for'
require 'bundler'
require 'rack/flash'

enable :sessions  

SITE_TITLE = "Events"  
SITE_DESCRIPTION = "for all your events"

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")  
  
class Event
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :name, String, :required => true
  property :description, Text
  property :occurs_on, DateTime, :required => true
  property :created_at, DateTime, :default => DateTime.now
  property :updated_at, DateTime, :default => DateTime.now
  
  has n, :items
  belongs_to :user, :required => false
end

class Item
  include DataMapper::Resource
  
  property :id, Serial, :key => true
  property :name, String, :required => true
  property :amount, Integer
  property :claimed, Boolean, :default => false
  property :created_at, DateTime, :default => DateTime.now
  property :updated_at, DateTime, :default => DateTime.now
  
  belongs_to :event
end

class User
  include DataMapper::Resource
#  include BCrypt

  property :id, Serial, :key => true
  property :username, String
  property :password, Integer
  
  has n, :events
  
  def authenticate(attempted_password)
    if self.password == attempted_password
      true
    else
      false
    end
  end
end
  
DataMapper.finalize.auto_upgrade!

use Rack::Session::Cookie, secret: "theg3lako8kach4baka3dili2by4taqu5tha1ghal5cod"
use Rack::Flash, accessorize: [:error, :success]
#
#use Warden::Manager do |config|
#  # Tell Warden how to save our User info into a session.
#  # Sessions can only take strings, not Ruby code, we'll store
#  # the User's `id`
#  config.serialize_into_session{|user| user.id }
#  # Now tell Warden how to take what we've stored in the session
#  # and get a User from that information.
#  config.serialize_from_session{|id| User.get(id) }
#
#  config.scope_defaults :default,
#    # "strategies" is an array of named methods with which to
#    # attempt authentication. We have to define this later.
#    strategies: [:password],
#    # The action is a route to send the user to when
#    # warden.authenticate! returns a false answer. We'll show
#    # this route below.
#    action: 'auth/unauthenticated'
#  # When a user tries to log in and cannot, this specifies the
#  # app to send the user to.
#  config.failure_app = self
#end
#
#Warden::Manager.before_failure do |env,opts|
#  env['REQUEST_METHOD'] = 'POST'
#end
#
#Warden::Strategies.add(:password) do
#  def valid?
#    params['user'] && params['user']['username'] && params['user']['password']
#  end
#
#  def authenticate!
#    user = User.first(username: params['user']['username'])
#
#    if user.nil?
#      fail!("The username you entered does not exist.")
#      flash.error = ""
#    elsif user.authenticate(params['user']['password'])
#      flash.success = "Successfully Logged In"
#      success!(user)
#    else
#      fail!("Could not log in")
#    end
#  end
#end
    
helpers do
    include Rack::Utils
    alias_method :h, :escape_html
end

get '/' do
    @events = Event.all :order => :created_at.asc
    @title = 'All Events'
    if @events.empty?
        flash[:error] = 'No events found. Add your first below.'
    end
    erb :home
end

post '/' do
  e = Event.new(:name => params[:name], :description => params[:description], :occurs_on => DateTime.parse(params[:occurs_on]))
  if e.save
    redirect '/', :notice => 'Event created successfully.'
  else
    flash[:error] = 'Failed to save event.'
    i = 0
    e.errors.each do |error|
      error_type = 'error_' + i.to_s
      flash[error_type] = error[0]
      i = i + 1
    end
    redirect '/'
  end  
end

post '/update_event_name' do
  e = Event.get params[:id]
  e.name = params[:update_value]
  if e.save
    e.name
  else
    "Error"
  end
end

post '/update_event_description' do
  e = Event.get params[:id]
  e.description = params[:update_value]
  if e.save
    e.description
  else
    "Error"
  end
end

post '/update_event_date' do
  e = Event.get params[:id]
  e.occurs_on = params[:update_value]
  if e.save
    e.occurs_on.strftime('%a %b %d, %Y %l:%M %p')
  else
    "Error"
  end
end

post '/update_item_name' do
  i = Item.get params[:element_id].gsub( 'item_name_', '')
  i.name = params[:update_value]
  if i.save
    i.name
  else
    "Error"
  end
end

post '/update_item_amount' do
  i = Item.get params[:element_id].gsub( 'item_amount_', '')
  i.amount = params[:update_value].to_i
  if i.save
    i.amount.to_s
  else
    "Error"
  end
end

post '/:id/add' do
  @event = Event.get params[:id]
  if @item = @event.items.create(:name => params[:name], :amount => params[:amount].to_i, :created_at => DateTime.now, :updated_at => DateTime.now)
    erb :"partials/list_item.js", :layout => false
  else
    redirect '/' + params[:id],  :error => 'Error adding new item.'
  end
end

get '/:id' do  
    @event = Event.get params[:id]
    @title = "Edit event ##{params[:id]}"
    @items = @event.items.all :order => :created_at.asc
    if @event  
        erb :edit  
    else  
        redirect '/', :error => "Can't find that event."  
    end  
end

put '/:id' do  
  e = Event.get params[:id]  
  e.name = params[:name]
  e.description = params[:description]
  e.occurs_on = params[:occurs_on]
  e.updated_at = DateTime.now  
  if e.save  
      redirect '/' + params[:id], :notice => 'Event updated successfully.' 
  else 
      redirect '/' + params[:id], :error => 'Error updating event.'  
  end
end

get '/:id/:item_id/edit' do
  @event = Event.get params[:id]
  @item = @event.items.get params[:item_id]
  if @item
    erb :edit_item
  else
    redirect '/#{params[:i]', :error => "Can't find that item"
  end
end

put '/:id/:item_id' do
  i = Item.get params[:item_id]
  i.name = params[:name]
  i.amount = params[:amount].to_i
  i.updated_at = DateTime.now
  if i.save
    redirect '/' + params[:id], :notice => 'Item updated successfully'
  else
    flash[:error] = 'Failed to save item'
    i = 0
    e.errors.each do |error|
      error_type = 'error_' + i.to_s
      flash[error_type] = error[0]
      i = i + 1
    end
    redirect '/' + params[:id] + '/' + params[:item_id] + '/edit'
  end  
end
    
get '/:id/delete' do  
    @event = Event.get params[:id]  
    @title = "Confirm deletion of event ##{params[:id]}"  
    if @event  
        erb :delete  
    else  
        redirect '/', :error => "Can't find that event."  
    end  
end

delete '/:id' do  
    e = Event.get params[:id]
    e.items.all.destroy
    if e.destroy  
        redirect '/', :notice => 'Event deleted successfully.'  
    else  
        redirect '/', :error => 'Error deleting event.'  
    end  
end

delete '/:id/:item_id/delete_item' do
  e = Event.get params[:id]
  i = e.items.get params[:item_id] 
  if i.destroy
      redirect '/' + params[:id], :notice => 'Item deleted successfully.'  
  else  
      redirect '/' + params[:id], :error => 'Error deleting item.'  
  end  
end

#get '/auth/login' do
#  erb :login
#end
#
#post '/auth/login' do
#  env['warden'].authenticate!
#
#  flash.success = env['warden'].message
#
#  if session[:return_to].nil?
#    redirect '/'
#  else
#    redirect session[:return_to]
#  end
#end
#
#get '/auth/logout' do
#  env['warden'].raw_session.inspect
#  env['warden'].logout
#  flash.success = 'Successfully logged out'
#  redirect '/'
#end
#
#post '/auth/unauthenticated' do
#  session[:return_to] = env['warden.options'][:attempted_path]
#  puts env['warden.options'][:attempted_path]
#  flash[:error] = env['warden'].message || "You must log in"
#  redirect '/auth/login'
#end
#
#get '/protected' do
#  env['warden'].authenticate!
#  @current_user = env['warden'].user
#  erb :protected
#end