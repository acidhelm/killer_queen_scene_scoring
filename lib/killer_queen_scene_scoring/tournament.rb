# frozen_string_literal: true

module KillerQueenSceneScoring

class Tournament
    attr_reader :scene_scores, :complete

    # `id` can be the slug or the challonge ID of the first bracket in the
    # tournament.  If you pass a slug, and the bracket is owned by an organization,
    # it must be of the form "<org name>-<slug>".
    # `api_key` is your Challonge API key.
    def initialize(id:, api_key:)
        @brackets = []
        @scene_scores = []
        @loaded = false
        @complete = false
        @id = id
        @api_key = api_key
    end

    # Reads the Challonge bracket with the ID that was passed to the constructor,
    # and fills in all the data structures that represent that bracket and any
    # later brackets in the tournament.  `@complete` is also set to indicate
    # whether the entire tournament is complete.
    # Returns true if at least one bracket was loaded, and false otherwise.
    def load
        @loaded = false
        tournament_id = @id
        all_brackets_loaded = true

        while tournament_id
            # TODO: Rails.logger.debug "Reading the bracket \"#{tournament_id}\""

            # Load the next bracket in the chain.  Bail out if we can't load it.
            bracket = Bracket.new(id: tournament_id, api_key: @api_key)

            if !bracket.load
                all_brackets_loaded = false
                break
            end

            # Store that bracket.
            @brackets << bracket

            # For debugging purposes, log the players in each scene ->
            scenes = Hash.new { |h, k| h[k] = [] }

            bracket.players.each_value do |team|
                team.each do |player|
                    scenes[player.scene] << player
                end
            end

            scene_list = scenes.map do |scene, players|
                "#{scene} has #{players.size} players: " +
                  players.map(&:name).join(", ")
            end

            # TODO: Rails.logger.info scene_list.join("\n")
            # <- end debug logging

            # Go to the next bracket in the chain.
            tournament_id = bracket.config.next_bracket
        end

        return false if @brackets.empty?

        # Check that all the config files have the same `max_players_to_count`.
        values = @brackets.map { |b| b.config.max_players_to_count }

        if values.count(values[0]) != values.size
            msg = "ERROR: All brackets must have the same \"max_players_to_count\"."
            # TODO: Rails.logger.error msg
            raise msg
        end

        # If we loaded all the brackets in the list of brackets, set our
        # `complete` member based on the completed state of the last bracket.
        # We only check the last bracket because previous brackets in the
        # sequence are not guaranteed to be marked as complete on Challonge.
        # For an example, see "bb3wc".  The BB3 wild card bracket was not
        # marked as complete because play stopped once it got down to 4 teams.
        @complete = all_brackets_loaded && @brackets.last.complete?

        @loaded = true
        true
    end

    # Calculates the score for each scene in the tournament, and sets
    # `@scene_scores` to an array of `Scene` objects.
    # The caller must call `load`, and `load` must succeed, before calling this
    # function.
    def calculate_points
        raise "The tournament was not loaded" unless @loaded

        @brackets.each(&:calculate_points)
        calculate_scene_points
    end

    protected

    # Calculates how many points each scene has earned in the tournament.
    # Sets `@scene_scores` to an array of `Scene` objects.
    def calculate_scene_points
        # Collect the scores of all players from the same scene.  Since a player
        # may be in multiple brackets, we find their greatest score across
        # all brackets.
        # `player_scores` is a hash from a `Player` object's hash to the `Player`
        # object.  This is a hash to make lookups easier; the keys aren't used
        # after# this loop.
        player_scores = @brackets.each_with_object({}) do |bracket, scores|
            bracket.players.each_value do |team_players|
                team_players.each do |player|
                    key = player.hash

                    if !scores.key?(key) || player.points > scores[key].points
                        scores[key] = player
                    end
                end
            end
        end

        # Assemble the scores from the players in each scene.
        # `scene_players_scores` is a hash from a scene name to an array that
        # holds the scores of all the players in that scene.
        scene_players_scores = Hash.new { |h, k| h[k] = [] }

        player_scores.each_value do |player|
            scene_players_scores[player.scene] << player.points
        end

        @scene_scores = scene_players_scores.map do |scene, scores|
            # If a scene has more players than the max number of players whose
            # scores can be counted, drop the extra players' scores.
            # Sort the scores for each scene in descending order, so we only
            # keep the highest scores.
            max_players_to_count = @brackets[0].config.max_players_to_count
            scores.sort!.reverse!

            if scores.size > max_players_to_count
                dropped = scores.slice!(max_players_to_count..-1)

                # TODO: Rails.logger.info "Dropping the #{dropped.size} lowest scores from #{scene}:" +
                #                  dropped.join(", ")
            end

            # Add up the scores for this scene.
            Scene.new(scene, scores)
        end
    end
end

end
