# Devlog: Carving Pumpkins & Dwarfing dumplings

Welcome to the devlog for my game **Carving Pumpkins & Dwarfing Dumplings**. \<TO DO: Link>

I'm going to *try* to keep this one shorter than usual, as this game is basically a spinoff from another game I was making. (It's **Rolling in the Sheepe** \<TO DO: Link>)

In that game, I implemented a system that could *slice any shape (realistically*). So, for example, a player could be a *hexagon*. When I drew a line through that hexagon, it would *split* the shape into two parts. (Which, if you were to glue them together again, would represent the original hexagon.)

It was really cool to figure out *how* to do this. It's "relatively easy", though still quite challenging. (Especially when you get to supporting *any* shape, not just the "nice ones" like circles, rectangles, etc.)

However ... as the game progressed, the mechanic just didn't fit anymore. It was more *fun* to split players non-realistically. (Splitting a hexagon would just yield two smaller hexagons.) It fit better with the mechanics, the gameplay, the feeling of the game.

Determined to not let my code go to waste, I decided to create a quick little game that *did* use it!

As Halloween was coming up, it became a silly party game about slicing ( = carving) pumpkins.

**Remark:** I will *not* explain the algorithm for slicing shapes (in 2D) here. It's quite complex and I discussed my journey of discovery *at length* in the other devlog. This is meant as a devlog discussing only the interesting bits from *this* game.

Spoiler Alert: I did not keep it short, the game become too big, and I've learned I'm not good enough yet for projects of this size. But hey, you can read all about my hard-earned lessons in the coming 10,000 words ...

## The idea

It's simple. You can move and you can throw a knife. If the knife goes through another player, you literally slice them in two. The biggest part remains ( = *you* *are the biggest part*), the smaller parts will be lost and out of your control.

Any player who is too tiny, dies and is out of the game. The last one standing wins.

## Step 1: Sometimes you don't need all the physics

At first, I implemented knives in the "traditional way":

-   I gave them a (narrow, rectangular) body

-   When you threw them, I apply an *impulse*

-   When they hit something, I decide whether I want to *slice* it ( = hitting another player)

-   If not, I simply *bounce off of it* ( = hitting a wall) and let the physics engine do its thing.

This didn't work.

Why not? Because *slicing something* is completely different from *hitting something*. They are, in most cases, complete opposites.

-   To hit something, you need a body with some "area". Slicing something means cutting it *along a thin, zero-width line*.

-   It's really hard to tell the physics engine to "delay" colliding with something. They're not built for that, and for a good reason.

As such, the code would work 50% of the time. But the other times, one of these situations would happen:

-   The *body* hit something. But when I shoot a line from it, the line *missed* that object. So we clearly hit someone ... but still didn't slice them.

-   We sliced someone. But, the *collision* also came through, which means our knife had some random rotation/offset added *before* calculating the slice line. Leading to wildly unpredictable slices.

-   Sometimes, if the knife was going fast, both cases would simply fail and nothing happened.

So let's return to that first remark: **slicing means a zero-width line.** That means ... we don't need the physics body (on knives)!

I removed the body (and its shape). I added some code to handle *velocity* myself. (Simply move according to velocity each frame and dampen it a little.)

Then I added a **raycast** just ahead of the knife. If it hits a player, it shoots a line straight ahead, and slices the player across that line. All bodies that come out of it are saved as "exceptions". These will *not* be picked up by the raycast from now on.

(Otherwise, it just keeps slicing and slicing every frame, because it will *keep hitting the player* until the knife comes out on the other side.)

If it hits something else, I simply *deflect* the knife. There's a basic formula for deflecting a force/velocity you can look up online.

With these simple steps, we have a knife that can both *slice* and *collide* (realistically) ... without actually having a physics body.

I only use the physics engine for shooting that *raycast* into the world. Otherwise, the knives are completely handled by my own code, which isn't more than 40 lines.

## Step 2: Throwing and catching

