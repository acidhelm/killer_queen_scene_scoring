require "test_helper"

class KillerQueenSceneScoringTest < Minitest::Test
    def test_the_version_number
        refute_nil KillerQueenSceneScoring::VERSION
    end

    def test_a_6_team_tournament
        api_key = ENV["CHALLONGE_API_KEY"]

        if !api_key
            flunk "You must set the CHALLONGE_API_KEY variable in your environment" \
                    " or the .env file to your API key."
        end

        tournament = KillerQueenSceneScoring::Tournament.new(
                       id: "tvtpeasf", api_key: api_key,
                       logger: Logger.new("log/test.log"))

        VCR.use_cassette("calc_scores_tvtpeasf") do
            assert tournament.load
        end

        # TODO: Check the scene and score names.
        tournament.calculate_points
    end
end
