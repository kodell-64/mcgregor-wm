# mcgregor-wm

An extremely minimal X11 window manager in the spirit of Blackbox: a thin
frame and title bar on each window, multiple desktops, and nothing else.
There is no toolbar and there are no menus. It's a single C file of about
3,100 lines, with a comment above every function explaining what it does,
and needs only Xlib and libXinerama.

* **No focus stealing.** A window that opens while you are working never
  takes the keyboard focus. It shows up with an **orange** title bar, and
  one Alt+Tab takes you to it. Apps that try to grab focus on their own,
  through `_NET_ACTIVE_WINDOW` or `XSetInputFocus`, get the orange title
  bar too, and focus stays where you left it. The exceptions: a dialog
  opened by the window you're using (a Save dialog, say) does get focus,
  and so does the first window on an empty desktop.
* **Multiple monitors.** Desktops span all monitors, so Alt+2 switches
  every screen at once, as in Blackbox. Maximize and fullscreen fill only
  the monitor the window is on. New windows open on the monitor the mouse
  is on, and Alt+Shift+Left/Right throws a window to the previous/next
  monitor, left to right.
* **Alt+Tab in most-recently-used order.** Tap Alt+Tab to flip between your
  last two windows. Hold Alt and press Tab repeatedly to go further back.
  Only the current desktop's windows are included.

## Install on Debian trixie

```
sudo apt install build-essential libx11-dev libxinerama-dev xfonts-base
make
sudo make install            # /usr/local/bin, man page, login-screen entry
```

Or build and install a .deb package:

```
make deb
sudo apt install ./mcgregor-wm_1.0_amd64.deb
```

The .deb also registers mcgregor-wm as an `x-window-manager` alternative.

Then choose **mcgregor-wm** from the session menu on the login screen
(LightDM, GDM, SDDM). With `startx`, put this in `~/.xinitrc`:

```
exec mcgregor-wm
```

## Keys

| Keys | Action |
|---|---|
| Alt+Tab / Alt+Shift+Tab | cycle windows, most recent first; release Alt to choose (the mouse pointer jumps to its centre), Esc cancels |
| Alt+1 … Alt+4 | go to desktop 1–4 |
| Alt+Shift+1 … 4 | send window to desktop 1–4 |
| Ctrl+Alt+Left / Right | previous / next desktop |
| Alt+Shift+Left / Right | move window to previous / next monitor |
| Alt+F4 | close |
| Alt+F9 | minimize (Alt+Tab brings it back) |
| Alt+F10 | maximize / restore |
| Alt+F11 | fullscreen / restore |
| Alt+Return | terminal (`x-terminal-emulator`) |
| Ctrl+Alt+Shift+R | restart mcgregor-wm in place (X and your windows keep running) |
| Ctrl+Alt+Shift+Q | quit |

## Mouse

| Action | Effect |
|---|---|
| click a window | focus and raise |
| click the **[X]** on the title bar | close (slide off before releasing to cancel) |
| click the **[_]** on the title bar | minimize (Alt+Tab brings it back) |
| drag the title bar, or Alt+drag | move (snaps to monitor edges) |
| drag any edge or corner | resize (the cursor changes over an edge) |
| Alt+right-drag | resize from the corner nearest the pointer |
| double-click the title bar | maximize / restore |
| middle-click the title bar | lower |

## Starting programs

