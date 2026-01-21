# tutorial.dsl - Sample tutorial timeline

:start
emit set_face smile
emit output_text "Hello! Welcome to the tutorial."
wait_input space

emit output_text "You pressed space! Great job."
wait_time 1.0

cmd observe
cmd play song1.tres
emit set_face neutral
emit output_text "Press space again to continue..."
wait_input space

emit set_face smile
emit output_text "Excellent! You're getting the hang of this."
wait_input space

emit output_text "One more time..."
wait_input space

:end
emit set_face neutral
emit output_text "Tutorial complete. Thanks for playing!"
wait_time 2.0
