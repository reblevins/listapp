# Initial setup for Ruby 1.9.3 on DreamHost shared hosting.
# We assume you're already in your project's root directory, which should
# also be the directory configured as "web directory" for your domain
# in the DreamHost panel.
 
 
# Install rbenv and ruby-build
git clone git://github.com/sstephenson/rbenv.git ~/.rbenv
git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
 
# Create temporary directory--DreamHost does not allow files in /tmp to be 
# executed, which makes the default not work
mkdir ~/.rbenv/BUILD_TEMP
 
# DreamHost will set your GEM_HOME and GEM_PATH for you, but this conflicts
# with rbenv, so we unset them here.  You'll want to do this in your .bashrc
# on the dreamhost account.
unset GEM_HOME
unset GEM_PATH
 
# Add rbenv to PATH and let it set itself up.
# You probably want these two lines in your .bashrc as well:
export PATH=~/.rbenv/bin:"$PATH"
eval "$(~/.rbenv/bin/rbenv init -)"
 
# Decide which version of Ruby we're going to install and use.
NEW_RUBY_VERSION=1.9.3-p327
 
# Using that as the temp space, build and install ruby 1.9.3
TMPDIR=~/.rbenv/BUILD_TEMP rbenv install $NEW_RUBY_VERSION
 
# Now everything is set up properly, you should be able to set your
# directory to use the new ruby:
rbenv local $NEW_RUBY_VERSION
 
# Bundler isn't included with ruby, so install it first:
gem install bundler
 
# Make sure rbenv picks up the newly installed bundler:
rbenv rehash
 
# Then use it to install the rest of your gems:
bundle install
 
# Create the "log" dir in for the file containing the stderr of your dispatch.fcgi script:
mkdir -p log
