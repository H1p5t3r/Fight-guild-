# Match, training and development menus

The native game opens at **Main menu**. Applied move data remains in memory when changing modes; **Save locally** in Development persists it across launches. Backing out of fighter selection discards draft selections and preserves an existing round.

| Entry | Sequence | Tools and exit paths |
| --- | --- | --- |
| Versus / Local versus | Main menu → Versus → Local versus → Fighter select → Start match | Full-width arena; Esc/Start opens Resume, Restart round, Change fighters, Main menu. A completed round offers Rematch, Change fighters and Main menu. |
| Versus / Online versus | Main menu → Versus → Online versus → Local fighter select → Connection → Host or Join → Match | Opponent chooses their own fighter. Waiting exposes Cancel connection. Errors and disconnects return to the connection screen with the explanation and retained selection/address. Back cancels the connection and returns to fighter select, then Versus. |
| Training | Main menu → Training → Fighter and dummy select → Start training | Dummy behavior, starting Momentum, input history, hitboxes, pause, one-frame step and reset. No move editor. |
| Development | Main menu → Development → Fighter and dummy select → Open combat lab | Training tools plus move/buffer/Momentum editing, sprite review, import/export/save, unified gatling reference and rollback trial. The lab can also switch to local versus for testing. |

Each selection has its own simplified-input toggle; motion inputs remain available. Versus starts with zero Momentum regardless of the practice reset setting. Training and Development retain their dummy and starting-meter preferences for the session. Development defaults to visible hitboxes; Training and matches default to sprites without collision overlays.

Navigation supports mouse, arrows/Tab/Enter, and the controller D-pad/A. Esc/B goes back in menus. Esc/Start opens or closes the in-match menu. Home ignores Back; quitting is an explicit button. Focus moves to an enabled control on every menu entry. A held confirm or movement input must be released before combat accepts input after entry/resume.

Menu pages use interruptible 280 ms eased slides and crossfades; incoming navigation responds immediately. Outgoing controls cannot receive focus or clicks. Entering/resuming a match crossfades in 280 ms, with offline combat held until it completes. The home footer has a persistent **Motion: Full / Reduced** preference; reduced motion uses fades of at most 90 ms without translation. This setting affects presentation only.

Offline combat freezes during match transitions, while outside the play screen or while a modal dialog is open. Resume preserves the exact round, including a lab frame-step pause. A fighter-change cancellation returns to its originating screen and does not reset the round. Training/Development retain the manual Reset workflow when their round ends.

Online combat **continues with neutral local input** while its menu is open. Its menu explicitly says so and offers Resume or Leave match & main menu. A local restart or fighter change is unavailable during the connection. The results screen is shown only after the winner exists in a fully confirmed rollback state. It offers Return to online lobby; both players host/join again for another round. Negotiated rematches, matchmaking and reconnect remain backlog items.

`GameMenus` presents the pages and emits actions; `main.gd` owns transitions and simulation scheduling. `transition_verification.gd` exercises running transitions, rapid interruption, held-input isolation and reduced motion. `menu_verification.gd` exercises these paths in both the editable project and release package, including actual loopback ENet handshake/cancel/disconnect, keyboard and synthetic-controller navigation. Physical controller and Windows hardware testing remain separate.

Presentation follows the [Guild Ball menu style](menu-style.md). Headings and navigation stay fixed while bodies scroll. Controls has separate Player 1, Player 2 and Gamepad reference tabs and restores focus on close.
