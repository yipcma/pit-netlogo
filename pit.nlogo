;; PitGame v2.2 7 Feb 2017
;; world window version 2
;; requires NetLogo 6.0 or higher
;; by Doug Edmunds
;; based on the Pit card game
;; modified and extended by Andrew Yip 23 Oct 2017
;; for components and rules https://tametheboardgame.com/category/published-games/pit/
extensions [sound cf array]

globals [deck  do-trade xcards1 xcards2 winner this-trader-g other-trader-g scores round-counter]

breed [players player]

players-own [cards keepers trade-set offered-cards offered-count won]


to output-help
  output-print "Corn - yellow, Oats - white,"
  output-print "Wheat - blue, Flax - green,"
  output-print "Barley - pink"
  output-print "Dice show last traders"
end

to setup
  ct ; reset turtles
  set deck []
  set xcards1 []
  set xcards2 []
  set this-trader-g "--"
  set other-trader-g "--"
  set winner []
  set do-trade true
  create-players 5 [set cards [] set color red set label who set shape "circle" set xcor 1 set ycor 6 - who]
  repeat 9 [set deck fput "oats" deck]
  repeat 9 [set deck fput "corn" deck]
  repeat 9 [set deck fput "wheat" deck]
  repeat 9 [set deck fput "flax" deck]
  repeat 9 [set deck fput "barley" deck] ; add 5th commodity
  set deck (sentence "bull" "bear" deck) ; add bull bear cards
  ;; if increasing the number of players, add 9 cards of another commodity, like barley

  set deck shuffle deck ; no need for repeat 9 here
  deal
  reset-ticks
end

to deal
  ask players [
    repeat 9 [
      set cards sentence cards first deck
      set deck but-first deck]
    set cards sort cards
    set keepers []
    set trade-set []
    set won false
  ]
  ask n-of 2 players [
    set cards sentence cards first deck
    set deck but-first deck
  ]
  ; deal 1 extra card each to 2 random players
end

to analyze-position
;  output-print ""
  select-keepers
  select-offer
end


to select-keepers
  set do-trade true

  foreach sort players [ [?1] ->
   ask ?1 [
    let most-cards one-of modes cards

;; leave this here for the setup
    let card-pos 1
    let this-xcor  xcor + 2
    let this-ycor  ycor
;    show list this-xcor this-ycor

    foreach cards [ [commodity] ->
      if commodity = "oats"  [ask patch this-xcor this-ycor [set pcolor white]]
      if commodity = "corn"  [ask patch this-xcor this-ycor [set pcolor yellow]]
      if commodity = "wheat" [ask patch this-xcor this-ycor [set pcolor blue]]
      if commodity = "flax"  [ask patch this-xcor this-ycor [set pcolor green]]
      if commodity = "barley" [ask patch this-xcor this-ycor [set pcolor pink]]
      if commodity = "bull" [ask patch this-xcor this-ycor [set pcolor cyan]]
      if commodity = "bear" [ask patch this-xcor this-ycor [set pcolor grey]]
      set this-xcor this-xcor + 1
      ]


    set keepers []
    set trade-set[]
    foreach cards [ [??1] -> ifelse ??1 = most-cards
      [set keepers lput ??1 keepers]
      [set trade-set lput ??1 trade-set] ]
    set trade-set sort remove "bull" trade-set
      ; remove bull from trade-set
;    output-show word "I am cornering " most-cards
;    output-show word "My trade-set is " trade-set
    ]
   ]
;  output-print "end select-keepers" output-print ""
end

to-report occurrences [x the-list]
  report reduce
    [ [occurrence-count next-item] -> ifelse-value (next-item = x) [occurrence-count + 1] [occurrence-count] ] (fput 0 the-list)
end

