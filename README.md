# Killer Queen Scene Scoring
[![Build status](https://travis-ci.com/acidhelm/killer_queen_scene_scoring.svg?branch=master)](https://travis-ci.com/acidhelm/killer_queen_scene_scoring)
[![Gem version](https://badge.fury.io/rb/killer_queen_scene_scoring.svg)](https://badge.fury.io/rb/killer_queen_scene_scoring)
[![Coverage status](https://coveralls.io/repos/github/acidhelm/killer_queen_scene_scoring/badge.svg?branch=master)](https://coveralls.io/github/acidhelm/killer_queen_scene_scoring?branch=master)

This is an implementation of the scene-wide scoring system that was introduced
in Bumble Bash 3. The idea is outlined in
[this Facebook post](https://www.facebook.com/events/1788575457853671/permalink/1949400981771117)
in the BB3 group.

# The config file

The config file is a JSON file that contains information about the bracket.
The file is attached to the first match in the bracket.  Challonge apparently
doesn't allow attachments with the `.json` extension, so you must use some
other extension like `.txt` for it to be accepted.

The config file has some parameters, a list of teams, and the players on those
teams.  The parameters are:

```json
{
  "base_point_value": 0,
  "next_bracket": null,
  "max_players_to_count": 3,
  "match_values": [ 1, 1, 1, 2, 2, 3, 3 ],
}
```

`base_point_value`: This is a number that is added to the point values in the
`match_values` array.  It is used in tournaments where some teams do not advance
to the final bracket.  Set this to the number of teams that did not advance.
For example, if your tournament has 20 teams, and 12 play in the final bracket,
set `base_point_value` to 8 (20-12).  
`next_bracket`: Set this to the slug or the Challonge ID of a bracket that
should be processed after the current bracket.  Set it to `null` or omit it in
the config file of the last bracket in the tournament.  If you set this to the
slug of a tournament that is owned by an organization, the string must be of the form
"org_name-bracket_name", for example, "kq-sf-GDC3" (which is owned by the "kq-sf"
organization).  
`max_players_to_count`: The maximum number of players from a scene that can
contribute to that scene's score.  All config files in a tournament must have
the same value for this field.  
`match_values`: An array of integers.  These are the points that are awarded
to the players on a team for reaching each match of the bracket.  For example,
a team that reaches match 4 gets 2 points, since the 4th element in the array
is 2.  The example above is for a
[four-team double-elimination bracket](https://challonge.com/tvtpeasf).
These numbers must currently be calculated by hand.  However, once you calculate
them for a particular type of bracket (e.g., double-elimination with 12 teams),
you can reuse them for all future brackets of that same type.

Note that the last two values in the sample `match_values` are the same.
Those represent the two matches in the grand final.  Those numbers are the
points awarded for _reaching_ a match, not _winning_ a match.  Once a bracket is
complete, the team that won the grand final is awarded one additional point.

The config file also holds a list of teams and their players.  After the
parameters, write a `teams` array that lists the teams, the names of their
players, and the scenes that the players represent.

```json
{
  /* parameters here */
  "teams": [
    {
      "name": "Midwest Madness (CHI/MPLS/KC)",
      "players": [
        {
          "name": "Alice",
          "scene": "Chicago"
        },
        {
          "name": "Bob",
          "scene": "Chicago"
        },
        {
          "name": "Charlie",
          "scene": "Minneapolis"
        },
        {
          "name": "Dani",
          "scene": "Minneapolis"
        },
        {
          "name": "Eve",
          "scene": "Kansas City"
        }
      ]
    },
    /* other teams... */
  ]
}
```

The team name in the config file must match the team's name in the
Challonge bracket, although the case of letters may differ.  This means that
a team must have the same name in all the brackets in a tournament.

# Calculating scores

```ruby
id = "tvtpeasf"  # Replace this with your tournament's slug or ID

t = KillerQueenSceneScoring::Tournament.new(id: id, api_key: your_api_key)

if t.load
  t.calculate_points
  puts t.scene_scores.sort
end
```
