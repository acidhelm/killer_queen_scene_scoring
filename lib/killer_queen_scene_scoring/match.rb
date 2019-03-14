# frozen_string_literal: true

module KillerQueenSceneScoring

class Match
    attr_reader :points

    # `challonge_obj` is the Challonge data for this match.  `match_values` is
    # the array from the config file that holds how many points are awarded to
    # the teams in that match.
    def initialize(challonge_obj, match_values)
        @team1_id = challonge_obj[:player1_id]
        @team2_id = challonge_obj[:player2_id]

        play_order = challonge_obj[:suggested_play_order]
        @points = match_values[play_order - 1]
    end

    # Returns whether the team with the Challonge ID `team_id` is in this match.
    def has_team?(team_id)
        @team1_id == team_id || @team2_id == team_id
    end
end

end
