# roblox-console

An embeddable console GUI which you can write programs for.

I got tired of drawing UI buttons and menus and states for roblox game dev tools, so I decided to simplify to console-based programs.
Because `roblox-console` is fundamentally about the gui, I made a demo where you can try making and running your own programs.
You can also use the demo to test another project of mine, `roblox-css`, which helps separate aesthetic styling code from everything else.

### Demo place

You can play, download & edit your own copy of the demo: https://www.roblox.com/games/15359714312/roblox-console

### Build project using rojo

You can sync this project to ROBLOX Studio using `Rojo` by `lpghatguy`.

The following dependencies need to be added to `ReplicatedStorage` for everything to work, though:

- Loadstring
  - Parses strings of lua to be executed on the client
  - ROBLOX Model: https://create.roblox.com/marketplace/asset/15358817822/Loadstring%3Fkeyword=&pageNumber=&pagePosition=
  - I didn't make this, but I don't remember where I got it from :/
