# To Do

What I **should** have done:

-   Focus entirely on first (or first two) mode(s)

-   Make *everything* a throwable. (Powerups as well.)

-   Make the rest a *feature of the arena itself*. (Such as places around which the knives curve. Things like that are awesome + don't need to be *taught*.)

    -   In general, build arenas from the ground up to support what I need: dead players have something to do, encourage throwing from distance, everything can be sliced (or interacted with in some way)

-   Write cleaner code from the start so all those bug fixes and patches aren't needed

## General To-Dos/Questions

-   **Quite crucial:** add a "counter rotate" button to the default control scheme?

-   **Training Ravines (arena):** Also add "stuckable" stones? (Now all of them are just deflectable.)

-   More throwables: At least something for *close range* (although not sure anymore now that I've discouraged this so much) And something really uniquely Halloween, unique to this game's mechanics.

```{=html}
<!-- -->
```
-   Make collectors look better. Also allow placing them in *any* map layer. (Sometimes they should overlay, sometimes they should be ground.)

-   **Quite crucial:** Sometimes, when knives get stuck in something they still rotate the wrong way around? (It seems their raycast hits the *back* of the object, instead of the *front*. Which suggests the raycast starts *inside* the object because it's too fast?)

-   **Quite crucial:** Similarly, sometimes knives tunnel through some object, deflect loads of times, the never get out of it => I already keep their velocity when overlapping NonSolids, and knives are regularly removed (if not held), so that should compensate a fair bit

-   When possible, permanently show the effects of a powerup (in a unique, clear way, like a "magnet" shape or particle effect for the magnet)

-   **Extra mode:** all players start *really small* (minimum size). You grow *automatically* and you win when you're *maximum size*.

-   **The extra modes (besides the first two) are very much untested ...**

## Better bots

-   More properly test the bots on other modes.

-   Bots can "insta-press" buttons. Add *some* delay between press/release cycles to make it more manageable?

    -   Similarly, smooth out rotations (to prevent flipflopping)

-   Change the *global* weight of things also based on distance? (Mostly applicable to less important things. For example, if the closest powerup is quite far away, don't consider their vector as much.)

-   Niceties:

    -   Give personality.

    -   If no knives, *and* no knives for grabs, flee from others?

    -   Add the general niceties.

## Nudging player behavior

-   Change arenas to modify player behavior:

    -   Tiles in the floor that fall away as players walk over them. (More chance/quicker if there are *more* players.)

    -   Lilypads with the same idea: too many, and the whole thing sinks.

-   Keep score/data over multiple rounds and use it to change player priorities.

    -   Maybe the winner from the last round is marked "Winner!" and therefore painted as a target.

    -   Or the best defensive player is marked "Defensive!" (and players are incentivized to try and break that streak)

    -   The person with the longest throws gets a bonus the next round?­

## Really, really optional

-   Pirate Curse

    -   Add some torches (probably in the stones) for lighting? (Would require particles and animated sprite, otherwise it just doesn't look good.)

-   Family Dinner

    -   Occlusions also on objects themselves (make them their own sprite to ignore that), food uses the "multicolor" coloring ... which doesn't look good at all.

-   Haunted House

    -   Not sure about lighting + the completely empty walls and space

    -   Sound effect on arena change

-   Swimming pool:

    -   Make light distribution nicer (symmetric?) => in general, find ways to make it look slightly better

    -   Explain the "drain" with some extra particles and stuff?

-   Dumplings: give different types a different *trail*?

    -   Isn't it confusing that dumplings have their own color *which has nothing to do with player owner*, while other throwables *have a color that shows owner*?

-   ~~Button for *changing bot teams* (if they ever learn about teams).~~

    -   **Don't see a good solution in current system.** For next game, allow player to *traverse* all logged-in **bots** (with arrow keys/joystick). So we can edit each bot specifically by going to them.

-   **IDEA:** Different *ground terrains*. As long as you're on that terrain, you are influenced by its special effect (whatever it is).

    -   Icy movement, sticky movement, keep growing/shrinking?

    -   Curver => curves any throwables through it. (Might be more intuitive to make it a "magnet" or "hurricane" or something.

-   **IDEA:** A way to really *separate* a map between players, locking them into a certain zone

    -   **AMAZING (but weird) IDEA:** There's an actual *minimap* of the arena available somewhere. Slicing it will *actually* divide the arena into those portions.

    -   **Maybe something for a different game. =>** would be cool though, maybe for a pirate game about slicing the actual map, or a puzzle game.

**Things that are probably already fixed:**

-   Make dumplings *also* deflect knives in the air. (That's the whole reason I gave them a *body*.) => I think they already do this by default! (Their body is never actually reset, which makes all their functionality possible.)

-   On old playtest, there was an issue with owner not being reset on knives standing still. I think it had to do with max capacity, and I fixed that clear bug, but not sure if that solved all issues.

-   On old playtest, some losers (or winners?) didn't get an award handed to them at the end. Is that fixed?

## Playtest Results

-   **Visual clarity:**

    -   ~~**The aim helper** could be brighter + more visible + animated~~

    -   ~~Way thicker outline around players~~

    -   ~~Larger UI windows (for tutorial, game over, etc.)~~

-   ~~Longer reminders + non-immediate-skip protecetion~~

-   ~~Die sooner (while you're still large) + start larger~~

-   ~~Max \# throwables (just remove overflow after a while; think this was already built-in, just not strong enough)~~

-   ~~Enforce strict minimum size, even in modes where you cannot die.~~

-   ~~**Ghost town:** (And maybe two ghost knives 100% of the time is too much?)~~

-   ~~**Jungle:** keep vines removed for longer + completely remove them earlier.~~

-   ~~**BUG:** Add bot/add player buttons reversed?~~

-   ~~Gracefully degrade when no powerup types available. (Just place nothing?)~~

-   ~~**Feedback**: slightly larger, wait longer before fading~~

    -   ~~Make "no throwables" shorter (like "empty!"), or limit how often they can appear~~

-   ~~**BUG:** In ghost town, ghost knives don't *always* seem to go away after a hit~~???

-   ~~Feedback when you've become a ghost, but have not died. (Conversely, when you've died, but don't become a ghost immediately.)~~

-   ~~**BUG: Frightening Feast:** shows leftover parts (permanently), why?? => forgot to set fade_rubble to true in GlobalDict settings~~

-   **~~Starting rules:~~**

    -   ~~Enable "area-shrink" by default~~

    -   ~~Enable "active knife in front" by default~~

    -   ~~No powerups. Only standard knife throwable.~~

-   ~~**Jungle:** shut down teleporters after a while?~~

-   ~~**DOUBT: Remove/rethink** the dumpling throwables???~~

-   ~~**DOUBT:** Is limiting players to a single knife an idea?~~

-   ~~**DOUBT:** Are players moving too fast by default? (Now that they're bigger, and they move faster if close, I think I can tone it down?)~~

## Reddit post

-   ~~Tutorial arena:~~

    -   ~~Players are forced to stay spread out~~

        -   ~~4 different locations, can't visit each other~~

        -   ~~At the start, assign a location to each team.~~

        -   ~~Then place players inside their location (based on team num) => modify the code to allow this as a possibility~~

    -   ~~There are some elements for cover, though they can be sliced through (after which the knife is deleted).~~

    -   ~~You have to throw across a distance to hit others~~

-   ~~Limited fire rate (shown through progressing black border around player)~~

-   ~~When hit, you are *invincible* for a couple of moments. The more close-by the hit was, the *longer* you're invincible.~~

    -   ~~=> more feedback for this (shield icons across body?)~~

-   ~~When hit, you are briefly *stunned*.~~

    -   ~~=> extend to bots as well, as it now only happens in *player* Input module~~

    -   ~~Switch icon to a stunned face~~

    -   ~~Show a starry pattern across the body?~~

-   ~~The closer you are to another (enemy!) player, the faster you move.~~

-   ~~Holding button charges up speed. If knife doesn't have enough throw speed, it will just bump off the other player. => mainly make this speed difference *much more obvious*~~

    -   ~~Also show this powering up on the *aim helper (dotted) line*?~~

-   ~~When really close to someone else, you cannot throw. Instead, pressing the button just does a *repel* on the other. => decided not to do this, as repelling already happens, and it would make throwing inconsistent~~
