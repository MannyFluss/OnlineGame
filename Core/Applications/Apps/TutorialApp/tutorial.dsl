# tutorial.dsl - Sample tutorial timeline

:start
cmd message tutorial_face smile
cmd message tutorial Hello! Welcome to the tutorial.
cmd message tutorial_player [Press SPACE to continue]
wait_input space

cmd message tutorial You pressed space! Great job.
cmd message tutorial_player
wait_time 1.0

cmd observe
cmd play song1.tres
cmd message tutorial_face neutral
cmd message tutorial Press space again to continue...
cmd message tutorial_player [Press SPACE to continue]
wait_input space

cmd message tutorial_face smile
cmd message tutorial Excellent! You're getting the hang of this.
cmd message tutorial_player [Press SPACE to continue]
wait_input space

cmd message tutorial One more time...
cmd message tutorial_player [Press SPACE to continue]
wait_input space

:end
cmd message tutorial_face neutral
cmd message tutorial Tutorial complete. Thanks for playing!
cmd message tutorial_player
wait_time 2.0
