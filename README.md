# coffeebot
**The best, if not the only, CoffeeScript Screeps AI**

<img align="right" src="https://github.com/RobbieBarnhoorn/coffeebot/blob/master/res/colony.gif" alt="" width=320 height=320>

## About
[Screeps](https://screeps.com/) is an MMO sandbox game for programmers.

You write an AI which controls a colony 24/7. The game deals with resource acquisition and distribution, trade and war,
exploration and expansion. There is also a significant emphasis on optimisation, because your CPU and memory usage are
restricted.

This is my personal bot which I run on the public server. It is written in a functional style using CoffeeScript and
Lodash. You can track its performance here: https://screeps.com/a/#!/profile/MrFluffy

## Features
#### Well-distributed multi-rooming
CoffeeBot efficiently performs all of its functions in a well-distributed manner across all rooms in its domain:
resource mining and distribution, repairing, upgrading, defending, reserving, etc.

#### Flag-based high-level directives
You can pass high-level directives to CoffeeBot by placing flags in rooms, where the colour of the flag corresponds to
what action should be done in this room. CoffeeBot will continue this action while the flag exists. e.g.: `orange` for
`attack`, `yellow` for `patrol`, `blue` for `reserve`.

#### Abstracted pathfinding
CoffeeBot's pathfinding system abstracts over the discrete rooms in the game so that it can find *actually optimal*
paths over long distances, across multiple rooms, as if the map was continuous. Units won't get lost, stuck, or take
weird routes because the default logic is suboptimal.

#### Expensive result caching
CoffeeBot caches expensive results like paths, cost matrices, and targets in order to reduce CPU utilisation.

#### Military logic
CoffeeBot has 3 different types of military units:
1. **Soldiers:** Beefy melee units which go straight for the enemy, soaking up and dealing lots of damage
2. **Medics:** Healer units which assist other units in combat by restoring their health
3. **Snipers:** Ranged units which dodge around enemies, dealing moderate damage while trying to avoid taking any
themselves

#### Defensive logic
CoffeeBot spawns military units to defend itself when threats appear, and has them patrol when there are no threats.
Units will patrol routes between all the `patrol` flags. CoffeeBot can also activate safe-mode when needed.

#### Smart spawning
CoffeeBot's spawning system has several components:
- **Population control:** Maintain desired populations for all roles
- **Dynamic scaling:** Scale popoulations depending on how many rooms and resources are available. It won't scale
beyond CPU limits
- **Spawn Prioritisation:** Ensures the most important roles are always filled
- **Pre-spawning:** Pre-emptively spawn replacements for existing units when they are close to death

## Roadmap
In order of priority:
1. **Optimal structure placement:** Implement an optimisation algorithm to position structures in rooms. I'm
working on an evolutionary algorithm to solve this
2. **Behaviour Trees:** Re-implement the current ~shitty~ highly-adapted decision architecture using
Behaviour Trees
3. **Auto-expansion:** Choose rooms to claim or reserve based on some heuristics;
start territorial battles when necessary

## Installation
1. [Install npm](https://github.com/npm/cli)
2. [Install CoffeeScript](https://coffeescript.org)
3. `git clone` this repo
4. In the `Makefile` set `PROD_DIR` to the location Screeps expects your scripts to be (To find this,
    click the "Script" tab in game and click "Open local folder")
5. `cd coffeebot`
6. `make run`

## Usage

There are several `make` commands you can use:
- `default`: Build and output to `build/` for inspection
- `show`: Build and print output directly to terminal for inspection
- `run`: Build and upload the script to the Screeps server
- `tools`: Build any tools in `tools/` into `bin/`
- `clean`: Delete `build/` and `bin/`
- `uberclean`: Delete the directory Screeps uses. This halts the bot in-game

## FAQ

#### Can I use CoffeeBot?
Yes, but the game will be more rewarding if you write your own bot. If you do choose to use CoffeeBot 
(modified or not), send me your in-game name so I can get more data on how CoffeeBot is performing.

#### Can I submit pull requests?
Yes. Consider opening an Issue first so we can discuss what you want to do.

#### Can I fork this repo?
Yes. I would appreciate a link to your fork so I can track your work.

#### Why CoffeeScript?
Screeps is powered by Node.js and only accepts JavaScript user code. CoffeeScript transpiles to JavaScript, and is
more suitable for the functional style I'm going for. It's also more *aesthetic*.

#### But have you heard of \<some half-baked transpiler\> for \<my favourite language\>?
Probably not.
