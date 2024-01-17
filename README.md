# roblox-console

An embeddable console GUI which you can write programs for.

 > You can test a demo version [here](https://www.roblox.com/games/15359714312/roblox-console)

I got tired of drawing UI buttons and menus and states for roblox game dev tools, so I decided to simplify to console-based programs.

Because `roblox-console` is fundamentally about the GUI, I made a demo where you can try making and running your own programs.
You can also use the demo to test another project of mine called `roblox-css`, which helps separate aesthetic styling code from functional code.

### Grab the Terminal package!

The code for the `Terminal` object can be found in `src/replicated-storage/Terminal.lua`, or you can find it in a [github gist.](https://gist.github.com/andrewens/11ea5fcbecfc8aaa8cec1acba8757bb9)

### Demo place

You can play, download & edit your own copy of the [demo place.](https://www.roblox.com/games/15359714312/roblox-console)

### Build project using rojo

You can sync this project to ROBLOX Studio using `Rojo` by `lpghatguy`.

The following dependencies need to be added to `ReplicatedStorage` for everything to work, though:

- Loadstring
  - Parses strings of lua to be executed on the client
  - Get the RBX model [here.](https://create.roblox.com/marketplace/asset/15358817822/Loadstring%3Fkeyword=&pageNumber=&pagePosition=)
  - (I didn't make it, but I forgot where I got it so I just made my own RBX model)
- [roblox-css](https://github.com/andrewens/roblox-css)
  - allows defining GUI appearance as stylesheets
