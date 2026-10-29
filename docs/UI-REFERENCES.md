# Focus UI references and decisions (2026-10-28)

Official sources reviewed:
- Pomofocus: https://pomofocus.io/ describes selecting a task, focusing for a chosen interval, and reviewing completed work.
- Focus To-Do: https://www.focustodo.cn/ combines task organization with a Pomodoro timer and historical statistics.
- Forest: https://www.forestapp.cc/ presents visible accumulated progress as a focus reward.

Design decisions are our interpretation of these workflows, not a claim that their exact screens have been reproduced. Keep the task and countdown together, expose one primary action (Start when idle, Pause/Resume when running), keep duration choices secondary, and preserve ship growth as the visible reward. The game retains its own no missed-day penalty policy. Asteroid contacts do not remove study rewards.

The revised dock is compact, uses plain ASCII status separators, and rejects empty or whitespace-only task titles in the authoritative Game logic as well as the UI. Unlabeled legacy checkpoints require a task before resume. Shop and Robot modes hide the dock while the same session continues. Their fixed preview and independently scrolling upgrade sidebar replace the former page-long card grid.

Steady instrument lights are the default. Diagnostic bars no longer animate rapidly. There are no animated selection borders. The optional steady-light setting is separate from the gentle cruise scenery.

Headless font metrics differ from normal rendered font metrics on this machine; layout checks bound the dock against both the normal height target and the active font's measured line height. Actual appearance and motion comfort need user review, since visible launches are not authorized.