; TODO: offer bear card first
; TODO: trade out low value cards first at a tie
to select-offer
  foreach sort players [ [?1] ->
      ask ?1 [
      set offered-cards []
      set offered-count 0
      ;output-show word "I am player "  who
      if length trade-set > 0
        ;;create a list with no duplicates to trade away
        ;;pick one
        ;;figure out how many player has of the choice
        ;;offer random quantity up to maximum of that one
        [let no-dupe-list remove-duplicates trade-set
          let trade-pick one-of no-dupe-list
          set offered-count length filter [ [??1] -> ??1 = trade-pick ] trade-set
          ;; reduce to a random amount > 0, less than max
          ;; output-show word "before random: " offered-count
          set offered-count (random offered-count) + 1
;          output-show (word "Player " who " offers " offered-count " (" trade-pick ")" )
          repeat offered-count [set offered-cards lput trade-pick offered-cards]
        ]

      ]
    ]
  ;; if more than one winner, whoever is first to ring the bell wins
  ; add bull corner
  ; add double bull corner
  ; penalize bear or bull losing holders
  ask players [
    if member? "bull" cards and occurrences one-of modes cards cards = 9 [
      output-show (word round-counter ": Double Bull Winner! (" item 2 cards ")")
      sound:play-note "tubular bells" 100 111 2
      set winner lput who winner
      set do-trade false
      score-winner one-of modes cards "double"
      set won true
      stop ]

    ; add bull corner
    if member? "bull" cards and occurrences one-of modes cards cards = 8 [
      output-show (word round-counter ": Bull Winner! (" item 2 cards ")")
      sound:play-note "tubular bells" 100 111 2
      set winner lput who winner
      set do-trade false
      score-winner one-of modes cards ""
      set won true
      stop ]

    if occurrences one-of modes cards cards = 9 [
      output-show (word round-counter ": Winner! (" item 1 cards ")" )
      sound:play-note "tubular bells" 100 111 2
      set winner lput who winner
      set do-trade false
      score-winner one-of modes cards ""
      set won true
      stop ]
  ]
;  output-print "end select-offer" output-print ""
end

to score-winner [commodity mode]
  let price 0
  cf:match commodity
  cf:case [c -> c = "wheat"] [set price 100]
  cf:case [c -> c = "barley"] [set price 85]
  cf:case [c -> c = "corn"] [set price 75]
  cf:case [c -> c = "oats"] [set price 60]
  cf:else [set price 50] ; fictional price
  cf:match mode
  cf:case [m -> m = "double"] [array:set scores who 2 * price + array:item scores who]
  cf:else [array:set scores who price + array:item scores who]
end

to penalize-loser
  ask players with [won = false] [
    if member? "bull" cards [array:set scores who array:item scores who - 20]
    if member? "bear" cards [array:set scores who array:item scores who - 20]
  ]
end

to find-and-make-trade
;  output-print ""
  ask players [
    let my-count offered-count
    ;; do-trade is global, changed to false in make-trade
    if do-trade and any? other players with [offered-count  = my-count]
    [ make-trade my-count]


    let card-pos 1
    let this-xcor  xcor + 2
    let this-ycor  ycor
;    show list this-xcor this-ycor

    foreach cards [ [?1] ->
      if ?1 = "oats"  [ask patch this-xcor this-ycor [set pcolor white]]
      if ?1 = "corn"  [ask patch this-xcor this-ycor [set pcolor yellow]]
      if ?1 = "wheat" [ask patch this-xcor this-ycor [set pcolor blue]]
      if ?1 = "flax"  [ask patch this-xcor this-ycor [set pcolor green]]
      if ?1 = "barley" [ask patch this-xcor this-ycor [set pcolor pink]]
      set this-xcor this-xcor + 1
      ]

  ]

;    output-print "end find-and-make-trade" output-print ""
    tick
end


;; this is done by a player, so output-show cards is that player's cards
to make-trade [my-count]
 ;exchange same number of cards
 ;then set do-trade false
 ;this bogs down if same cards are returned
 ;output-show sentence  who  offered-cards
; output-show offered-cards
 let other-trader nobody
 let this-trader who
 ask one-of other players with [offered-count = my-count]
    [
;      output-show offered-cards
      set other-trader who
      ]
 exchange-cards this-trader other-trader
 set do-trade false
