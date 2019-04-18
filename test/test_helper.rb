# frozen_string_literal: true

require "simplecov"
require "coveralls"
require "webmock/minitest"

Coveralls.wear!

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [ SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter ])

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "killer_queen_scene_scoring"
require "vcr"
require "minitest/autorun"

VCR.configure do |config|
    config.cassette_library_dir = "test/vcr_cassettes"
    config.debug_logger = File.new("log/vcr_test.log", "a")
    config.ignore_localhost = true
    config.default_cassette_options = {
        record: :new_episodes,
        re_record_interval: 5 * 60 * 60 * 24 }  # 5 days
    config.hook_into :webmock
end

class KillerQueenSceneScoringTestBase < MiniTest::Test
    def self.test(name, &block)
        test_name = "test_#{name.gsub(/\s+/, '_')}".to_sym
        defined = method_defined?(test_name)

        raise "#{test_name} is already defined in #{self}" if defined

        if block_given?
            define_method(test_name, &block)
        else
            define_method(test_name) do
                flunk "No implementation was provided for #{name}"
            end
        end
    end
end
