<p align="center"><img src="assets/icon.png" width="160" alt="PingAltClick"></p>

# PingAltClick

> 🤖 **Este addon ha sido íntegramente _vibe-coded_** con [Claude Code](https://claude.com/claude-code). Funciona y se ha probado en el juego, pero tenlo en cuenta.
>
> 🤖 **This addon was entirely _vibe-coded_** with [Claude Code](https://claude.com/claude-code). It works and has been tested in-game, but keep that in mind.

**[Español](#español) · [English](#english)**

---

## Español

Usa el **sistema de pings normal de Blizzard con Alt + clic izquierdo**, sin tener que llevar la mano a la tecla de ping. Hecho para **WoW: Forever**.

### Qué hace

| Dónde | Alt + clic rápido | Alt + clic mantenido |
|---|---|---|
| **Mundo** (unidades, objetos, suelo) | Ping contextual | Rueda radial (Atacar, Advertencia, En camino, Ayuda) |
| **Marcos de unidad** (tú, objetivo, foco, grupo, banda) | Ping contextual ("Salud 100%" sobre la barra de vida, unidad sobre el retrato) | Rueda radial *(también en combate, configurable)* |
| **Botones de acción** (Blizzard y Bartender4) | Ping de la habilidad u objeto | — |

Es el mismo sistema que la tecla de ping del juego: el resultado es idéntico al de pulsarla con el cursor en el mismo sitio. Tu tecla de ping sigue funcionando.

### Instalación

1. Descarga el addon desde CurseForge o desde las *releases* de GitHub.
2. Copia la carpeta `PingAltClick` en la carpeta `Interface/AddOns/` de tu instalación de WoW: Forever.
3. Reinicia el juego.

No necesita configuración.

### Opciones

En **Opciones → AddOns → PingAltClick**:

- **Igual en combate** *(activada por defecto)*: Alt + clic izquierdo en los marcos de unidad funciona igual dentro y fuera de combate, con rueda radial incluida. Si la desactivas, en combate solo hace ping contextual sobre los marcos de unidad.

### Comandos

- `/pingalt` — diagnóstico. Pon el ratón sobre un botón o marco, escribe el comando y te dice qué elemento recibe el clic, si está enganchado y cómo está configurado el sistema de pings.
- `/pingalt debug` — activa o desactiva una traza del modo seguro en combate (fuera de combate).

### Cómo funciona y limitaciones

- La función que activa la tecla de ping (`C_Ping.TogglePingListener`) está restringida, así que el addon asigna la acción de ping (`TOGGLEPINGLISTENER`) a `ALT-BUTTON1` con un *override binding*.
- Fuerza el modo de ping **"Mantener tecla"** (`pingMode = 0`): pulsación corta = ping contextual, mantener = rueda. También afecta a tu tecla de ping normal.
- Los clics sobre la interfaz no llegan a las asignaciones de teclas:
  - En **botones de acción y marcos de unidad** se envuelve el clic con un fragmento seguro que, con Alt + clic izquierdo, ejecuta `/ping` sin objetivo, que hace exactamente lo mismo que la tecla de ping sobre ese elemento. Compatible con **Bartender4** y **Clique**.
  - En los **marcos de unidad**, mientras mantienes Alt se desactivan sus clics, así que el clic cae al mundo y se abre el sistema de ping completo, rueda incluida. Fuera de combate solo se desactivan los clics (no el movimiento del ratón). **En combate** eso está bloqueado, así que con la opción *Igual en combate* un controlador de estado seguro desactiva el ratón del marco por completo mientras Alt está pulsado (durante ese momento el marco no muestra su tooltip).
- Alt + clic izquierdo en un botón de acción ya no lanza la habilidad sobre ti mismo (*self-cast*); Alt + tecla de atajo sí.
- Con Alt pulsado, el clic derecho sobre un marco de unidad tampoco abre su menú.

---

## English

Use **Blizzard's regular ping system with Alt + Left Click**, no need to reach for the ping key. Made for **WoW: Forever**.

### What it does

| Where | Alt + quick click | Alt + hold click |
|---|---|---|
| **World** (units, objects, ground) | Contextual ping | Radial wheel (Attack, Warning, On My Way, Assist) |
| **Unit frames** (player, target, focus, party, raid) | Contextual ping ("Health 100%" on the health bar, unit on the portrait) | Radial wheel *(in combat too, configurable)* |
| **Action buttons** (Blizzard and Bartender4) | Spell / item ping | — |

It's the very same system as the game's ping key: the result is identical to pressing it with the cursor in the same spot. Your ping key keeps working.

### Installation

1. Download from CurseForge or from the GitHub releases.
2. Copy the `PingAltClick` folder into the `Interface/AddOns/` folder of your WoW: Forever install.
3. Restart the game.

No configuration needed.

### Options

In **Options → AddOns → PingAltClick**:

- **Same in combat** *(enabled by default)*: Alt + Left Click on unit frames works the same in and out of combat, radial wheel included. When disabled, in combat it only sends a contextual ping on unit frames.

### Commands

- `/pingalt` — diagnostics. Hover a button or frame and run it to see which element receives the click, whether it is hooked, and the ping system settings.
- `/pingalt debug` — toggles a trace of the in-combat secure handler (out of combat).

### How it works & limitations

- The function behind the ping key (`C_Ping.TogglePingListener`) is restricted, so the addon binds the ping action (`TOGGLEPINGLISTENER`) to `ALT-BUTTON1` via an override binding.
- It forces the **"Key Down"** ping mode (`pingMode = 0`): short press = contextual ping, hold = wheel. This also applies to your regular ping key.
- UI clicks don't reach key bindings:
  - On **action buttons and unit frames**, the click is wrapped with a secure snippet that, on Alt + Left Click, runs a target-less `/ping`, which does exactly what the ping key does on that element. Works with **Bartender4** and **Clique**.
  - On **unit frames**, while Alt is held their clicks are disabled, so the click falls through to the world and the full ping system opens, wheel included. Out of combat only clicks are disabled (mouse motion is not). **In combat** that is blocked, so with the *Same in combat* option a secure state driver disables the frame's mouse entirely while Alt is held (the frame shows no tooltip meanwhile).
- Alt + Left Click on an action button no longer self-casts; Alt + keybind still does.
- While Alt is held, right-clicking a unit frame won't open its menu either.

---

## Licencia / License

[MIT](LICENSE)