end

;; this is done by the same player from inside make-trade
to exchange-cards [this-trader other-trader]
  ask players [set shape "circle"]
  ask player this-trader [
    set shape "die 1"
    foreach offered-cards [ [?1] ->
    let pull-card-index position ?1 cards
    set cards remove-item pull-card-index cards
    ]]

  ask player other-trader [
    set shape "die 2"
    foreach offered-cards [ [?1] ->
    let pull-card-index position ?1 cards
    set cards remove-item pull-card-index cards
    ]]

    set this-trader-g this-trader
    set other-trader-g other-trader

    set xcards1 ([offered-cards] of player this-trader)
    set xcards2 ([offered-cards] of player other-trader)

    ask player this-trader  [set cards sentence cards xcards2]
    ask player other-trader [set cards sentence cards xcards1]
end

to one-round
  setup
  while [length winner < 1] [
  analyze-position
  find-and-make-trade
  ]
  penalize-loser
  print (word round-counter ":" scores)
  set round-counter round-counter + 1
end

;  write game-loop until score of player > 500
to one-game
  ca
  set scores array:from-list [0 0 0 0 0]
  set round-counter 0
  while [max (array:to-list scores) < 500] [
    one-round
  ]
  print (word "player "  position max (array:to-list scores) array:to-list scores " wins with score " max (array:to-list scores))

end
@#$#@#$#@
GRAPHICS-WINDOW
270
275
500
403
-1
-1
17.11111111111111
1
10
1
1
1
0
1
1
1
0
12
0
6
1
1
1
ticks
30.0

BUTTON
12
10
74
43
Setup
setup\n;;sound:play-note \"tubular bells\" 90 90 2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
10
50
360
95
NIL
sort [cards] of player 0
17
1
11

MONITOR
10
100
360
145
NIL
sort [cards] of player 1
17
1
11

MONITOR
10
150
360
195
NIL
sort [cards] of player 2
17
1
11

BUTTON
86
10
151
43
Analyze
analyze-position
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
135
275
185
320
p2
[offered-count] of player 2
17
1
11

MONITOR
75
275
132
320
p1
[offered-count]\n of player 1
17
1
11

MONITOR
15
275
72
320
p0
[offered-count] of player 0
17
1
11

BUTTON
150
10
210
43
Trade
find-and-make-trade
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
375
150
435
195
NIL
do-trade
17
1
11

MONITOR
375
100
435
145
NIL
Winner
17
1
11

MONITOR
75
335
245
380
NIL
xcards1
17
1
11

MONITOR
75
385
245
430
NIL
xcards2
17
1
11

MONITOR
15
335
72
380
trader A
this-trader-g
17
1
11

MONITOR
15
385
72
430
trader B
other-trader-g
17
1
11

MONITOR
190
275
247
320
p3
[offered-count] of player 3
17
1
11

MONITOR
10
200
360
245
NIL
sort [cards] of player 3
17
1
11

BUTTON
215
10
347
43
Analyze and Trade
analyze-position\nfind-and-make-trade
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
350
10
447
43
One round
one-round
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
540
10
890
420
12

BUTTON
445
10
507
43
Help
output-help
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
5
235
360
280
NIL
sort [cards] of player 4
17
1
11

BUTTON
385
55
477
88
One game
one-game
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
225
275
282
320
p4
[offered-count] of player 4
17
1
11

@#$#@#$#@
## WHAT IS IT?

PitGame is a trading game simulation based on "Pit." Pit is a fast-paced card game for three to seven players, designed to simulate open outcry bidding for commodities. The game was developed for Parker Brothers and first sold in 1904.  

Each player gets 9 cards tries to get all his cards to match, by trading from 1 to 4 to cards with other players (1 for 1, 2 for 2, etc). The cards given away have to be the same (all wheat, all corn).  In the live game everyone plays at once, trading with other players until there is a winner. There are no 'turns' per se. 

