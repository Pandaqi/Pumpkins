# Carving pumpkins

## General

The idea of "slice a shape into any other shape" was not applicable in my rolling game.

But it still works and it has potential, so let's make a different game out of it. The most logical conclusion: a fighting game where you *literally* slice your opponents.

**Titles:** Carving Pumpkins and Dwarfing Dumplings

## Main mechanic

When slashing/attacking, you *literally (realistically)* *slice their shape*. They become the "biggest shape", the other one is simply lost. Once the biggest shape is below a threshold, a player is considered completely dead.

Multiple player configurations (1-6 players max): Team-based, AI-bots

## General rules

-   If you're bigger, you move faster

-   A knife thrown from close range, will not slice. If thrown from a bit further, there's a *probability* it will slice.

-   If a knife is thrown from very far away, you get a "long throw" bonus:

    -   The knife resets to its original velocity (gaining huge speed)

    -   You grow a little

    -   And there's a probability of a second slice through the player.

## Input

Arrow keys / Joystick = Move

Button = Slash

-   Quick-press it to slice straight ahead. (The normal across your looking direction, with a small maximum range.)

-   Long-press it to throw your knife.

    -   This shoots a narrow rectangle, which functions as a bullet, and will keep flying until it reaches a non-player object.

    -   There it gets stuck. Touch it to retrieve it again.

Aiming is different between keyboard and controller

