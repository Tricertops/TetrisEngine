Core of Tetris game
=============================

This framework contains logic for a simple Tetris game. Feel free to use it, build apps on top of it, sell them, and learn. It depends only on Foundation and doesn’t provide any graphical output.

###### What this framework does for you:
 - Stores **game state**, like cells on game board, falling blocks, time intervals, and score.
 - **Generates** next blocks with random shape and orientation, while avoiding simple repetition.
 - Manages **timer** that can be pauses and resumed.
 - Exposes **4 controls**: `moveLeft()`, `moveRight()`, `rotate()` and `drop()`.
 - Detects **completed lines** and increments score. Higher score speeds up the timer.
 - Reports all events via a **callback**, like periodic fall, line completion, game over, etc.
 - Allows **serialization** to and from a dictionary that is compatible with property list.

###### What you need to implement:
- **Graphics** and animations. Be creative!
- User **input**, like buttons or gestures.
- Write serialized dictionary to **persistent** location and restore it.
- Create game **menu** with play/pause/reset options.
- Listen to **callback** from the engine and update your UI.
- Show next block and **score** on screen.


---
The MIT License (MIT)  
Copyright © 2017 Martin Kiss