The simulation provides a model for competitive concurrent action by agents, and also explores the coding issues involved in maintaining changes to lists.

## HOW IT WORKS

In order to simulate trading all at once, only one trade is allowed per turn, but who gets to trade is randomly selected in each turn. It is possible that player 2 gets to trade several times in a row, while player 1 doesn't get to trade at all.  

In the simulation there are 4 players (0,1,2,3) and 4 commodities (wheat, corn, oats, and flax).  There are 9 cards for each commodity. The players try to 'corner the market' by trading with each other to get all 9 cards of a commodity.  When a player gets all the cards of a commodity, he is the winner. 

## HOW TO USE IT

Make sure the output window appears as a large box on the right hand side. 

Click "Setup" to deal out original 9 cards held by each player.  

The sequence is Analyze-Trade, Analyze-Trade, etc. You can combine these two steps with the "Analyze and Trade" button, or you can click "Play to End" for the simulation to continue until there is a winner.

Click "Analyze" for each player to analyze and report their position.

Click "Trade" to do a trade.  The rule is that n order for there to be a trade, two players must offer each other the same quantity (1,2,3 or 4).  The offer must be of the same commodity (i.e., 3 wheat, not 2 wheat and 1 corn). If more than two players offer the same quantity, then a random selection of two players is made. The traders cannot see the type of commodity that is being offered to them.

Click 'Analyze and Trade' to combine analyze and trade.

Click "Play to end", which repeats until there is a winner.

A bell will ring when there is a winner.

## THINGS TO NOTICE

There are a lot of output boxes so you can see who is trading away what.

Look at the code to see how lists are manipulated to extract trade-sets and how exchanges are made between the players

Each 'round' only allows one trade, between two of the players.  When more than two players offer the same count, they are selected randomly.  

Sometimes the players will get "stuck" for several rounds, offering each other the same things (like 2 wheat for 2 wheat) so there is no change.  That is part of the game, so it should not be avoided.  Eventually, due to the randomization, this deadlock will break, so just click Step again until it does.

## THINGS TO TRY

Does the simulation model the real game?  To see how the card game runs out with real players, print out the rules, get together with 3 friends, and use some ordinary playing cards instead of buying a special deck (use the suits as 'commodities').  Get something to ding on unless you have a bell to ring.

## EXTENDING THE MODEL

The original card game awarded more points depending on the commodities: Wheat 100; Barley 85; Corn 75; Rye 70; Oats 60; Hay 50; Flax 40. The model does not prioritize.

You could better understand the code if you increase the number of players to 5 and add another set of 9 cards to the deck (such as barley, rice, or soybeans).  You should add a monitor for the additional player's holdings and for the additional player's offer-count.

The players are self-focused. Each player makes selections of cards to keep based on which cards he has the most of, and doesn't try to keep track of what the other players may be going for. Also the players randomly decide how many cards to trade. What would you change to make them smarter players?

The card game rules also have a version which uses two wild cards - a Bear and a Bull.  The rules are online (see link below for the pdf).  You could add those cards to the game to enhance it.

The card game also gives more points for trying to corner certain commodities, so there would be an incentive to go for the one that gets more points, especially in the case of a tie between cards in the player's hand.  That aspect is not included in the basic simulation. 

## NETLOGO FEATURES

Look at the code to see how the lists are manipulated to extract trade-sets and how exchanges are made.


## RELATED MODELS

None I am aware of.

## CREDITS AND REFERENCES

The original game is called Pit, and was designed to be played by 3 to 7 people. The rules can be downloaded as a PDF file from http://www.hasbro.com/common/instruct/pit.pdf

More information about the history of the game at http://en.wikipedia.org/wiki/Pit_(game)

NetLogo code developed by Doug Edmunds.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

die 1
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 129 129 42

die 2
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 189 189 42

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>analyze-position
find-and-make-trade
if length winner &gt; 0 [
stop]</go>
    <metric>first winner</metric>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
