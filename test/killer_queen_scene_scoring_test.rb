require "test_helper"

class KillerQueenSceneScoringTest < KillerQueenSceneScoringTestBase
    def setup
        unless (@api_key = ENV["CHALLONGE_API_KEY"])
            flunk "You must set the CHALLONGE_API_KEY variable in your environment" \
                    " or the .env file to your API key."
        end
    end

    def verify_scores(slug, expected_scores)
        tournament = KillerQueenSceneScoring::Tournament.new(
                       id: slug, api_key: @api_key,
                       logger: Logger.new("log/test.log"))

        VCR.use_cassette("verify_scores_#{slug}") do
            assert tournament.load
        end

        tournament.calculate_points

        assert_equal expected_scores.size, tournament.scene_scores.size

        tournament.scene_scores.sort.each_with_index do |score, i|
            assert_equal expected_scores[i][0], score.name
            assert_equal expected_scores[i][1], score.score
        end
    end

    test "The version number must exist" do
        refute_nil KillerQueenSceneScoring::VERSION
    end

    test "Check a 4-team tournament" do
        expected_scores = [ [ "San Francisco", 12.0 ], [ "Charlotte", 6.0 ],
                            [ "Chicago", 6.0 ], [ "Minneapolis", 6.0 ],
                            [ "New York", 5.0 ], [ "Kansas City", 4.0 ],
                            [ "Portland", 1.0 ], [ "Seattle", 1.0 ] ]

        verify_scores("tvtpeasf", expected_scores)
    end

    test "Check the KQ 25 tournament" do
        expected_scores = [ [ "New York", 391.5 ], [ "Chicago", 370.5 ],
                            [ "Charlotte", 316.5 ], [ "Minneapolis", 292.0 ],
                            [ "Portland", 275.0 ], [ "Columbus", 219.5 ],
                            [ "Kansas City", 160.5 ], [ "Seattle", 88.0 ],
                            [ "Madison", 73.0 ], [ "Austin", 46.0 ],
                            [ "San Francisco", 37.0 ], [ "CHA", 21.0 ],
                            [ "Los Angeles", 15.5 ], [ "Iowa", 11.0 ] ]

        verify_scores("clonekqxxvwc", expected_scores)
    end

    test "Check the BB3 tournament" do
        expected_scores = [ [ "New York", 951.0 ], [ "Chicago", 902.5 ],
                            [ "Charlotte", 803.5 ], [ "Portland", 782.5 ],
                            [ "Minneapolis", 735.5 ], [ "San Francisco", 654.5 ],
                            [ "Seattle", 478.5 ], [ "Columbus", 288.0 ],
                            [ "Austin", 279.0 ], [ "Kansas City", 249.0 ],
                            [ "Phoenix", 202.5 ], [ "St. Louis", 132.0 ],
                            [ "Cincinnati", 90.0 ], [ "Chattanooga", 82.5 ],
                            [ "Madison", 70.5 ], [ "Los Angeles", 60.0 ],
                            [ "Atlanta", 55.5 ], [ "South Florida", 45.0 ],
                            [ "Elkader", 28.5 ], [ "Baltimore", 16.5 ],
                            [ "Eugene", 13.5 ], [ "Canada", 4.5 ] ]

        verify_scores("bb3wc", expected_scores)
    end

    test "Try to load a non-existant bracket" do
        slug = "bogustournament"
        url = "https://api.challonge.com/v1/tournaments/#{slug}.json"
        resp = { errors: [ "Requested tournament not found" ] }

        stub_request(:get, url).
            with(query: hash_including(api_key: @api_key)).
            to_return(status: 404, body: resp.to_json)

        tournament = KillerQueenSceneScoring::Tournament.new(
                       id: slug, api_key: @api_key)

       refute tournament.load
    end
end
