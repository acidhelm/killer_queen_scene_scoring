# frozen_string_literal: true

module KillerQueenSceneScoring

class Team
    attr_reader :id, :name, :final_rank
    attr_accessor :points

    # `challonge_obj` is the Challonge data for this team.
    def initialize(challonge_obj)
        @id = challonge_obj[:id]
        @name = challonge_obj[:name]
        @final_rank = challonge_obj[:final_rank]
        @points = 0.0
    end
end

end
