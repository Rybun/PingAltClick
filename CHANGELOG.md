# Changelog

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
