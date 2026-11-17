# Character mechanic briefs · work in progress

Source: the user’s [2026-11-17 batch 2](move-batches/2026-11-17-batch-02.md), preserved in the workshop JSON. These are design requirements for a later implementation pass. Importing art-brief text does not create gameplay behavior.

## Shark — tether / Hooked!

- `5D` is a mid combo ender; `2D` is a low combo/blockstring ender. On hit, either attaches the opponent to a tether.
- The move becomes a follow-up pull, giving the opponent strong velocity toward Shark’s **current** position.
- Being hit breaks Shark’s tether.
- After the drag is used, a subsequent attack making contact on hit or block breaks the tether.

Before implementation, decide pull speed/duration, the follow-up input and availability, tether range/lifetime, which attacker’s subsequent contact consumes the tether, and behavior on whiff, knockdown, throws and wall travel. Keep the existing universal 2D hard-knockdown rule unless explicitly revised. This persistent Drive tether is distinct from the already implemented special-move hook pull.

## Fillet — bleed / Vein Ripper

- Initial `5D` is an overhead combo ender, unsafe on block, causing soft knockdown. Those properties are already set in the move data.
- On hit, it applies bleed and an initial grey-life amount affected by combo scaling. Bleed adds a small amount of grey life over time.
- While bleeding, blocked Fillet attacks add **20% of their on-hit damage** as grey life.
- While the debuff is active, this attack becomes a **leaping command grab** that cashes out accumulated grey life as damage.
- If Fillet is hit, the debuff ends and grey life is refunded.
- The debuff also ends and refunds grey life after **7 seconds without Fillet landing an unblocked hit**. Blocked attacks do not refresh that timer.
- Grey life cannot kill; it marks potential cash-out damage until the command grab connects.

Before implementation, decide the initial grey-life amount, tick amount/interval, scaling calculation, accumulation cap, command-grab timing/range/base damage, whether repeated applications stack or refresh, and whether hitstop pauses the seven-second timer. Clarify precisely how a failed cash-out attempt and round/wall transitions affect the stored amount. Preserve the distinction between grey-life bookkeeping and actual cash-out damage.

## Art direction received

Shark’s `5Hs` should strike down from overhead with his polearm, cover the front down to the ground, then drag the hook back into a small shoulder-rest flourish. The source JSON retains the exact active and recovery briefs. No new pose photos or completed animation sheets are supplied in this batch.