There's no menu, so put the programs you want at login in
`~/.config/mcgregor-wm/autostart` and make the file executable (an existing
`~/.config/mcgregor/autostart` from before the rename is still used if the
new one doesn't exist):

```
#!/bin/sh
xsetroot -solid '#2d3a46' &
setxkbmap us &
nm-applet &
```

Open everything else from a terminal (Alt+Return). For a launcher, add
`suckless-tools` and bind `dmenu_run` to a key in your terminal, or add a
line to the `keys[]` table.

## Configuration

Edit the block at the top of `mcgregor-wm.c` and run `make` again:

* `NDESKS`: number of desktops (up to 9)
* `MODKEY`: `Mod1Mask` (Alt) or `Mod4Mask` (the Windows key)
* `FOCUS_NEW_IF_NONE`, `FOCUS_TRANSIENTS`, `RAISE_NEW`: the new-window
  rules described above. Set `RAISE_NEW` to 0 to open new windows behind
  the focused one instead of on top.
* `WARP_ON_ALTTAB`: 1 (default) moves the mouse pointer to the centre of
  the window you Alt+Tab to; 0 leaves the pointer alone.
* `FONT`, `TITLE_PAD`: title font (default 15 px fixed) and the extra
  title-bar height around it
* `BORDER`: frame border width, which is also the edge you grab to
  resize (default 4 px). `CORNER`: how far along an edge still counts as
  a corner (default 20 px)
* Colours, edge snapping, terminal command

## Standards support

The basics are covered so panels, pagers and `wmctrl`/`xdotool` work:
`_NET_SUPPORTING_WM_CHECK`, desktops (`_NET_NUMBER_OF_DESKTOPS`,
`_NET_CURRENT_DESKTOP`, `_NET_WM_DESKTOP`), `_NET_CLIENT_LIST`,
`_NET_ACTIVE_WINDOW` (honoured from pagers and tools, refused from the app
itself), `_NET_CLOSE_WINDOW`, `_NET_WM_STATE` (fullscreen, maximized,
hidden, demands-attention), `_NET_FRAME_EXTENTS`, and ICCCM
`WM_DELETE_WINDOW`, `WM_TAKE_FOCUS`, size hints, urgency and transients.
Dock, desktop, splash and notification windows are left unframed.

## Restarting

Press **Ctrl+Alt+Shift+R**, or from a terminal run:

```
pkill -HUP -x mcgregor-wm
```

mcgregor-wm hands its windows back to X and starts again in the same
process, so the X session doesn't end. It starts the binary currently on
disk, so `make && sudo make install` followed by a restart puts a new
build into effect without logging out. Windows keep their desktop,
position, size, stacking, iconified state and fullscreen; the focused
window and Alt+Tab history are kept too. The autostart file isn't run
again.

If mcgregor-wm quits (Ctrl+Alt+Shift+Q), every window is put back intact
for whatever runs next.

## Not included (on purpose)

There's no toolbar, menu, window list or theme file, and no per-monitor
desktops: all monitors switch desktops together. It doesn't reserve space
for panels (struts).

## Multiple monitors

The monitor layout comes from the X server (Xinerama, which current Xorg
fills in from RandR), so set up your three monitors as usual with
`xrandr`, `arandr`, or `/etc/X11/xorg.conf.d`. For example, in
`~/.config/mcgregor-wm/autostart`:

```
xrandr --output DP-1 --auto --output HDMI-1 --auto --right-of DP-1 \
       --output DP-2 --auto --right-of HDMI-1
```

mcgregor-wm rereads the layout whenever it places, maximizes or moves a
window, and refits windows when the screen size changes. A window left on
a monitor that was unplugged is moved back onto a remaining one. Mirrored
outputs count as one monitor. To split one ultrawide monitor into two
halves, use `xrandr --setmonitor`.

## Testing

It was tested under Xvfb with an automated suite: focus never moves to new
windows or to apps that try to take it, Alt+Tab MRU order, Shift and Esc,
dialogs, desktops, click-to-focus, move, resize, maximize, fullscreen,
iconify, close, restart, and a churn test of 120 windows created and
killed (50 checks). A second suite with three side-by-side monitors of
different sizes (1280×800, 1920×1080, 1024×768) checks placement on the
mouse's monitor, per-monitor maximize and fullscreen, moving windows
between monitors, edge snapping, dialogs, and desktops (15 checks). All
pass. It has not yet been run on a real Debian
trixie desktop.
