# frozen_string_literal: true

module KillerQueenSceneScoring

class Base
    attr_reader :api_key, :logger

    def initialize(api_key, logger = nil)
        @api_key = api_key

        @logger = case logger
                      when true
                          Logger.new(STDOUT, progname: "KillerQueenSceneScoring")
                      when Logger
                          logger
                      else
                          nil
                  end
    end

    # Creates a hash whose values are arrays.
    def hash_of_arrays
        Hash.new { |h, k| h[k] = [] }
    end

    def log_debug(msg)
        @logger&.debug msg
    end

    def log_info(msg)
        @logger&.info msg
    end

    def log_warn(msg)
        @logger&.warn msg
    end

    def log_error(msg)
        @logger&.error msg
    end
end

end
