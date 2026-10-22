# Robot Sumo feedback

Open `godot-project/project.godot` in Godot 4.7.2 and run it.
Blue: WASD. Red: arrow keys. R: restart. P: save `sumo_state.json`.
The Output panel shows where the file was saved.

To use this in your checkout, copy these files from `godot-project/`:

- `system/full_state_feedback.gd`
- `system/simulation_manager.gd`
- `system/ring_area.gd`

In Project Settings > Input Map, add `save_feedback` and bind it to P.
The last match result stays available until R.

## Python

```bash
python -m pip install -r requirements.txt
python show_feedback.py
python show_feedback.py /path/to/sumo_state.json
```

```python
from sumo_feedback import FullStateFeedback

feedback = FullStateFeedback(snapshot)
gym_result = feedback.gymnasium_step("red", red_reward)
parallel_result = feedback.pettingzoo_step({"red": red_reward, "blue": blue_reward})
```

Godot: `SimulationManager.feedback.get_state()` returns the snapshot.
For reset data, read it before physics starts and use `gymnasium_reset("red")`
or `pettingzoo_reset()`. Restart the scene separately.

Each observation has `self` and `opponent`, with position, rotation, velocities,
steering, engine force, brake and ring status. Rotation uses `[x, y, z, w]`;
steering uses radians. Time is in simulation seconds.

- Status: 0 running, 1 terminated, 2 truncated.
- Winner: 0 none, 1 self, 2 opponent.
- Spaces: `make_observation_space()` and `make_state_space()`.
- `state()`: flat array, fixed red/blue order.

TODO: live Python connection and rewards.
