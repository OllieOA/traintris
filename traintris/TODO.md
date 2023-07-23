## Train
- [x] Create train sprites
- [x] Select correct sprite (refactor)
- [x] Create train movement
- [x] Train creates blocks on stop
- [x] Add train speedup control
- [ ] Add check of other segment present on board
## Board
- [x] Select tile sprites
- [x] Generate board at runtime
- [x] Add dynamic barriers to tiles
- [x] Refactor tiles to be programatically settable
- [x] Add mountain source for runways
- [ ] Add in props around the cleared board area (generative?)
- [x] Create debug boards for testing
- [x] Clear board on full line match
- [x] Remove runways when trains stop on one
- [x] Add "switchback" tiles
## UI
- [x] Add levels (seasons) widget
- [x] Add score widget
- [ ] Add high score saving
- [x] Add points remaining for next level
- [ ] Add status for level length
- [ ] Add tutorial
- [ ] Add main menu
- [ ] Add settings
	- [ ] Font setting
	- [ ] Keyboard layout setting
	- [ ] Sound setting
- [ ] Add start level selector
- [ ] Add exclamation points when 1 away from barrier
- [ ] Add powerups to turn trains full vert/full horizontal
- [ ] Add powerup for nuclear option (clear board no points)
## Game
- [x] Increase speed based on level
- [ ] Increase min/max train length with levels
- [ ] Add sound prompt for trains (chuggachugga)
- [ ] Add butler upload pipeline for project
- [ ] Add powerups for score multiplication/addition
- [ ] Refactor all spawning to "falling"
## Juice
- [ ] Add season modifiers (change colour, add particles)
- [ ] Add barrier setup to tunnel/crashed out tunnel
- [ ] Add train "squash" animation
- [ ] Add frog/pond in the bottom corner
- [ ] Make a twist on the Tetris theme
- [ ] Add clearing animation (horizontal swipe or particles)
## Bug
- [x] Fix coal truck wheels
- [ ] Train can roll over blocks (should be fixed by runway handling)
- [x] Train cannot collide with top of board