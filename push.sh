#!/bin/bash
# Publish the Chameleon resource pack to its public GitHub repo, and print what the server needs.
#
# WHY THIS REPO EXISTS: the Minecraft client downloads a server-sent resource pack over plain
# HTTPS, so the file needs a stable public URL. This box runs no web server, and the only other
# already-exposed surface is the Tailscale Funnel in front of Crafty's web UI - which is a worse
# thing to hang a public file off. A public GitHub repo is the smallest, most boring option.
#
# WHY THE SHA-1 MATTERS: it is not decoration. The client caches the pack against it, so a hash
# that does not match the file makes every player re-download on every single join. Always take
# the hash from THIS script's output, never from a value written down earlier - the pack is
# regenerated whenever the rig geometry changes, and the hash changes with it.
#
# Usage:  ~/mcstage/champack-repo/push.sh
set -euo pipefail

REPO=/home/rufus_main/mcstage/champack-repo
SRC=/home/rufus_main/mcstage/cham/pack/chameleon-rig.zip

if [ ! -f "$SRC" ]; then
  echo "no pack at $SRC - regenerate it with ~/mcstage/cham/gen/build.sh first" >&2
  exit 1
fi

# Refuse to publish a pack the plugin is not also serving. A mismatch here is invisible at the
# server and shows up as a client that downloads a pack whose models the server never spawns.
DEPLOYED=/home/rufus_main/docker/crafty/servers/c820a00e-254e-472e-8fc4-b6e1fdf25000/plugins/Chameleon/pack/chameleon-rig.zip
if [ -f "$DEPLOYED" ] && ! cmp -s "$SRC" "$DEPLOYED"; then
  echo "WARNING: the built pack differs from the one deployed to Party Games." >&2
  echo "         Deploy it there first, or players download models the server will not use." >&2
fi

cp "$SRC" "$REPO/chameleon-rig.zip"
cd "$REPO"

SHA=$(sha1sum chameleon-rig.zip | cut -d' ' -f1)
SIZE=$(stat -c%s chameleon-rig.zip)

python3 - "$SIZE" "$SHA" <<'PY'
import re, sys
size, sha = sys.argv[1], sys.argv[2]
p = "README.md"
t = open(p, encoding="utf-8").read()
t = re.sub(r"^\| size \|.*$", "| size | %s bytes |" % size, t, flags=re.M)
t = re.sub(r"^\| sha1 \|.*$", "| sha1 | `%s` |" % sha, t, flags=re.M)
open(p, "w", encoding="utf-8").write(t)
PY

git add -A
git commit -q -m "pack $(date -u +%Y-%m-%dT%H:%M:%SZ) sha1 ${SHA}" || echo "(nothing changed)"

if git remote get-url origin >/dev/null 2>&1; then
  git push -q origin main
  URL=$(git remote get-url origin | sed -e 's|git@github.com:|https://raw.githubusercontent.com/|' -e 's|\.git$||')/main/chameleon-rig.zip
  echo "pushed."
else
  URL="https://raw.githubusercontent.com/OWNER/REPO/main/chameleon-rig.zip"
  echo "no 'origin' remote yet - committed locally only."
  echo "add one with:  git -C $REPO remote add origin git@github.com:OWNER/REPO.git"
fi

echo
echo "  render.pack-url:  $URL"
echo "  sha1:             $SHA"
echo "  size:             $SIZE bytes"
