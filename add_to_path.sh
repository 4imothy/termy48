#!/bin/sh
# this already releases safe
zig build
ln -sf $(pwd)/zig-out/bin/termy48 ~/bin/termy48
