# frozen_string_literal: true

module KillerQueenSceneScoring

class Player
    attr_reader :name, :scene
    attr_accessor :points

    # `config_obj` is a hash that contains the player's data from the config file.
    def initialize(config_obj)
        @name = config_obj[:name]
        @scene = config_obj[:scene]
        @points = 0.0
    end

    def hash
        to_s.hash
    end

    def to_s
        "#{@name} (#{@scene})"
    end
end

end
