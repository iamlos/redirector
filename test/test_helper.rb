# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

class ActiveSupport::TestCase

  # Helper methods to be used by all tests here...

  def teardown

    # Reset tracking_url
    Redirector.setup do |config|
      config.tracking_url = nil
    end

  end

  # Make sure that each test case has a teardown
  # method to clear the db after each test.
  def inherited(base)
    base.define_method teardown do
      super
    end
  end

end

require 'mocha/setup'
