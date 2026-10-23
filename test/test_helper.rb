ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

# Tests never talk to theCrag, UKC, Boardsesh or anything else on the network:
# a request that was not stubbed fails the test. Localhost stays open for
# system tests, which drive the browser over it.
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  # Include devise test helpers for integration tests
  include Devise::Test::IntegrationHelpers
end
