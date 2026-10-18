# Store listing

Generated from the real app — every screenshot in `docs/store/` is a capture of
the shipping build on a physical device, not a mockup.

## Title

Quiet Places — automatic quiet places

## Short description (80 char max)

`Your phone goes quiet where it should, and back to normal when you leave.`

(73 characters.)

## Full description

**Your phone should already know to be quiet at the cinema.**

Save the places where your phone should hush — a cinema, an office, a bedroom,
a lecture hall. Quiet Places switches to silent, vibrate or Do Not Disturb when
you arrive, and puts your ringer back exactly as you had it when you leave.

**It restores what you had, not what it guessed.**
Quiet Places records your ringer state before it changes anything. Leave a Quiet
Place and you get that state back — not a blanket "normal". If you change your
ringer yourself while you're there, it takes the hint and stops managing it.
It won't fight you.

**Always know where you stand.**
Every Quiet Place shows the exact distance to its centre and which side of the
boundary you're on — "5 m · inside by 95 m". When GPS accuracy is too poor to
be sure, it says so instead of showing you a confident number it can't back up.

**Draw the boundary on a real map.**
Drag the pin, drag the edge to resize, long-press to drop a new one. It warns
you when two Quiet Places overlap and tells you which setting wins.

**Offline by default.**
Your Quiet Places, their names and your history never leave your phone. There
is no account, no analytics and no crash reporting. Maps are opt-in, and until
you turn them on the app makes no network requests at all — when you do, it
tells you plainly what gets sent and what that reveals.

**Built for the way phones actually work.**
Uses the operating system's own geofencing rather than polling your location,
so it costs a fraction of a percent of battery per hour. Survives a reboot.
Keeps working with the app closed.

---

### A note on iPhone

Apple provides no way for an app to change your ringer. On iOS, Quiet Places
notifies you when you arrive so you can do it yourself, and shows you how to set
up a Shortcuts Focus automation for a hands-free equivalent. We'd rather say
that here than have you find out after installing.

### Permissions, and why

- **Location, all the time** — Quiet Places can only fire in the background with
  all-the-time access. Without it, silencing works only while the app is open.
- **Do Not Disturb access** — required by Android to change silent/DND modes.
- **Notifications** — to tell you the moment your ringer changed.
- **Internet** — map tiles only, and only if you turn maps on.

## Screenshots

| File | Shows |
|---|---|
| `home.png` | Live distance to every Quiet Place, inside/outside at a glance |
| `editor.png` | The map editor: drag the pin, drag the edge, overlap warning |
| `moment.png` | The confirmation shown the moment your phone goes quiet |
| `history.png` | Why it fired — or why it didn't |
| `consent.png` | The opt-in map gate, stating exactly what leaves the device |
| `settings.png` | Pause, snooze, units, map cache |

## Things a reviewer will ask

- **Why background location?** Geofence transitions are delivered by the OS
  while the app is closed; that is the entire feature.
- **Why the foreground service type `location`?** Only to complete a ringer
  change started from a geofence callback on Android 14+. There is no persistent
  foreground service and no ongoing notification.
- **What is sent to OpenStreetMap?** Tile requests, and search text if the user
  searches. Nothing else, and only when maps are enabled. A User-Agent naming
  the app is sent as their usage policy requires, and requests are rate-limited.
