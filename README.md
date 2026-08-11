# Chameleon resource pack

Server-delivered resource pack for the **Chameleon** minigame on a private Minecraft network.
Minecraft 1.21.11, pack format 75.

This repository exists **only** to give the Minecraft client a stable public HTTPS URL to download
from. There is nothing to build here and nothing to install by hand — the server sends it to you.

| | |
|---|---|
| file | `chameleon-rig.zip` |
| size | pending first push |
| sha1 | pending first push |

The sha1 is what the server sends alongside the URL so clients cache the pack rather than
re-downloading it on every join. **It changes every time the pack is regenerated**, and a stale
hash means every player re-downloads on every login. Take it from `push.sh`'s output, never from
a value copied earlier.

## What is in it

Display-entity models that let a player disguise themselves as a pixel-exact crop of the wall
behind them, at three body scales. Block textures are derived from the vanilla Minecraft client
jar; no third-party art is included.

## Publishing a new build

```
~/mcstage/champack-repo/push.sh
```

It copies the freshly generated pack in, refreshes the size and hash in this file, commits,
pushes, and prints the `render.pack-url` and sha1 to put in the Chameleon config. It warns if the
built pack differs from the one actually deployed to the game server — that mismatch is invisible
server-side and shows up as clients downloading models the server never spawns.
