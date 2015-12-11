$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mongoid'
require 'coveralls'
Coveralls.wear!

Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO
Mongoid.configure do |config|
  config.connect_to('mongoid_pending_changes_test')
end


require 'mongoid/pending_changes'

RSpec.configure do |config|
  def clean_db
    Mongoid.purge!
  end

  config.before(:each) do
    clean_db
  end

  config.after(:each) do
    clean_db
  end
end