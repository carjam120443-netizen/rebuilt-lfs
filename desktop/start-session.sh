#!/bin/bash
set -e

# Start the Rebuilt LFS graphical desktop.
# XFCE is the initial desktop target.

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export XDG_SESSION_TYPE=x11

exec startxfce4
