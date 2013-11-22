ENV['GEM_HOME'] = '/home/eventlistapp/.gems'
require 'rubygems'
Gem.clear_paths

require File.expand_path '../app.rb', __FILE__

run Sinatra::Application
