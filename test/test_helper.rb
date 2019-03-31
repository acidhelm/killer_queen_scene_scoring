# frozen_string_literal: true

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