Each knife has an *area* attached to it. (It's called Area2D in Godot, my game engine. Many others call this a *sensor*.)

If this overlaps with its owner ( = the player that threw the knife), you pick it up again.

Of course, this has one issue: when you throw a knife ... it immediately overlaps and you pick it up again! Which means nothing happens.

As such, just after throwing, I "disable" this area for 0.5 seconds. (This has the added benefit that throwing the knife into the wall, and immediately deflecting, will make it go *through* you instead of nothing happening.)

Then I added some simple code to reposition the knives correctly. (On the edge of the player shape, whatever that shape is.)

It uses the **Shoelace algorithm** to estimate the area of the player. We know that, in a perfect circle, Area = pi \* r\^2. We can reverse that to get an *estimate* on the player radius, which would be r = square root(Area / pi).

The knives are placed this distance away from the player, a bit offset from each other. This way, they stick out nicely, whatever your shape.

At first, I "repositioned" the knives to always be in front of you. (Which is logical, as that's the direction you're facing, and that's from where people usually hold/throw knives :p)

But I soon discovered this had issues and that there was a better idea: just keep the knifes *wherever you caught them.* If you catch your knife with your back ... well, guess you'll have to put some extra effort in aiming it later.

## Step 3: Cleaning up the mess

Realistically slicing everything has one downside: you can end up with loads of ugly, tiny shapes floating around.

That's why there's a minimum area. If a shape falls below this -- again, this is estimated using the Shoelace algorithm -- it's simply deleted immediately.

Similarly, the parts that fly off a player have some damping attached to them, so they don't just endlessly float around. After a few seconds, they will have stopped rotating and moving, and just lie on the arena as a sort of "evidence of what happened".

Another thing that makes it "cleaner" is that I *separate* knives you grab. At the start, I define X "predefined angles". Whenever a new knife arrives, it snaps to one of those angles. (If that number is high enough, say above 20, the difference between the real angle and the snapped one is negligible.) Is the angle already occupied (by another knife)? Try another one, until you find an empty spot.

It makes it *so* much easier to see how many knifes you have and where they are pointing.

Lastly, I've learned from previous games that it's actually not a great idea to have separate menu screens. Many games, when the game is done, will go to a different screen that says something like "Game over! This player won. Press one of these buttons to continue." (This is often an overlay as well.)

I've found this to take players out of the experience. Additionally, you *certainly* don't want to switch to a mouse every time (when the rest of the game plays on keyboard/controller).

Instead, when the game is over, each player simply gets a "bubble" next to their head. The winner gets a crown! The losers get a "title" based on their accomplishments. (You've moved more than anyone else in the game? You are a *Runner!*)

One of the players gets a bubble with the instructions (Restart or Exit), which are completely controlled by keyboard/controller.

This makes the whole experience much faster and more streamlined.

## Step 5: Making a first level

Now we need these things for a first level:

-   The core game loop. (Know when it's game over, do something then.)

-   An arena in which to play. (Some obstacles, a background, etc.)

-   Some powerups would be nice. Something basic like "you get an extra knife".

### Core game loop

First step is easy. Whenever a player becomes too small, I send a "player_died" signal to the state manager. It checks how many players are still alive. If only 1, we go to "game_over".

In that state, all those *bubbles* appear next to the players. Additionally, I turn off anything I don't need (like, we don't need to check for "game over" again *if it's already game over*), and turn *on* the keys for navigating.

### Arenas

From a previous game that has some similarities to this one (*Totems of Tag*), I've learned that it's best to manually create the whole arenas.

(Instead of, for example, creating a bunch of tiles and reusing them everywhere.)

It easily allows each arena to be completely unique (with visuals and mechanics not used anywhere else), without requiring me to spend time "abstracting" or "generalizing" all objects and tiles in the game.

As such, the first arena will be the *graveyard*. I'll just draw a background, some decoration, and of course the tombstones. Then I import these to Godot, give them the necessary physics bodies/scripts/groups

**Remark:** *Groups?* In Godot, you can put everything into groups. It's *really* useful. Now I have three groups: Sliceables, Deflectables and Stuckables. These aren't actual words, I've simply always named groups like this. Why? Because it immediately tells you what the group *does*: the first type can be sliced, the second deflects knives, and the third makes knives get stuck inside them.

### Powerups

For the powerups, I invented something nice, I think. Instead of doing it the normal way (powerups spawn, if you like what you see, grab it) ... what if powerups came inside a package? And you need to open that package to see what it is?

And to open packages ... you need to slice them, obviously.

I like this for two reasons:

-   Picking up powerups is still easy: walk onto them

-   But there's a gamble: do you think the powerup is good, or are you going to check by throwing a knife against it?

There's one issue, though. If you *don't* check the powerup first ... you don't know what you're getting. So there must be some *very clear feedback* about what you just grabbed.

At first, I wanted to give each player their own "interface" in the corner and show your powerups there (as usual).

However, again, I've learned this isn't ideal.

-   It takes up a lot of space.

-   It limits me to 4 players maximum.

-   Players need to constantly switch between *looking at themselves* (and what's happening around them) and *looking at some corner of the screen that happens to hold their interface*.

As such, I will simply create *clear* *icons* for each powerup. These appear above your head for 1 or 2 seconds, then disappear.

Additionally, I'll try to give each powerup a *permanent* reminder. Easy example: if you're a ghost (and cannot be hit by knives), you become 50% transparent.

All of this together, makes the game "UI-less". Which is amazing, if it works.

## Step 6: Top-down perspective

At this point, I realized I never made a game with a top-down perspective before. (Well, except for some abstract puzzle games, but then it's not really a perspective but just "geometric shapes in a grid for clarity").

This led to mistakes. I drew (and programmed) some things, by force of habit, to appear *above* the player or to look good *when viewed from a certain angle*.

But in top-down view, you lose all that perspective. There is no "above" or "below" someone to show information. (The only "above"/"below" is in terms of *depth*. For example: players will be rendered *in front of* the ground.)

I tried some things, but nothing really satisfied me. It either didn't look good enough *or* wasn't clear enough during gameplay.

In the end, I settled on this:

-   A "distorted top-down perspective". Which means most things have no perspective, but the bigger elements near the edges *do* have some depth to them. It's like watching down a hole, where things get flatter and flatter as you come near the center.

-   Powerups are displayed *literally on top of the player*. The icon appears, does a bounce, then fades away. It's not ideal, but it's good enough.

-   Knifes are drawn with a sort of side view, that still looks good from top-down perspective. (Because, if you draw a knife top-down "realistically", you'll barely be able to see it, as the blade is too thin.)

-   Most (important) things have a thick *outline* to make them stand out more.

As I make this game, I'm learning more and more about how to deal with this perspective. It's a work in progress :p

**Remark:** by now, I also removed the "Area" from the knives. Looking at the code again, I realized I could do *everything* with that single raycast I was shooting. So this simplified the code and made it a bit faster. (Just in case there are ever going to be *loads of knives* on screen simultaneously.) Additionally, my engine was complaining that it can't re-parent physics objects during the physics calculations. And when a game engine complains, you better listen, or you'll run into hidden and annoying bugs soon.

In a similar vein, I modified the *raycast length* to look *further ahead* if the knife moves faster. Otherwise, if the knife goes *really fast*, it might miss a collision and "tunnel" through something.

## Step 7: Some interesting details (maybe)

In case you were wondering, this is how I implemented the more unique powerups.

**Grow/Shrink:** When setting the shape for a body, I already reposition all points so they are around (0,0) (locally). This ensures the shape is around the "center of mass", which is how it should be.

This means that, to grow/shrink a shape, I only need to **loop through all the points** and **multiply each by a number**. Number greater than 1? The shape grows. Smaller than 1? It shrinks.

**Morph:** I thought about *actually* morphing from one shape to the next. Then I realized that was too difficult for such a simple game.

(After some research, I got the general gist of it: convert both shapes into a *signed distance field*, which is just a grid that tells you the distance to the closest edge from each cell. Then take a weighted average between the two fields, depending on how far you want to morph. But by this point I was like: nah, not worth it.)

So I just drew a bunch of basic shapes in the editor. (I used an image as reference and just placed points on top of it.) These are loaded when the game starts. When you morph, it picks a random shape from the list, resizes it to keep your "current size", and then swaps the shapes.

**Reversed controls:** at the start of each frame, I collect player input into a vector. When controls are reversed, that vector is simply multiplied by -1 before sent to anything else.

**Curved shots:** there's a simple formula for calculating *curve* on a spinning object. You simply calculate something called the **Magnus force** and apply it each frame to the velocity.

This force is defined in 3D, so to make it work in 2D (easily), you just need to fake it. Pretend there's a Z-axis, calculate it, then throw it away again.

**Boomerang:** boomerangs are easy to implement if you follow a simplified model. The boomerang has two states: "flying" and "returning".

When you throw it, it's **flying**. It will just do its thing as always.

As soon as it hits *something*, it switches to **returning.** It calculates the vector towards its owner ( = the player that threw it) and uses *that* as the new direction. I call this the *target velocity*.

Of course, this is a bit *too* precise. (It just goes back in a straight line, probably just the reverse line it just traveled.) To make it curve, you simply *interpolate* between its current velocity and the target velocity. To make it even nicer, do a *spherical interpolate*. (Because we're talking about vectors and rotating here.)

**Ice/Skating movement:** The idea is the same as the boomerang curving. The player input is the "target velocity".

Normally, the velocity immediately updates to the target.

When "walking on ice", it interpolates, so that each input update is a bit "delayed" and you keep continuing in your original direction.

**A philosophical remark:** It's interesting. Many of the things I use in this project I take for granted. Within a *two days* I had everything up until this point, and it still felt like I could've gone faster.

But ... then I realized that 80% of the things I'm doing were *impossible* to me before the start of this year. Large parts of the code in this project are directly copied from other games I made earlier this year. There are things I use *a lot* here (e.g. directly checking the world for a collision *without* requiring an actual body) which I didn't even know were possible 6 months ago.

It's cool to see that progression. It also makes me wonder what stupid things I'm doing now which will, in 6 months, make me go "I wasted 3 hours on *that*?! That should be a 5 minute thing!"

It's even funnier when you copy old code and immediately spot a *huge* mistake you made there. Which explains that odd bug that sometimes appeared in that specific game :p In a sense, my games literally only get *better* with age.

## Step 8: Teams & AI - The forgotten features

In that similar previous game of mine (*Totems of Tag*), there were some features for which I didn't have time.

The most important ones were:

-   Teaming up

-   Computer enemies

(Both of these basically enable the game to be played with much more different *player counts* and *player types*. Totems of Tag has no single player mode. This game should.)

The first one is relatively easy to fix. In the menu, players should be able to press a button to switch teams. In the game, you cannot hit your teammates (or you can turn "friendly fire" on in the settings somewhere), and you win if only players from the same team are left standing.

Here\'s a mockup I made for the "game configuration" screen. (The final one will probably look slightly different, as I figure things out along the way.)

TO DO => IMAGE => Game Config Mockup

In *Totems of Tag*, I added the configuration as different "screens". First you had input. Then you got a grid with *all* ball types in the game, and you could select which ones you wanted. Then a grid with *all* powerups. After 4 of those screens, you could start the game.

It had two advantages: it looked good *and* encouraged players to check out all the content in the game (and try different things).

But it had a huge disadvantage: you had to go through all screens. It took some time. It was annoying, especially on your first play.

As such, this game will only have that single screen from the image.

-   Players can be added (or removed)

-   It shows an overview of the *current* active settings for the game.

-   And you can immediately start (or quit).

If you want to change or see those settings, you can press the indicated button. Only *then* do I switch to the old system of "individual full-size screens where you can pick the things you want".

### How to make bots?

The second feature is, obviously, much harder. How do you make competitive AI bots? Ones that can provide a challenge (no matter the arena or situation), without being predictable?

These are things I've learned from another project I'm working on (which has many "AI"-like elements):

-   There are actions that are "always sensible". If you just let the computer do those randomly, quite often, it works surprisingly well. For example: throwing a knife towards the center of the screen is usually worth *something*.

-   It's better to give the AI **personality**. Instead of one AI with fixed parameters/decisions for everything, give them some leeway. Make one prefer hiding, another more aggressive, another powerup-hungry. Things like these can be *random numbers* or controlled by *probabilities*.

-   That idea of "picking a target" and "slowly going to it" is usually what you need. In this case, it's no different. The computer should just *pick a player to target (sensibly), position themselves for a throw, then throw*.

Of course, that last part takes time to figure out. Because throwing directly at players all the time is certainly not the best move.

-   Instead of throwing directly at players, computers should *predict* where they will go.

-   If an obstacle stands in the way, there's no use in throwing, so they should just chase the player.

-   The computer should be able to see if the *other* player can hit *them*. If so, prefer walking to a safe location.

Generally, the AI script should

-   Read the situation around them. (Collect as much meaningful info as possible, such as the closest player, average distance to all players, etc.)

-   Which gives each possible input a certain "score". (If there's nobody in sight, the score for "throwing a knife" should be lower than for "move towards the action".

-   This score depends on the personality of that AI, which is a (somewhat) random set of number and probabilities.

-   And finally pick the option with the best score.

I'll figure out the details over the coming few days, so let's continue with something else for now.

## Step 9: Other game modes

So far, I've worked on the default game mode: deathmatch. You die if you've become too small. Last player standing wins.

Pretty basic stuff. Which is also why I wanted to add *more* game modes.

When playing, I noticed that the "leftover parts" (from a sliced player) were a bit annoying after a while. They clogged up the field.

I wrote a script to make them "fade out" after some time. But that felt like a wasted opportunity! Instead, what if we had a game mode where you had to *collect* parts from other players?

That was the first spark, which led to these game mode ideas:

-   **Deathmatch**

-   **Collector** => eat slices from other players by moving over them. The first to X slices wins.

-   **Bullseye** => targets appear across the map, hit them to score points. The first to X points wins.

-   **Dumplings** => players can eat dumplings to grow themselves. These dumplings, then, appear *inside* your body. When somebody slices through them, they take away your dumplings. First to X dumplings wins.

-   **Dwarfing Dumplings** => each player/team gets *one huge dumpling* to protect. If it becomes too small, you are out.

-   **Ropes** => each player has gems attached to them with a rope. (Maybe not gems. Just something valuable, Halloween-themed.) Obviously, slicing the rope cuts those items loose. Lose all your gems and you're out.

-   **Capture the Flag** => one player from each team has a *flag* inside of them. However, this is hidden information. (The player who has the flag cannot throw knives, that's how they know.) If you slice through that player, you capture the flag. The first to X captures wins.

    -   This would require *teams*. I see no way to adapt it to single player or individual players.

I'm not sure if I'll be able to make all of them in time. The further we get on the list, the harder they become. But the first ones should be doable.

Especially since they share a common core: collect things, win by collecting more than a threshold.

This did leave me with one issue though: **where do I show how many things you collected?**

Players can be any size or shape. I already show your *powerup* and *orientation* on top of you, so there's really no space for a big number there. I still didn't want to add *interfaces*. So what to do?

Then I remembered a trick I used in an earlier game: **making the interface part of the level.**

What if each player had a "home base" (just an image of a small castle, or something) that was simply **part of the level**? Then I'd have a logical, easily visible location to show how many a player has collected.

In fact, this can add to the challenge. Instead of increasing your counter *immediately*, you first need to successfully bring you items *to your home base*.

In the end, the first few modes were indeed relatively easy, as they share a common core: be the first to collect X of the same thing. That's easy to generalize, even if the thing (and how you collect it) is wildly different.

The later modes proved much harder. And as I didn't have much time, I decided to focus on some core gameplay elements first. (And only make the extra modes if time permits.)

## Step 10: Finishing the basics, adding the content

I've been testing the game a lot, obviously, and tweaked many things. Here's an incomplete list:

-   Increased physics FPS + fixed a stupid bug in my code to get rid of *all* tunneling issues.

-   Added many improvements to things that weren't bugs, but still didn't suit the gameplay. (For example, if you only slice someone "halfway", it does nothing. Because you didn't *fully* go through them. It's realistic ... but not so much fun, and not what players expect. So I extend those halfway slices to go through something completely, in most cases.)

-   You can only pick up powerups *after* you sliced them ( = "unpacked them"). I also made them way more visible, with a thick outline, a flickering animation, a bigger size, etcetera. It was just better, as it prevented "accidentally triggering powerups" and made the screen less chaotic.

-   Added clear indications *who* owned a knife. (Its outline is the color of the owning player. If it's free for all, it has a rainbow outline.)

-   Added many effects and animations to slicing. This makes it more impactful, but also more clear. (Until now, it could happen that you sliced someone ... and the body parts stayed together quite well, so you didn't even know exactly *how* you sliced the other.)

-   Added *probabilities* to powerups, because some are *way* more vital than others. (The "extra knife" powerup is huge, as you only start with a single knife, which you can even lose. Something like "move slower" is much less important, in that sense.)

I'm still unsure about the moving and aiming inputs. It feels like a different control scheme might be easier. This was the main contender: **Use left/right arrows to *rotate left/right*. Use up/down to move *forward/backward*.**

Another idea was: **shoot automatically on timed intervals (e.g. every 5 seconds).** This means players aren't required to press/hold the button, making the game more accessible and easy to control ... but also limiting my options.

As always: I don't know until I test it.

What do I think? **Yes, I think this should be the default.** It's not that it's *obviously better*.

But here's why I chose this new control scheme:

-   It's a game about aiming. If you can only rotate *by also moving in that direction*, it actually makes aiming quite annoying.

-   (Usually, this is solved by adding a second button or a mouse. For example, shooters usually allow you to move with *left joystick* and aim with *right joystick*, independently. However, as this is a local multiplayer game for 1-8 players that also supports keyboard ... I can't do that.)

-   It's a top-down game where rotation is vital. Moving in four directions only makes sense (and is probably always the best option) when rotation does not matter.

The downsides of the new scheme are:

-   Can't control when you throw your knife. (Although we can modify this with, for example, powerups that increase the speed of throwing.)

-   It might take some players an extra step to understand it. ("Always move in the direction of the key you press" is more intuitive at first glance.)

As such, the old control scheme will be fully supported and is something you can turn on in the settings.

With that done, all the basics and essential mechanics/systems/rules are in the game. Now it's time to add the content: arenas, special elements/items/locations, and of course loads of polishing with sound effects and particles.

## Step 11: Arenas

Earlier you already saw the first few attempts at an arena (the "graveyard").

These taught me that I need to make them *bigger* and leave *enough room for players of any size*. They also taught me that playing with lighting and weirdly-shaped physics objects is cool.

Lastly, as this is a game about *slicing* things (realistically, any way you want), I feel like that should be prominent feature in any arena.

First ideas were: an arena which is almost completely filled and you need to *slice* your way through it. (Like an overgrown jungle where you need to cut all these vines to get a path for yourself.)

An arena with big blocks that can be sliced sometimes, but deflect knives at other times. (This way, the possible deflections in the level constantly change.)

Things like this. All with a bit of a Halloween theme, although it's not too strong, as I don't like games having time-limited appeal.

This is the final version of the graveyard. It has some more decorations (such as the gates), which is mostly to reinforce the perspective and add more depth. (Otherwise it just looked too "flat" and "basic"). If I had more time, I'd add way more tiny decorations, such as bits of grass, imperfections on the tombstones, flowers around them, etcetera.

(As always, we're doing a "one week game" here, which means I need to strip any fancy stuff that is "non-essential". If the game turns out good, or I feel motivated, I can *always* improve it later. Conversely, if I spend all my time now on drawing one beautiful arena, the game might never even see the light of day.)

IMAGE of final graveyard image

I decided it might be better to start with a "simpler" map that was a bit more intuitive, so I created "the spooky forest".

IMAGE of final spooky forest.

This screenshot made me realize the light was too dark and players probably need their own (weak) circle of light anyways. Some of the trees are also interactive -- some can be chopped down (creating more space), others auto-throw knives once in a while.

I also made knives more visible with unique colors *and* a "flickering" effect when they are standing still (indicating they can be picked up by *someone*).

Then I wanted a map where *almost the full map* consisted of sliceable objects. This is how the "dark jungle" was born.

## Step 12: Controls, now Properly

I was able to do a quick playtest. (Very quick, just 10 minutes with a random family member.)

The problems were ... stupid and obvious, in hindsight.

-   **Too few knives**. (If you've thrown a knife ... you also can't open powerups. So there's no way to get another knife, unless someone gifts it to you.)

    -   **Solution?** Start with more knives. Regularly, spring open a powerup (automatically) and set it to "extra knife" type.

    -   **What makes it worse?** The "quick slash" action is a bit overpowered, as you don't lose the knife after doing it. This, combined with knives being a rare commodity, causes people to only use this! => There's now a 5 second cooldown on it, and you don't need to hold the button very long to make it a throw.

-   **Controls.** The idea of "rotate left/right" (instead of move in four directions) was added to make *precise aiming* possible on keyboard. On controller, it's obviously not necessary, as you can aim anywhere with joystick. *Additionally* ... there's no need to turn this on during movement. I can just switch to those controls *during aiming*.

Otherwise, things worked as expected, the menus worked (and looked really nice), and it's starting to become a game!

Some other minor tweaks were:

-   The fact that you lose ownership of your knife when it gets stuck is now an *optional rule* you can turn off if you want.

-   When you're smaller, you move slower. (So that the "relative speed" stays the same. Otherwise, it would feel like you were *racing* over the field if you were small. Which felt weird and "off", but also gave you a significant benefit, as you were much harder to hit.

-   By default, players start with random shapes. (I have a list of 20 basic shapes, like rectangle, circle, triangle, hexagon, etc.) Again, there's an option *"everyone starts as a pumpkin"* you can turn on.

-   Decided to add all "special objects" as powerups, to keep the game streamlined. It also prevents me from having to *explain* each special object with an in-game tutorial, as powerups are explained in the settings menu when you hover over them/turn them on.

    -   Example: dumplings are powerups now.

-   Also added some other really useful powerups to enable by default. Such as "repel knives": repel any hostile knives near you, which is basically a shield but more fun/dynamic.

## Step 13: Bots

Earlier I gave a general idea of how bots should work.

After thinking about it for quite a while, I realized I needed to stop thinking about it. **I needed to draw a diagram.**

Unfortunately ... I lost that diagram. I know, I'm an idiot, in the future I've learned to insert images/GIFs *immediately into the devlog* as I see the need, instead of wait until the game releases.

It can be summarized as:

-   Immediate threat? Drop everything and avoid it.

-   Can't do anything because we're out of resources? Find a resource (most likely a knife.)

-   Something useful nearby for the long-term goal? Grab it.

-   Still here? We have time and space to attack!

By changing the weights and probabilities, I can make bots more "defensive" (prioritizing the first few parts) or "aggressive" (prioritizing attack, even if the other conditions aren't met).

Avoiding obstacles uses a basic dynamic physics check:

-   Shoot a few raycasts ahead of us

-   If any of them hit, we can't move there. So try the same movement, but rotated to the left and right.

-   Continue rotating further and further, until we have safe passage.

-   If we had to rotate a lot, the bot goes into "stuck" mode and *tries to get away from all obstacles* for the next 0.5-1 seconds. (It doesn't do anything else.)

    -   If we don't do this, it will keep rotating endlessly, without ever moving out of that space. This fix isn't ideal, but it solves 95% of the cases.

This works quite well, better than expected! Bots are quite a challenge already and mostly feel like you're playing a smart human being.

But as I said, it's not *perfect*. Bots always have this issue: there are situations in which a *human player* would easily see what to do, but a bot just gets lost and does something idiotic.

Bots can still get stuck and will just stand there helplessly, especially if they're shooting for a target that's *just* on the other side of a wall.

To solve this, we could use actual *pathfinding*. Godot has "NavigationMesh" built-in, which I've never used before, but looked like the perfect fit.

To use it, I

-   Draw one big mesh for the whole map

-   Cut out all static bodies. (So they are "holes" in the NavigationMesh.)

-   Tell the bot to find a path between its current position and its target, staying inside this NavigationMesh.

-   Then just walk that path.

This *also* was surprisingly easy. With one big caveat: bodies that overlapped the edge of the screen would cause trouble. (It cannot create a proper navigation mesh if some of it extends beyond the bounds.)

Solution? Modify the points of that shape to stay within the screen.

The problem with that? Whenever a bot wanted to go near the edge, it would find a path *along the border of the screen*, as there was 0.0001 free space there due to floating point precision errors. Which led to paths that didn't actually exist.

To solve it, I

-   Check if a path does something like this. (One of the points is an edge point.)

-   If so, set the target *halfway* the real target. Check if the path is still wrong.

-   Continue until the path is valid.

-   Because bots re-check targets each frame, it doesn't matter if we get only halfway. Because, when we're there, it would just calculate the next half from there.

I thought this worked great, but ...

The day after, I discovered this was just a "happy accident" and there were actually many more issues with the code.

It would fail to generate a navigation mesh for like 80% of the situations. Sometimes I could trigger this crash by just moving a single body *one pixel* to the right.

I searched, and tried, and recoded for *hours*. Eventually, the crashes were the result of *several mistakes* coming together, instead of being caused by a single error.

-   Overlapping bodies aren't possible in navigation meshes. So adding a body that overlapped with one already added, would just crash it.

-   My code for moving points inside the bounds was flawed. It simply *forced* a point to the nearest edge, but this could lead to multiple points (in the same shape) being forced to an identical spot, causing illegal polygons.

-   The navigation mesh does not take the size of the player body into account: it just generates a path of zero-width lines through the allowed area. So I had to grow all shapes myself (by a reasonable amount) to make it actually work.

In the end, I learned that Godot (my game engine) has this **amazing** Geometry class built-in. It allowed me to *merge* any overlapping polygons into one, and *clip* any parts of polygons that exceeded the screen area, and *inflate/deflate* shapes as needed. All with three lines of code. And it runs fast, on any arena I've tested so far.

If I'd known this before, coding the main mechanic ("slicing stuff realistically") would also have been *much* easier :p But hey, now I know, and I already see cool game ideas in my future.

With that done, bots are at least really good at navigating the map and aiming. Being fun to play against will have to be something I finetune.

## Step 14: Bringing it all together

At this point, it was just about adding more content, fixing the flaws, and polishing the gameplay.

I must admit this is *very hard* for me to do. For three reasons:

-   These are local multiplayer games, so I really need other people to test it. And other people are busy or might not feel like doing so.

-   This is the "moment of truth". Here we see if the game is *actually* as fun as I'd hoped, and if things really work and click with people.

-   I'm more of an inventor than a creator. I come up with unique ideas all the time, am motivated to try them, and (over the years) trained myself to actually *be able to make basically anything I come up with*. But when the idea has been tested -- the prototype built, the algorithm invented, its feasibility determined -- my head is like: "what's next? What's something you haven't done before? Do that now!" I really need to stay disciplined to finish my projects and polish them.

To overcome this, I usually list *all the things I need to do*, with as much specificity/detail as possible. This way, they are "5 minute tasks", which I can cross off and "power through". I shut down any inner critic and just work my way through.

### The list

These were the main things to do:

-   Sound effects (and soundtrack) -- already had some melodies written though

-   Particles and animations (mostly related to *feedback* about what you're doing)

-   Making at least 3 playable arenas and modes

-   Figuring out what to do with "throwables" => I'm not sure if I should actually make a category of different things to throw, or just shove some of it under "powerups" and ignore the rest.

For each, I'd written a list (almost a full A4 per category) of the *exact things I need*. Like: (sound effects) slash, walk, menu click, menu scroll, grab knife, die, game start, ...

And then I muster as much motivation as I can and do it!

The soundtrack turned out better than expected! I simply combined many "Halloween" sounds with a simple, catchy melody I came up with over dinner. (Remember, this is a One Week Game, the timespan between "I need an idea => I need to implement it" is usually less than an hour.)

After many games, sound effects and particles are also starting to be come less of a hassle. (I copied two sound effects from an older game, namely those for the *UI Buttons*, as I saw no need to change that or do something unique here.)

After some more testing (and more ideas implemented), I realized I needed an *even simpler* starting arena. That's how Ghost Town was born:

TO DO => IMAGE HERE => Ghost Town

It's a mostly open arena, with the ruins of an old town. The openness was necessary to allow good movement and knife throwing lines, making it a good start to the game.

Nevertheless, it still has enough structures to hide behind. Each wall (without exception) gets your knife *stuck*. This means there are no deflections, and you always need to run after the knife you just threw, making it an even better starting arena.

This structure of (half)walls leads to some cool shadows (from the lanterns attached to the wall.)

But, as always, there's a catch: every X seconds, the arena switches from day to night (or vice versa). At night, obviously, some players turn into ghosts and a big *ghost knife* appears. It can go through walls and follows the nearest player like a homing missile.

### Answering the last question

When I wanted to implement that ghost knife, however ... I realized there was no good way to do it. The current code for knives was *completely specific* to how knives worked (and mostly resided in a single script) and written at the very start of the game.

If I wanted to implement different knife types, I'd have to rework the whole thing into smaller, cleaner, more manageable modules. Well ... if I have to do that anyway, I might as well add support for any type of "throwable" and thereby answer my last question.

Yes, the game will have a separate category of throwables, which will include things like a *boomerang knife* or *Thor's hammer* (if you press *throw*, all hammers you've thrown will fly back into your hand). It was just the best option, especially if I ever decide to improve the game after my Halloween deadline.

(One thing that always helps me answer the question "do I need to subdivide this into smaller categories?" is looking at the UI. When navigating the settings, the *powerups* screen is currently (by far) the fullest.\
\
It's so full that I can't add more than 5 powerups without breaking the code, because it cannot position all sprites nicely on screen. Hence, it seems that splitting *powerups* and *throwables* is the better idea, as it will lead to *two* separate, clean screens.)

One day was spent on the first three points and rewriting the "throwable" code.

The next day was spent *actually (fully) implementing* throwables and fixing many issues with the current arenas and feedback.

And then, finally, on the last day I could add more content at a more leisurely pace: some new arenas, some modes that finally work, some extra throwables.

## Step 15: Playtest

I was able to playtest the game (more thoroughly than the last time) with 5 players. (4 on controller, 1 on keyboard)

My play group is a bunch of inexperienced gamers (with, sometimes, someone who plays games regularly thrown in). Which is both a blessing and a curse.

The curse is that they don't really have that "gaming mentality" and will not be interested in anything more than the bare basics of the game.

The blessing is that it *immediately* pinpoints *any* part of the game that's not simple/intuitive/clear/fun enough.

The major takeaway from the playtest was:

-   People don't use the system of "quick slash vs long throw" properly. They just keep mashing buttons in the hopes of hitting someone, running into them over and over ... and it rarely works.

-   Arenas (and modes) are only explained once you get to the *settings* screen and want to change it. This means there is *no* explanation at all on your first playthrough, which is *exactly* the moment you need it!

-   Players kept being annoying by *hoarding knives* yet *never releasing them*.

-   Dead players had nothing to do.

-   Quite a few game-breaking, significant bugs.

After asking the players, looking at the footage (I always record these sessions), talking about it, I decided on these solutions:

-   **Quick slashing is gone**. It only clogs up the game. The idea is nice, the reality is that it doesn't fit. Any button press will *throw* your knife. (This also allows me to remove some of the indicators and powerups for quick slashing, tightening the game further.)

-   **Players cannot move through each other**. In fact, you are even *repelled/bounced back* if you come too close.

    -   This removes a lot of the "messiness" from people running through each other.

    -   It does mean players need to be a bit *smaller*, otherwise it doesn't fit.

    -   You *can* go through players of the same team, as I don't see why not, and it would help a lot with spacing.

-   The first arena should **be even simpler** (so it needs *no* explanation). No special rules or funny stuff, nothing that could trip you up.

-   There should be a "quick text explanation" for your current mode **every time**. (For the first mode: "Throw knives at others to slice them. Too small? You're dead." It just pops up for two seconds, then fades away, then the game properly starts.)

-   More **feedback.** (Wanted to do this anyway, but its importance was highlighted here.)

-   **Lower limit** on holding stuff. If you're at maximum, or haven't thrown in a while, the system **automatically throws** a knife for you.

-   I don't see a clear thing that **dead players** could do *in any mode/arena*. Instead, I'll do specific things per arena. (For example: Ghost Town? Dead players can *control* the ghost knives. Graveyard? You become a tombstone that can still throw any knives it receives.)

Besides that, there were *tons* of situations which resulted in the game being unplayable for some (or everyone). This is normal, as playtesting is a real "stress test" for a game, it's just annoying that it happens every time :p

For example, some players would randomly *blow up* (become 100x larger), until they were so big they disappeared from the game entirely.

Bugs like that are quite invisible, yet *must* be fixed 100%.

Only near the end, someone said "it's when I grabbed one of those" and pointed at a specific powerup. And wouldn't you guess it: it was one of the first powerups I implemented, but the underlying systems had changed, so it was buggy as hell.

So yeah, a lot of work ahead of me to fix these things. But players actually had loads of fun, the game was very easy to get into and play, and they specifically complemented the visuals/slicing/lighting effects. And seeing them play the game and their process of understanding it makes me very certain these changes *are more than worth it*.

**Remark:** also, I completely forgot to explain in-game that powerups need to be *sliced* to open them. And I also forgot to tell you about it in this section. This means, to me, that the mechanic must certainly be explained *clearly and obviously* somewhere. Or that it's not intuitive enough and should be removed.

After some thinking, I decided to *implicitly teach it* by forcing players to experience it in the first arena. This is the idea: powerups are placed at locations where players will accidentally slice them. (They do not "auto slice" themselves.) For example, just behind a *shrub* or *vine* that is sliceable.

After repeating this a few times, players should (hopefully) understand what's happening.

## Conclusion

This devlog became way longer than I thought (or hoped).

Surprisingly, that doesn't actually mean the *development* of the game took longer. I worked *really* hard and actually managed to get it all done in time for Halloween.

It's just that I solve most of my issues by writing about them, which means I usually do this:

-   Spent an hour writing the devlog

-   Discover what I need to do

-   Do that in 30 minutes

Instead of this:

-   Try to figure out what I need to do

-   And finally succeed after 2 hours

It's what works for me.

Anyway, the game turned out great! I think it looks good (especially the menus and everything *around* the content got some love this time), it's really easy to teach and play, yet offers many possibilities and interesting situations.

It's also another step up from previous games. They did not have:

-   Teaming up

-   Bots

-   As much content/variety as this one

-   A streamlined and good-looking interface. (They had parts of it, but there were always big areas of improvement to be seen.)

-   Dynamic slicing of player shapes :)

Because of this game, I learned how to do all those things above. I also learned more methods of dealing with shapes, how my game engine (Godot) has built-in functions that really simplify that, and improved some of my older code.

(For example, earlier projects didn't have the possibility of *leaving* after you've added a player. You'd have to restart the whole game if you accidentally plugged in a controller too many or somebody had left. Now there's proper support for that.)

This means I can build future projects on that codebase and the next game(s) will become even better!

If I had more time, I would certainly:

-   Go back to the drawing board to rethink some of the core mechanics of the game. Because, well, it only has *one* (realistic slicing) and I don't even use it that much. I'm sure I can become more creative with it and use it for more.

-   In hindsight, perhaps I should have done away with powerups entirely. Instead, *throwables* should be the powerups. (Holding something = you get the effect.) This would greatly simplify the game and lead to unique mechanics.

-   Add more arenas and modes ( + really streamline/polish them)

-   Improve some of the surrounding elements, such as marketing (trailer), and playtest the game *much more* to improve it.

But besides that ... I think the game is surprisingly complete in all ways. A good sign of things to come.

Until the next devlog,

Pandaqi

(The devlog doesn't actually end here, as this was just version 1 and I did a big update *after* Halloween for the paid version. But you can stop here if you want.)

## Post Release: More fixes & lessons

I raced through development to release the game (well) before Halloween.

Of course, once released, I took a break for a few days, then dove back in to fix all sorts of obvious issues.

The biggest one had to do with core mechanics: it just wasn't fun to hit players from nearby. It defeated the purpose of the game, which was all about *throwing* stuff.

After some thinking, I decided to "subtly" encourage players to play this way and try keeping their distance to others:

-   Throwing from *really close distance* (basically standing on top of the other) does not slice them and gives the feedback \"Too close!\"

-   Throwing from *quite nearby* has a probability of being succesful, which gets higher the further you get away.

-   Then there\'s a big range where throwing will always be succesful and slice your opponent.

-   But if you manage to hit someone from the other side of the field, you get a \"Long throw!\" reward. (Causing your knife to gain speed again, your body to grow, and to slice the other player *twice* if you\'re lucky.)

(This is only applicable to players. Any other objects in the environment are still sliceable by any hit, as it would just be annoying to put restrictions on that.)

Then I spent almost a whole day fixing tiny issues with the UI -- both the menus and in-game things -- and rewriting some code to be much cleaner (and more generally applicable in the future).

This is an interesting experience, as it usually reveals what the game *should have been* :p Now, after actually making and testing the whole game, I have a much clearer picture of which parts I need and which I don't.

The biggest examples are:

### Realization #1

**Realization #1:** It's a game about slicing stuff. Yet most arenas had nothing that could be sliced (besides the players, obviously).

Now, retroactively, I added elements to *all arenas* that can be sliced. But I just didn't think about this beforehand. Most of these elements *have no functionality* and are purely for decoration and the satisfaction of destroying the arena :p

### Realization #2

**Realization #2:** It's a game about throwing stuff. In the first version, all throws were a straight line ... always. (Unless you had a boomerang of course, but that's a special type that only sometimes appears.) After making some arenas, I found much more enjoyable/varied ways to throw.

The swimming pool has a *drain* that sucks knives towards it, with the result that anything flying past is *curved* around it. This looks cool, is logical/intuitive, *and* has clear gameplay applications. I wish I'd known this sooner!

### Realization #3

**Realization #3:** It's more fun to give players *more than they need*, than to hold back in fear of adding too much.

After the first playtest, it was clear that players were just *swimming* in knives. They were too easy to get and never disappeared!

My first instinct is, of course, to lower the numbers. Make them appear less frequently. Make it much harder to get a knife. Set hard, low limits.

But that's the wrong way of thinking. Players really *enjoyed* the fact that it was so easy to get something to throw.

So I decided to keep it this way.

Instead of scaling back the knives, I added a unique way to *lose knives* in each arena. A way that can happen accidentally *or* if you choose to use it. A way that fits the arena, the setting, the gameplay.

It is, again, something I should've done from the start. Luckily I only made a few arenas for that first version, so I was able to adjust course for all the arenas afterwards.

### Realization #4

**Realization #4:** In the same vein, in a competitive party game (about eliminating others) ... players are going to be dead a lot of the time.

If the rounds are *really* quick, this is fine. (Elimination is actually a *great* source of tension in a game, as there's no coming back from it.)

But with this game, especially on the full 6-8 players, rounds can be a bit longer and you can stay dead a while.

The solution? Again, a *unique thing* in each arena that dead players can do or at least interact with.

This means that, over a week of development, a sort of "arena bible" appeared that said:

-   It should have something for dead players to do. (Not too overpowered, but enough to influence gameplay somewhat.)

-   It should have lots of things to slice, either purely for decoration or with gameplay influence.

-   It should have a unique way to *lose* throwables.

-   It should have a unique color scheme. (Just looks nice in general and distinctive in the settings.)

-   It should have *one* completely unique rule or mechanic that's not found, in any way, in the other arenas.

## Towards V2: Another playtest

Albeit delayed (for many reasons), it's now one month after Halloween, and I'm still working towards that big (paid) v2 release.

We just did some playtesting for it, and here are the results.

(First of all, there were obviously bugs. But we're now at a stage where none of them are game-breaking, just minor things that don't go exactly as intended.)

### Realization #1

**Biggest realization: the game should be simplified even more, especially at the start.** By adding the second 50% of the content (extra arenas, extra throwables), you easily lose sight of the first 50%. Instead, that becomes harder and more muddled as well, until the game has become a bit unfriendly to newcomers.

Another realization that goes hand in hand with that is: **UI elements should be bigger and stay on the screen longer.**

In concrete, I wrote down these notes:

-   Add another arena at the start. This one has *no powerups*, everyone starts with *X knives* (and none can be added/removed), and there are *no specialties*. This is literally the "training arena"

    -   That's also the general state in which you start: only knives, no dumplings or other throwables, no extra rules enabled.

-   Larger UI elements

-   Larger feedback + wait longer before it fades out

    -   Also, *more* feedback. Seeing your playtesters do crazy shit is a great wake-up call about how many things *don't* have adequate feedback

-   Reminders stay on screen longer ( + can't be skipped by accident)

-   Larger minimum size for players. (Which means they stay more visible + die earlier) => also a strict minimum size you can never go under, even in modes where you cannot die

-   **Your active knife is always at the front**

Especially the last one should be huge. This idea of "wherever a knife enters, that's where you throw it from" is *nice* and will stay in the game ... but not enabled by default.

Why? When we playtested the game, I had been away from it for \~4 weeks. (I deemed the game finished and was just waiting for the playtest.)

When I picked up the controller ... I was surprised by my own controls :p It took me at least a minute to realize what was happening and how to adjust, and even then it was quite difficult.

Even me, the developer, expects that the thing we're throwing is right in front of us. It's just the natural, intuitive way to think about throwing and aiming. So it should be the default.

**Remark:** in hindsight, I should also have left some room for error. Now, when a knife just *barely* glides past your body, it might either mean "no hit at all" or "a way bigger slice than expected". The physics are completely realistic in that regard and just calculate the precise line through the object. Instead, I should've done something like: "a tiny hit is no hit, any other hit is *at least* this damaging"

### Realization #2

**Another realization: the game is just full of *stuff*, and the players too *small*.**

I've learned now that this is an inherent issue with this game idea: because you win by slicing other players ( = making them smaller) ... as the game continues, it becomes *harder and harder* to see yourself and others.

There's no way around it. The problem is baked into the game idea.

(We could've fixed this by reversing the core idea. Your goal is to be the first one to reach size X. This way, other players can *delay* you by slicing you, but in general everyone trends upwards in size.)

Basically, after working on this game for a month in total, I've learned what *not to do* and how I'd do it *differently* the next slicing game I make.

But for now, I'll need to fix the game I have.

Players should die sooner, so they don't become *too* small. Stuff in the level should disappear sooner. (For example, the jungle has vines that regrow after X seconds. Make that longer. Don't regrow them after 2 or 3 times.)

If players happen to grab a lot of knives (or rarely lose one), the number of throwables becomes way too high. Randomly destroy some of them (which aren't owned by players, of course).

### Realization #3

**Nudging players into the right direction.**

Even though you cannot slice players from close range anymore ... players still kept trying it, over and over, leading to button mashing frenzies once in a while.

And then they were confused about what was happening, why they weren't hitting anyone, etcetera. So this behavior isn't adding to the fun.

How do we fix that?

-   When players do a close-range shot, they are penalized for that. (Shrink, get sliced, become frozen in their place, something clearly visible.)

-   When players are *close to another player*, they are somehow penalized for that. (But this would be unfair, as I would have to penalize *both* players being close to each other. The only way it'd work is if the penalty is "*you cannot throw"*.)

The only issue I see is: *how do we communicate this to players? This is another rule to learn/remember? Do we really want that?*

**Remark:** also, I'll probably enable the "shrink area" rule by default. It really helps bring games to a close in under 5 minutes. Especially when there are only 2 players left, it helps them to focus and slowly go towards the center, where a confrontation is inevitable.

### Realization #4

**A completely different way to aim**

So ... some people have trouble *holding one button*, then aiming with the *other*. Additionally, it's a bit annoying that you're *locked and standing still* when you do so.

It seems that it would be better to:

-   Always allow movement (with arrow keys/joystick)

-   And pressing/holding the throw button just *rotates you* (for aiming). (Release to actually throw.)

Why might this be better?

-   You're free to move around while aiming. (Allowing you to dodge or gain distance.)

-   The movement input is consistent: it always moves, in the same way, never changes.

-   Quick-pressing does what you'd expect: immediately throw in your current direction.

-   Aiming takes slightly more time and therefore becomes a more conscious action.

-   But you can still freely aim anywhere you want, after some training with the mechanic.

## Towards a final version: more playtesting

So, I tested the game again with a bunch of players! To preface this: the project dragged on way longer than I wanted, so I was already calling this the final playtest, even if I thought major improvements were possible. I was just done with it and thought putting more time into it would just ... delay it indefinitely.

### The Good Stuff

Fortunately, it went well! Most parts were really enjoyable, almost no "teaching" or "setup" was necessary.

The new control scheme (always walk with joystick, use one button to aim) was favored by all players. Gave more freedom and gave them the impression they were better at the game. (This might also be because many tested it for the *second* time, automatically making you better than the first time :p)

The new training arena was a great addition, but with some issues I hadn't foreseen during development (which I'll mention soon).

One controller gave out, and switching that player to play with the keyboard was also seamless, which I'm happy with.

(It did reveal a flaw with my login system: if somebody *leaves*, all players after it are moved up a spot, because we can't have gaps. But that means ... colors can change when somebody accidentally leaves, which is *very confusing*. But I can't really solve it now, I'll remember this for the next game.)

### The Bad Stuff

However, some key components of the game weren't working the way they should. For example ...

-   Anytime you went back to the menu, teams were reset (instead of remembered).

-   The wrong control scheme was turned on by default.

-   Sometimes, players that died couldn't do *anything* anymore (you should be able to move your ghost in any case).

-   In the "Family Dinner" arena, knives should be able to fly over the tables ... but they didn't. (Which makes the arena pretty unplayable, as you have almost no space otherwise, and can't slice the fruit on the tables.)

But that was down to me leaving on some debugging stuff (before exporting the game for the test), or some other minor configuration issues. I've made sure -- as sure as I can be -- this doesn't happen again.

**The training arena is a *great* addition ... with one fatal flaw.** If a few players are dead and a few remain ... it's quite likely all knives get stuck on a part of the ravine *nobody can access*, basically stalemating the game. How to solve?

Usually, I immediately have 5 possible solutions. But this time? Nothing was great. (Place teleporters? Destroys the purpose of the ravines. Move standstill knives in unused areas to used areas? Would work, but very complicated to check (well).)

In the end, I settled on a compromise. Slowly, over time, parts of the map open up. The ravine is already broken into three parts (because more needs to be blocked off on high player counts), I can just remove one every minute or so. This might mean you just need to *wait* for 30 seconds before you can continue playing ... but we'll have to accept that.

Automatically enabling the **shrink area** was a great move, as it forced games to a conclusion within a nice time frame. On dark maps, though, it's really tough to see the black mist coming at you. So I had to draw a clear contrasting outline around it.

The **grow** powerup is the only one put into the game by default. That was a bad idea. It caused games to go on way longer, because players could just constantly regrow themselves to full size. It should *not* be enabled by default. Moreover, there should be a strong *limit* on powerful powerups like this.

An idea (which I think is definitely the best): some powerups can have, at most, X distributed *per game*. So they are still a bit random, there's still some fluctuation, but after say 5 of them, they won't appear ever again.

And lastly, some of the more "dense" maps (almost no open space, filled with lots of stuff) are annoying if you start too big. So simply start players smaller on those maps, and perhaps reduce some of the physics bodies. (The *Forest* is the biggest offender here. But that's to be expected, as it was *designed* to be the most dense map.)

### We're stopping here

Is the game perfect now? No, of course not.

Much special content (such as powerups/throwables) are not that significant when used in-game, some players still have trouble grasping what's happening or how to aim well (at the start), the idea could've been executed better and more ... I guess, cleanly?

But it's polished, tested a lot, very accessible (to even non-gamers), and does an okay job at nudging players towards fun strategies and trying cool stuff. And most importantly: the difficulty is just right so that actually *slicing someone* -- getting a good, clean hit on them -- is *extremely* rewarding and makes players jump with joy.

That's what it's all about, so I don't want to change anything to the balance anymore :)

## Where does this leave us?

In a sense, it means that the current game is *not* the best it could be, and I see clear ways to *greatly improve it*.

-   Remove powerups -- everything special comes from the throwables.

-   Build arenas and modes from the ground up using the knowledge I have now.

-   Encourage *throwing* (instead of hitting from close distance) in all aspects of gameplay.

-   Add many more elements that make throwing more varied, like the attractors that curve throws, teleporters, or things that give back your knives after a delay. Make *that* the backbone of the game.

-   (Using this, clean up all the code and messy systems in the game now. Because I couldn't predict, when I started, how this game would turn out.)

But here's the thing. This was meant as a quick Halloween game. Working on it past Halloween, far past the original plans, is already something I had my doubts about. But I don't want to leave projects hanging and really like *completely* finishing something.

And, if you've read this devlog the whole way through, you've seen this pattern: I create something, I realize afterwards (because of making it) that I need to steer in a different direction, the cycle repeats endlessly.

Even if I took the time to completely redo the game (according to the list above), there'd probably still be many imperfections and updates to make.

I decided to leave the game as it is. The basic systems and concepts from version 1 are fixed and stay in the game. I just want to add a bit more content to make the game worth its price. It would probably cost me more time and energy than I already put into the project to *rewrite and improve it* by this much. I'd rather create a whole new game in that time, using the lessons I learned.

(Also because I noticed I really like drawing/sketching new arenas. Making them *functional* and *balanced* is a whole different beast ... Let me tell you: in a game where objects can be sliced, you'll be spending 90% of your time putting things in specific collision groups and physics layers and hoping you didn't mix them up.)

If the game becomes successful? If it gets downloaded/played again by thousands each year at Halloween? If I find a short, clear way to improve it? Sure, I will do so.

But for now, it's onto the next project! (Which might use the slicing mechanic again ... but *improved* this time!)

Until the next devlog,

Pandaqi
