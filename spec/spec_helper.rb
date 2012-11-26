require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

end

Spork.each_run do
  # This code will be run each time you run your specs.

end

# --- Instructions ---
# Sort the contents of this file into a Spork.prefork and a Spork.each_run
# block.
#
# The Spork.prefork block is run only once when the spork server is started.
# You typically want to place most of your (slow) initializer code in here, in
# particular, require'ing any 3rd-party gems that you don't normally modify
# during development.
#
# The Spork.each_run block is run each time you run your specs.  In case you
# need to load files that tend to change during development, require them here.
# With Rails, your application modules are loaded automatically, so sometimes
# this block can remain empty.
#
# Note: You can modify files loaded *from* the Spork.each_run block without
# restarting the spork server.  However, this file itself will not be reloaded,
# so if you change any of the code inside the each_run block, you still need to
# restart the server.  In general, if you have non-trivial code in this file,
# it's advisable to move it into a separate file so you can easily edit it
# without restarting spork.  (For example, with RSpec, you could move
# non-trivial code into a file spec/support/my_helper.rb, making sure that the
# spec/support/* files are require'd from inside the each_run block.)
#
# Any code that is left outside the two blocks will be run during preforking
# *and* during each_run -- that's probably not what you want.
#
# These instructions should self-destruct in 10 seconds.  If they don't, feel
# free to delete them.




# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'simplecov'
SimpleCov.start 'rails'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'factory_girl'
require 'rexml/document'
FactoryGirl.find_definitions

User
class User
  alias real_send_create_notification send_create_notification
  def send_create_notification; end
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

module RSpec
  module Core
    module Hooks
      class HookCollection
        def find_hooks_for(group)
          self.class.new(select {|hook| hook.options_apply?(group)})
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = "#{::Rails.root}/test/fixtures"

  config.before(:each) do
    Localization.lang = :default
  end
end

def define_spec_public_cache_directory
  ActionController::Base.page_cache_directory = File.join(Rails.root, 'spec', 'public')
  unless File.exist? ActionController::Base.page_cache_directory
    FileUtils.mkdir_p ActionController::Base.page_cache_directory
  end
end

def path_for_file_in_spec_public_cache_directory(file)
  define_spec_public_cache_directory
  File.join(ActionController::Base.page_cache_directory, file)
end

def create_file_in_spec_public_cache_directory(file)
  file_path = path_for_file_in_spec_public_cache_directory(file)
  File.open(file_path, 'a').close
  file_path
end

def assert_xml(xml)
  assert_nothing_raised do
    assert REXML::Document.new(xml)
  end
end

def assert_atom10 feed, count
  doc = Nokogiri::XML.parse(feed)
  root = doc.css(':root').first
  root.name.should == "feed"
  root.namespace.href.should == "http://www.w3.org/2005/Atom"
  root.css('entry').count.should == count
end

def assert_rss20 feed, count
  doc = Nokogiri::XML.parse(feed)
  root = doc.css(':root').first
  root.name.should == "rss"
  root['version'].should == "2.0"
  root.css('channel item').count.should == count
end

def stub_default_blog
  blog = stub_model(Blog, :base_url => "http://myblog.net")
  view.stub(:this_blog) { blog }
  Blog.stub(:default) { blog }
  blog
end

def stub_full_article(time=Time.now)
  author = stub_model(User, :name => "User Name")
  text_filter = Factory.build(:textile)

  a = stub_model(Article, :published_at => time, :user => author,
                 :created_at => time, :updated_at => time,
                 :title => "Foo Bar", :permalink => 'foo-bar',
                 :guid => time.hash)
  a.stub(:categories) { [Factory.build(:category)] }
  a.stub(:published_comments) { [] }
  a.stub(:resources) { [Factory.build(:resource)] }
  a.stub(:tags) { [Factory.build(:tag)] }
  a.stub(:text_filter) { text_filter }
  a
end

# test standard view and all themes
def with_each_theme
  yield nil, ""
  Dir.new(File.join(::Rails.root.to_s, "themes")).each do |theme|
    next if theme =~ /\.\.?/
    view_path = "#{::Rails.root.to_s}/themes/#{theme}/views"
    if File.exists?("#{::Rails.root.to_s}/themes/#{theme}/helpers/theme_helper.rb")
      require "#{::Rails.root.to_s}/themes/#{theme}/helpers/theme_helper.rb"
    end
    yield theme, view_path
  end
end

# This test now has optional support for validating the generated RSS feeds.
# Since Ruby doesn't have a RSS/Atom validator, I'm using the Python source
# for http://feedvalidator.org and calling it via 'system'.
#
# To install the validator, download the source from
# http://sourceforge.net/cvs/?group_id=99943
# Then copy src/feedvalidator and src/rdflib into a Python lib directory.
# Finally, copy src/demo.py into your path as 'feedvalidator', make it executable,
# and change the first line to something like '#!/usr/bin/python'.

if($validator_installed == nil)
  $validator_installed = false
  begin
    IO.popen("feedvalidator 2> /dev/null","r") do |pipe|
      if (pipe.read =~ %r{Validating http://www.intertwingly.net/blog/index.})
        puts "Using locally installed Python feed validator"
        $validator_installed = true
      end
    end
  rescue
    nil
  end
end

def assert_feedvalidator(rss, todo=nil)
  unless $validator_installed
    puts 'Not validating feed because no validator (feedvalidator in python) is installed'
    return
  end

  begin
    file = Tempfile.new('typo-feed-test')
    filename = file.path
    file.write(rss)
    file.close

    messages = ''

    IO.popen("feedvalidator file://#{filename}") do |pipe|
      messages = pipe.read
    end

    okay, messages = parse_validator_messages(messages)

    if todo && ! ENV['RUN_TODO_TESTS']
      assert !okay, messages + "\nTest unexpectedly passed!\nFeed text:\n"+rss
    else
      assert okay, messages + "\nFeed text:\n"+rss
    end
  end
end

def parse_validator_messages(message)
  messages=message.split(/\n/).reject do |m|
    m =~ /Feeds should not be served with the "text\/plain" media type/ ||
      m =~ /Self reference doesn't match document location/
  end

  if(messages.size > 1)
    [false, messages.join("\n")]
  else
    [true, ""]
  end
end

# Temporarily define #flunk until rspec-rails 2 beta 21 comes out.
# TODO: Remove this once no longer needed!
def flunk(*args, &block)
  assertion_delegate.flunk(*args, &block)
end

# Make webrat's matchers treat XML like XML.
# See Webrat ticket #345.
# Solution adapted from the following patch:
# http://github.com/indirect/webrat/commit/46b8d91c962e802fbcb14ee0bcf03aab1afa180a
module Webrat #:nodoc:
  module XML #:nodoc:

    def self.document(stringlike) #:nodoc:
      return stringlike.dom if stringlike.respond_to?(:dom)

      case stringlike
      when Nokogiri::HTML::Document, Nokogiri::XML::NodeSet
        stringlike
      else
        stringlike = stringlike.body if stringlike.respond_to?(:body)

        if stringlike.to_s =~ /\<\?xml/
          Nokogiri::XML(stringlike.to_s)
        else
          Nokogiri::HTML(stringlike.to_s)
        end
      end
    end
  end
end

