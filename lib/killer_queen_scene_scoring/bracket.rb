# frozen_string_literal: true

module KillerQueenSceneScoring

class Bracket
    attr_reader :players, :config

    # `id` can be the slug or the challonge ID of the bracket.  If you pass a
    #  and the bracket is owned by an organization, it must be of the form
    # "<org name>-<slug>".  `api_key` is your Challonge API key.
    def initialize(id:, api_key:)
        @id = id
        @api_key = api_key
        @loaded = false
        @state == ""
    end

    def complete?
        @state == "complete"
    end

    # Reads the Challonge bracket with the ID that was passed to the constructor,
    # and fills in all the data structures that represent that bracket.
    # Returns a boolean indicating whether the bracket was loaded.
    def load
        url = "https://api.challonge.com/v1/tournaments/#{@id}.json"
        params = { include_matches: 1, include_participants: 1 }

        begin
            response = send_get_request(url, params)
        rescue RestClient::NotFound
            # Bail out if we got a 404 error.  The bracket doesn't exist on
            # Challonge right now, but it might be created in the future.
            # TODO: Rails.logger.warn "The bracket does not exist."
            return false
        end

        # Set `@challonge_bracket` to the data structure that represents the
        # bracket, its teams, and its matches.  We also keep the bracket's
        # state separately, for convenience.
        @challonge_bracket = OpenStruct.new(response[:tournament])
        @state = @challonge_bracket.state

        # Bail out if the bracket hasn't started yet.  This lets the tournament
        # organizer set the `next_bracket` value to a bracket that has been
        # created on Challonge, but which will be started in the future.  For
        # example, the organizer can create a wild card bracket and a finals
        # bracket, and set `next_bracket` in the wild card bracket to the ID
        # of the finals bracket before the wild card bracket has finished.
        if @challonge_bracket.started_at.nil?
            # TODO: Rails.logger.warn "The bracket has not been started yet."
            return false
        end

        # Read all the things.
        read_config
        read_teams
        read_matches
        read_players

        @loaded = true
        true
    end

    # Calculates how many points each player has earned in this bracket.  If the
    # bracket is not yet complete, the point values are the mininum number of
    # points that the player can earn based on their current position in
    # the bracket.
    # On exit, `@players` contains a hash.  The keys are the Challonge IDs of
    # the teams in the bracket.  The values are arrays of `Player` objects
    # representing the players on the team.
    # The caller must call `load`, and `load` must succeed, before calling this
    # function.
    def calculate_points
        raise_error "The bracket was not loaded" if !@loaded

        calculate_team_points
        calculate_player_points
    end

    protected

    def finalizable?
        @state == "awaiting_review"
    end

    def raise_error(msg)
        # TODO: Rails.logger.error "ERROR: #{msg}"
        raise msg
    end

    # Reads the config file from the bracket.
    def read_config
        # Find the match that has the config file attached to it.  By convention,
        # the file is attached to the first match, although we don't enforce that.
        # We just look for a match with exactly one attachment.  We do require
        # that exactly one match have exactly one attachment.
        first_match = @challonge_bracket.matches.select do |match|
            match[:match][:attachment_count] == 1
        end

        raise_error "No matches with one attachment were found in the bracket" if first_match.empty?
        raise_error "Multiple matches have one attachment" if first_match.size > 1

        # Read the options from the config file that's attached to that match.
        url = "https://api.challonge.com/v1/tournaments/#{@id}/matches/" \
                "#{first_match[0][:match][:id]}/attachments.json"

        attachment_list = send_get_request(url)
        asset_url = attachment_list[0][:match_attachment][:asset_url]

        raise_error "Couldn't find the config file attachment" if asset_url.nil?

        uri = URI(asset_url)

        # The attachment URLs that Challonge returns don't have a scheme, and
        # instead start with "//".  Default to HTTPS.
        uri.scheme ||= "https"

        # TODO: Rails.logger.debug "Reading the config file from #{uri}"

        # Read the config file from the attchment.
        config = send_get_request(uri.to_s)

        # Ensure that the required values are in the config file.
        %i(base_point_value max_players_to_count match_values).each do |key|
            raise_error "The config file is missing \"#{key}\"" unless config.key?(key)
        end

        @config = Config.new(config)
    end

    # Reads the teams that are in this bracket, and sets `@teams` to an array
    # of `Team` objects.
    def read_teams
        @teams = []

        # Make a `Team` for each participant in the bracket.
        @challonge_bracket.participants.each do |team|
            @teams << Team.new(team[:participant])
        end

        # TODO: Rails.logger.info "#{@teams.size} teams are in the bracket: " +
        #                  @teams.sort_by(&:name).map { |t| %("#{t.name}") }.join(", ")

        # Check that all of the teams in the bracket are also in the config file.
        # We do case-insensitive name comparisons to allow for different
        # capitalizations of prepositions and articles.  This is fine, because
        # two teams' names will never be the same except for case.
        missing_teams = []
        config_team_names = @config.teams.map { |t| t[:name] }

        @teams.each do |team|
            if config_team_names.none? { |name| name.casecmp?(team.name) }
                missing_teams << team.name
            end
        end

        if missing_teams.any?
            raise_error "These teams are in the bracket but not the config file: " +
                        missing_teams.join(", ")
        end
    end

    # Reads the matches that are in this bracket, and sets `@matches` to an array
    # of `Match` objects.
    def read_matches
        # Check that `match_values` in the config file is the right size.
        # The size must normally equal the number of matches.  However, if the
        # bracket is complete (finalized, or not finalized but all matches have
        # been played) and it is double-elimination, then the array size is
        # allowed to be one more than the number of matches, to account for a grand
        # final that was only one match long.
        #
        # TODO: Also check that grand_finals_modifier is not set.
        #
        # If this is a two-stage bracket, the matches in the first stage have
        # `suggested_play_order` set to nil, so don't consider those matches.
        # If there is a match for 3rd place, its `suggested_play_order` is nil.
        # We also ignore that match, and instead, we award points to the 3rd-place
        # and 4th-place teams after the bracket has finished.
        @matches = []
        elim_stage_matches =
            @challonge_bracket.matches.select { |m| m[:match][:suggested_play_order] }
        num_matches = elim_stage_matches.size
        config_array_size = @config.match_values.size

        if num_matches != config_array_size
            if !(complete? || finalizable?) ||
               @challonge_bracket.tournament_type != "double elimination" ||
               config_array_size != num_matches + 1
                raise_error "match_values in the config file is the wrong size." \
                              " The size is #{config_array_size}, expected #{num_matches}."
            end
        end

        # Make a `Match` for each match in the bracket.
        elim_stage_matches.each do |match|
            @matches << Match.new(match[:match], @config.match_values)
        end
    end

    # Reads the players that are in this bracket, and sets `@players` to a hash.
    # Each key is a Challonge ID of a team, and each value is an array of
    # `Player` objects for the players on that team.
    def read_players
        @players = Hash.new { |h, k| h[k] = [] }

        # Read the team list from the config file and create structs for each
        # player on each team.
        @config.teams.each do |team|
            # Look up the team in the `@teams` array.  This is how we associate a
            # team in the config file with its Challonge ID.
            team_obj = @teams.find { |t| t.name.casecmp?(team[:name]) }

            # If the `find` call failed, then there is a team in the team list that
            # isn't in the bracket.  We allow this so that multiple brackets can
            # use the same master team list during a tournament.
            if team_obj.nil?
                # TODO: Rails.logger.info "Skipping a team that isn't in the bracket: #{team[:name]}"
                next
            end

            team[:players].each do |player|
                @players[team_obj.id] << Player.new(player)
            end

            # TODO: Rails.logger.info "#{team[:name]} (ID #{team_obj.id}) has: " +
            #                  @players[team_obj.id].map { |p| "#{p.name} (#{p.scene})" }.join(", ")
        end

        # Bail out if any team doesn't have exactly 5 players.
        # TODO: Do this in `read_config` instead.
        invalid_teams = @players.select do |_, team|
            team.size != 5
        end.each_key.map do |team_id|
            @teams.find { |t| t.id == team_id }.name
        end

        if invalid_teams.any?
            raise_error "These teams don't have 5 players: #{invalid_teams.join(', ')}"
        end
    end

    # Calculates how many points each team has earned in this bracket.  If the
    # bracket is not yet complete, the values are the mininum number of points
    # that the team can receive based on their current position in the bracket.
    # Sets the `points` member of each object in `@teams` to the number of
    # points that each team member has earned.
    def calculate_team_points
        # If the bracket is complete, we can calculate points based on the
        # teams' `final_rank`s.
        if complete?
            calculate_team_points_by_final_rank
            return
        end

        # For each team, look at the matches that it is in, look at the point
        # values of those matches, and take the maximum point value.  That's the
        # number of points that the team has earned so far in the bracket.
        base_point_value = @config.base_point_value

        @teams.each do |team|
            matches_with_team = @matches.select { |match| match.has_team?(team.id) }

            # TODO: Rails.logger.info "Team #{team.name} was in #{matches_with_team.size} matches"

            points_earned = matches_with_team.max_by(&:points).points

            # TODO: Rails.logger.info "The largest point value of those matches is #{points_earned}" \
            #                  "#{" + #{base_point_value} base" if base_point_value > 0}"

            team.points = points_earned + base_point_value
        end
    end

    # Calculates how many points each player has earned in the tournament, and
    # sets the `points` member of each object in `@players` to that value.
    def calculate_player_points
        # Iterate over the teams in descending order of their scores.  This way,
        # the debug output will follow the teams' finishing order, which will be
        # easier to read.
        @teams.sort_by(&:points).reverse_each do |team|
            # TODO: Rails.logger.info "Awarding #{team.points} points to #{team.name}: " +
            #                  @players[team.id].map(&:to_s).join(", ")

            @players[team.id].each do |player|
                player.points = team.points
            end
        end
    end

    # Calculates how many points each team earned in this bracket.
    # Sets the `points` member of each object in `@teams` to the number of
    # points that each team member has earned.
    def calculate_team_points_by_final_rank
        # Calculate how many points to award to each rank.  When multiple teams
        # have the same rank (e.g., two teams tie for 5th place), those teams
        # get the average of the points available to those ranks.  For example,
        # in a 6-team bracket, the teams in 1st through 4th place get 6 through 3
        # points respectively.  The two teams in 5th get 1.5, the average of 2 and 1.
        sorted_teams = @teams.sort_by(&:final_rank)
        num_teams = sorted_teams.size.to_f
        final_rank_points = Hash.new { |h, k| h[k] = [] }

        sorted_teams.each_with_index do |team, idx|
            final_rank_points[team.final_rank] << num_teams - idx
        end

        base_point_value = @config.base_point_value

        sorted_teams.each do |team|
            points_earned = final_rank_points[team.final_rank].sum /
                              final_rank_points[team.final_rank].size

            # TODO: Rails.logger.info "#{team.name} finished in position #{team.final_rank}" \
            #                  " and gets #{points_earned} points" \
            #                  "#{" + #{base_point_value} base" if base_point_value > 0}"

            team.points = points_earned + base_point_value
        end
    end

    # Sends a GET request to `url`, treats the returned data as JSON, parses it
    # into an object, and returns that object.
    def send_get_request(url, params = {})
        params[:api_key] = @api_key
        resp = RestClient.get(url, params: params)

        JSON.parse(resp, symbolize_names: true)
    end
end

end
