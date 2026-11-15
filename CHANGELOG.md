# Changelog

## 2.6
- **Fixed:** with Left Click selected, holding the modifier no longer blocks the other mouse buttons on unit frames (e.g. Alt + Right Click bindings from Clique now work out of combat). Only the ping button passes through to the world.
- **More mouse buttons:** middle button and mouse buttons 4 and 5, with or without a modifier (no modifier is only allowed for buttons 3-5). E.g. `/pingac none 5` pings with just Mouse Button 5.
- Removed the **Same in combat** option: pinging always works the same in and out of combat (radial wheel on unit frames included).
- Everything is configurable from **Options → AddOns → PingAltClick** (modifier and mouse button) as well as from the `/pingac` window.
- `/pingalt` diagnostics show whether the frame lets the ping button pass through.

## 2.5
- **Configurable ping click:** choose the modifier (Alt, Ctrl, Shift, or Ctrl + Alt, Alt + Shift, Ctrl + Shift) and the mouse button (left or right). Default is still Alt + Left Click.
- New `/pingac` window with both dropdowns, the "Same in combat" option, a summary of the current combination and a warning if it overrides an existing keybind. Also available in **Options → AddOns → PingAltClick**.
- Quick setup from chat: `/pingac ctrl left`, `/pingac alt+shift right`, `/pingac reset`.
- The modifier must match exactly, so e.g. Ctrl + Alt + click stays free for Clique or other addons when Alt is selected.
- EllesmereUI support: action buttons and unit frames from other UIs are detected by their secure attributes instead of their names.

## 2.4.1
- Fixed: Alt + number keybinds on paged action bars (e.g. Dominos) were turned into pings instead of casting. Only real mouse clicks over the button ping now.

## 2.4
- New options panel in **Options → AddOns → PingAltClick**.
- New option **Same in combat** (enabled by default): Alt + Left Click on unit frames opens the radial ping wheel in combat too, through a secure state driver.
- `/pingalt debug` toggles a trace of the in-combat secure handler.
- The addon list now shows the real version number.

## 2.3
- Unit frames: Alt + hold click opens the radial ping wheel (out of combat).
- Unit frames use a target-less `/ping`, so the health bar sends "Health 100%" like the ping key.
- Action buttons (Blizzard and Bartender4/LibActionButton) can be pinged with Alt + Left Click.
- Compatible with Clique click-casting.
- World: Alt + Left Click is bound to the native ping action (`TOGGLEPINGLISTENER`).
- `/pingalt` diagnostics command.
- Addon icon.
