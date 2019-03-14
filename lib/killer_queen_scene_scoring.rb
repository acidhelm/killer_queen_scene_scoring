require "json"
require "rest-client"
require "killer_queen_scene_scoring/bracket.rb"
require "killer_queen_scene_scoring/config"
require "killer_queen_scene_scoring/match"
require "killer_queen_scene_scoring/player"
require "killer_queen_scene_scoring/scene"
require "killer_queen_scene_scoring/team"
require "killer_queen_scene_scoring/tournament"
require "killer_queen_scene_scoring/version"

module KillerQueenSceneScoring
    class Error < StandardError
    end
end
