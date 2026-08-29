# Dynamic events

Server-wide interruptions. Some fire on a timer, some are purchasable
([monetisation](../game/monetization-stance.md)). Their job is to make the server feel inhabited and to
give everyone a shared thing to talk about.

## The eight (section 54)

| Event | What happens | Purchasable |
|---|---|---|
| **SCRAP RAIN** | hundreds of objects drop across the zone | ✅ |
| **GOLD RUSH** | high-value scrap replaces normal spawns | ✅ |
| **MAGNETIC STORM** | objects float; the world goes weightless | — |
| **CARGO DROP** | a large crate lands somewhere in the zone | — |
| **SECURITY FAILURE** | rare-part spawn rate rises sharply | — |
| **ROBOT BREAKOUT** | security robots enter zones they do not belong to | — |
| **HEAVY DELIVERY** | large industrial objects arrive | ✅ |
| **LEGENDARY SIGNAL** | one special part appears, announced server-wide | — |

## Factory Shifts are not events

A Shift is a ~12 minute **re-weighting** of the spawn pools, not an interruption:

**HEAVY** more heavy parts · **ELECTRIC** more power components · **GOLD** higher-value scrap ·
**SECURITY** more dangerous, better parts · **CHAOS** more world events.

Shifts change what the factory *is*. Events change what is *happening*. Keep them visually and
audibly distinct or players will conflate them.

## Rules

- An event must be **legible within three seconds** of arriving: a banner, a sound, and a visible change
  in the world. If a player has to check a menu to know an event is running, it failed.
- **Purchasable events benefit everyone on the server.** That is the entire reason they are the sellable
  ones. A purchasable event that only helps the buyer is pay-to-win with extra steps.
- An event must never invalidate a rare part someone is currently carrying. A Refresh retracts
  **unclaimed** parts only.
- Events stack badly. Cap concurrency at one non-Shift event at a time, except during a CHAOS Shift.

## Open

| Question | When |
|---|---|
| Event frequency on a quiet server — does a 3-player server get the same rate as a 20-player one? | before events ship |
| Does MAGNETIC STORM change the pull physics, or only the ambient float? The first is expensive | before it ships |
| Cooldown between purchased events, so one player cannot spam the server | before the first product is listed |