-   Keyboard has "turn left" and "turn right". (Because just using arrow keys only allows 8 directions for aiming, which isn't enough.)

-   Controller just follows your joystick.

-   In both cases, if you hold it long enough, it slows down. (To get even more precise, but also force you to release quite quickly.)

## Collision Layers

1.  All

2.  Players. (Though collision exceptions are added manually, at the start, for all team members.)

3.  Terrain

4.  Powerups (and other (custom) items)

5.  Ghosts => used for dead players to interact in *some way* with the environment, and to keep them inside of bounds

6.  Areas that want to check if a throwable enters them (even those without a body)

7.  Things that are only solid for *players*, but not for *throwables* (or anything else). Only their *mask* is set to 7.

## Groups

-   Players => actual, controlled player entities (includes bots)

-   Parts => loose player parts; still have a rigid body and value, but can't be controlled

    -   PlayerParts

-   Deflectables => knifes get deflected by them

-   Stuckables => knifes get stuck in them

-   Sliceables => knifes slice through these

-   Unpullables => can't be moved by e.g. a magnet pulling on it

-   Powerups

    -   PowerupsRevealed

    -   PowerupsUnrevealed

-   KeepAlives => objects in this group will have their *biggest* body remain (as an active entity), used for Players (as they can be sliced) and the Huge Dumpling

-   IgnoreNavs => not counted when generating navigation for Bots (used for things that will move around or can be destroyed+respawned)

-   Custom => has a completely custom response to throwable hits

-   ThrowableDeleters => deletes a throwable upon hit (if the hit was actually successful/handled)

Remark: adding something to *both* the Stuckables and Sliceables means things are stuck in it *if they go slow*, but slice it *if they go fast*.

# Modes

### Dicey Slicey

Slice your opponents to make them smaller. Too small? Dead.

Last player standing wins.

### Collect 'em All

Parts sliced off your opponents can be *collected*.

First one to X parts wins.

Remarks:

-   Cannot collect your own or teammate's parts

-   Players constantly (automatically) grow bigger to accommodate the size loss through slicing.

### Bullseye

Targets appear across the map. They are divided into sections, giving different points. Throwing from further away *multiplies* the points you get.

Slicing another player gives one of your points to them.

First to X points wins.

Remarks:

-   Some targets rotate

-   Players start with *more* knives, as they get stuck inside the thing. (Still valid, as now you're not *physically pushed away* from targets anymore?)

### Frightening Feast

Hitting a dumpling on another player transfers it to you. (There are many different types; some that you might not even *want* to steal.)

First to hold X dumplings (at the same time) wins.

Remarks:

-   Ensures at least the basic dumpling is available + place once every 3 powerups.

-   Those dumplings you hold *cannot be thrown*. (As they are seen as a collectible in this mode.)

-   You can still slice players. Why? If you're smaller, your dumplings are less spread out, increasing the chance of someone hitting them.

-   (Still though, might need a better ruling for this.)

### Dwarfing Dumplings

Each team gets their own *huge dumpling* to protect. (Max 3 teams.)

If it's completely sliced, you lose.

Remarks:

-   Players start smaller

-   When you slice the huge dumpling of an opponent, you are blasted back. (To prevent easy repeat slices.)

-   When you die, you respawn back (after a few seconds) at your home base. (In the meantime, you're a ghost.)

### Ropeless race (TO DO)

Each player receives *lives* attached to them via ropes. If another player slices through such a rope, it comes loose and you lose that life. No lives? Dead.

Last player standing wins.

Remarks:

### Capture the flag (TO DO)

One player from each team has a *flag* inside of them. (Max 3 teams.)

This is hidden information. (The player having the flag cannot throw knives, that's how they know.)

If the flagbearer is sliced through, you obtain the flag. First to X captures wins.

Remarks:

-   Throwing a throwable at a teammate (and them grabbing it), causes the flag to *switch places*??

-   You still need to bring the flag *back home??*

# Powerups

Powerups are shown as "packages". You need to *slice them open* to see what's inside. (You can also grab them the normal way, but then you don't know what you get.)

As always, they are grouped by *category*, where each category follows the exact same color scheme.

### Shape

-   **Grow**

-   **Shrink**

-   **Morph** => reset to a *different* shape (from predefined list)

-   **Ghost (temporary)** => you are temporarily unslicable

-   **Hungry (temporary)** => walking over pieces makes you *eat* them (to grow yourself)

### Knife/Slashing

-   Lose knife

-   Faster throw speed

-   Slower throw speed

-   Knife Repel

-   **Repeater =>** Throw *all* your knifes at the same time. **=> TO DO**

-   **Destroyer =>** Anything thrown at you is simply destroyed on impact

### Moving

-   Faster move

-   Slower move

-   Reversed controls (temporary)

-   Ice (temporary)

### Collecting

-   Magnet (temporary) => you *attract* stuff to yourself

-   Duplicator (temporary) => any dumplings you eat/parts you collect are *duplicated*

-   Clueless (temporary) => you can't collect anything

-   Auto Unwrap (temporary) => automatically unwrap powerups when walking over them

### Misc (perhaps *too* wild)

-   **Switch teams!** (Randomly. Can't really show all colors on such a thing.)

-   **Vampire** =>

    -   The game has light/dark. Vampires can't enter the light?

    -   A vampire can only slice you from *close range*, but does *more damage* if so. (As they "drink your blood".)

# Arenas

### Ghost Town (Implemented)

-   Mostly open grass field, with a few bits of rubble and leftover stone walls

-   Switches between day and night.

    -   At night, one player becomes a ghost.

    -   And two big "ghost knives" appear.

-   Meant as a light training ground, so mostly open and free, no complex stuff.

-   **Fun slicy stuff?** Some barrels.

-   **Removing throwables?** Happens when you throw one into the cave

-   **Dead players?** Can control the Ghost Knives.

### Spooky Forest (Implemented)

-   Some trees deflect, others get your knife stuck.

-   Some trees can be *cut down* by throwing a knife. (Though if too slow, it just gets stuck. And if successful, the throwable is removed.)

-   It has a layer "above" the players, so you're actually walking underneath branches.

-   A *mist* travels through the map regularly. Anything thrown into it is deflected randomly (changing its path slightly)

-   **Fun slicy stuff?** Sliceable trunks.

-   **Removing throwables?** Happens by throwing them into the "sliceable" trunks

-   **Dead Players**? Get a mist around them as well.

### Graveyard (Implemented)

-   Tombstones to hide behind (which might move)

-   A light that constantly moves

-   Some flowers/variation around the graves.

-   **Fun slicy stuff?** Some stones near the edges of paths, all of them modular and sliceable.

-   **Removing throwables?** The gates open (alternating pattern). Anything thrown into the open gate ("out of the field") is destroyed.

-   **Dead players?** Become a tiny tombstone, capable of moving around (very slowly), and any knives in them can be thrown again.

### Dark Jungle (Implemented)

-   Small areas separated by thick patches of leaves: these constantly regrow, up to a limit

-   Some solid things inside as well, to prevent knives from slicing through *absolutely everything* at once.

-   Fireflies for nice lighting. Hitting one turns off its light (temporarily)

-   The spiral-icon places teleport both *players* and *throwables* to their counterpart (diagonally, other side).

-   **Fun slicy stuff?** The vines.

-   **Removing Throwables?** *Doesn't happen*, as you really need them to slice your way through the jungle.

-   **Dead players?** Become a firefly.

### Bogus Blackouts (Implemented)

-   Divided into rooms

-   Throw something against the light switch to completely turn off the lights. (This also happens randomly.)

-   Stairs to teleport from one corner to the other

-   Windows can be broken when throwing a knife through them.

-   **Fun slicy stuff?** The windows.

-   **Removing throwables**? Happens by throwing them out the window. (There's one window going "to the outside".)

-   **Dead Players**? Can activate light switches, if *multiple* are on the same one.

### Swimming Pool (Implemented)

-   A simple swimming pool. (When you walk through water, ripples appear around you.)

-   Maybe several pools, of different sizes, with a small walkway between and a jumping plank/glide.

-   Moving in the water is much *slower*, or just *different*? (A bit like the ice movement in Totems of Tag. Or *aiming* is constant, meaning you just keep rotating and rotating until you release.) => Yes, both aiming and movement are different and wobbly.

-   Also, *entering* water goes with a splash/bang? (It sends shockwaves and literally blows away things/people around the point.)

-   **Fun slicy stuff?** There are those "blow-up boats" (and crocodiles, and helper things, etc.) floating in the water? => might not even all be throwable, getting stuck in something like this + it floats is also fun

-   **Removing throwables?** There's a *drain* somewhere that attracts throwables (and stuff in general?)

-   **Dead players?** Can vote (by hovering over buttons) to change the wave direction.

### Family Dinner (Implemented)

-   A family member sitting in the room. Any time a knife gets stuck in them, they become more *angry*. Once the meter is filled, they explode in FURY and shoot away all the knives.

-   Otherwise just a big table, with chairs, and lots of food that can be sliced.

-   **Fun slicy stuff?** All the food and plates on the table.

-   **Removing throwables?** The "angry" person doesn't give back *all* the knives put into it? (In any case, keeping the knives for some time is already a form of "removing" them.)

-   **Dead players?** Can eat the many leftover food parts. If they do that enough (10+?), they are revived, albeit with a smaller body. If that's too strong, just give them *some* of their functionality back.

### Pirate Curse (implemented)

-   An island with some water around it. (Using all the water mechanics/rules also used in the swimming pool.)

-   Treasures appear. Hit them to:

    -   **Heart:** revive the last player that died (though smaller/less powerful)

    -   **Destroy**: destroys whatever was thrown against it

    -   **SelfSlice**: your body is randomly sliced

    -   **Curse:** your controls are reversed + you get some random penalties to speed/movement/throw speed/number of throwables

    -   **Free Point:** Get a free point (in a mode where collectibles are a thing). If you can die in this mode, you *grow*.

    -   **BigCurse:** *all* players are teleported to a random different location and might receive a random curse.

-   **Fun slicy stuff?** The treasures lying around. (Plus some leaves or stones?)

-   **Removing throwables?** There's a treasure for that.

-   **Dead players?** There's a treasure for that.

### Haunted House (implemented)

-   The whole *stage* changes every X seconds => there's a flash, fade out, all obstacles inside are removed (if needed), then we come back to the new arena

-   Lots of creepy things *doing things on its own* => mostly has to do with *traps*

    -   **Trap 1:** a wall that shoots knives sometimes. These have a *random owner*, which might be you (in which case you grab it) or not.

    -   **Trap 2**: a floor that gets *holes* in them from time to time

    -   **Trap 3**: boulders rolling/flying at you => can be sliced to prevent your demise.

    -   **Trap 4**: just a lot of furniture moving around => there are *mirrors*, some are fake and will break on contact, others reflect the knife back *but with a different owner* ( = slicing yourself)

        -   This idea is actually so nice it might be an arena in and of itself?

-   **Fun slicy stuff?** ??

-   **Removing Throwables?** Happens on certain stages.

-   **Dead players?** The icons for the other arenas are in the corners. Dead players can vote for the next trap (when it switches).

### Cheese Factory (Skipped because too much work)

-   Akin to a storage room/factory mix.

-   Conveyor belts are everywhere.

    -   Lots of cheese blocks (or butter, or whatever) appearing on it. (Also in fixed stacks on the field.)

    -   Players are also influenced by them

-   *Throw* the cheese to freeze people in place?

-   *Throw* the butter to blow them back and make movement skippy slidy? (But after one throw, they disappear.)

-   Add a **slicing machine** somewhere, which eats players and throwables alike.

-   (Add those doors that swing open/closed?)

-   **Fun slicy stuff?** all the cheese and butter

-   **Removing throwables?** Throw them into the slicing machine.

-   **Dead players?** Can reverse the direction of conveyor belts, once in a while.

### Training ravines (Implemented)

Has no special rules, on purpose. It's meant to both *teach the game* and *reinforce the better play style (keep distance, aim, hit from distance)*

Two features:

-   A ravine that splits all players into their own zones

-   Stones that randomly appear and disappear (so they can be used for cover, and fill the empty space a bit)

### Bat Cave

A dark (grey/black) cave full of bats. Get inspired by the Batman visuals and ideas.

### WeB o' Spiders

A big spiderweb. Ideas:

-   You can only move over the actual lines.

-   (Knifes only move over those lines as well?)

-   Big, scary spiders move around as well. They block your path + eat/slowdown any knives thrown into them?

## Workflow for Each arena

**Step 1:** Draw it in Affinity Designer, keeping in mind separate layers/groups

**Step 2:** Designate zones for *collector UI* and *huge dumplings*

**Step 3:** Import to Godot. (Place correct sprites, in correct map layer, at correct position.)

**Step 4:** Create static bodies where needed. Put these in **Collision layer 1 and 3.**

**Step 5:** Add lights, canvas modulate, and light occluders where needed.

**Step 6:** Finetune, add custom logic, make some things stuckable or deflectable or sliceable.

# Throwables

### Knives

-   **Knife =>** slices stuff, has an owner (which it loses when no velocity), no body

-   **Boomerang** => after one hit, finds a (smooth) path back to owner

-   **Curve** => simply curves a lot (a bit random, not sure if too great)

### Dumplings

-   **Dumpling** => deflects knives, in-air and when on your body

-   **Poisoned Dumpling** => when hit by someone, the attacker is poisoned: they lose one throwable and get their controls inverted.

-   **Double Dumpling** => worth two points (in modes where dumplings are collected), makes you bigger

-   **Downgrade Dumpling** => worth *minus points* (in modes where dumplings are collected), makes you smaller.

-   **Timebomb Dumpling** => will automatically throw itself after X seconds

**Remark:** the effects of dumplings are also, by default, "on hit". Because dumplings are friendly and grabbed by anyone. So a hit just means they grab the dumpling and get the effect.

### Misc

-   **A Melee Weapon.** Something that only works close range, but is *very effective* there. Probably an "area" effect that hits everything within a certain radius, no matter how you aim.

-   **Thor's Hammer** => when hits body, slices you 1-3 times in random ways => when you hold the throw button, all hammers come flying back to you?

-   **Bat** => chases the nearest player, simply shrinks you?

-   **Spider** => pushes *players* aside, as they don't want to come near the spider or touch it, but it does move incredibly slowly. (Or it copies your movement after being thrown??)

-   **Borderline** => there's a knife that draws a line behind itself. That line will persist for X seconds. Anyone that crosses it is sliced?

-   **Grappling Hook:** A knife that works as a grappling hook: throw it, whenever it does something, *you* are attracted to its current position.

They can have these properties:

-   Owner: *Auto, Friendly, Hostile*.

    -   Auto = default behavior. Starts with an owner. Once stuck or standstill, it loses its owner.

    -   Friendly = has no owner; anyone grabs it when nearby, can't hurt players

    -   Hostile = has no owner; nobody can grab it, everyone is hurt

-   Body: *False, True*

    -   If false, no *actual* CollisionShape is created, and everything goes via RayCasts. Needed for objects that *slice* things.

    -   If true, a KinematicBody and CollisionShape are added and used for movement instead
