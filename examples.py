import json
from copy import deepcopy
from pathlib import Path

from sumo_feedback import FullStateFeedback, make_state_space

path = Path(__file__).parent / "examples" / "sample_state.json"
with path.open(encoding="utf-8") as file:
    start_snapshot = json.load(file)

# 1. read an observation
feedback = FullStateFeedback(start_snapshot)
obs = feedback.observation("red")
print("red position:", obs["self"]["position"])
print("blue position:", obs["opponent"]["position"])
print("red in ring:", bool(obs["self"]["inside_ring"]))

# 2. gymnasium style (reset needs the step 0 snapshot)
obs, info = feedback.gymnasium_reset("red")
print("\nepisode:", info["episode_id"])

# pretend blue left the ring, so red won
end_snapshot = deepcopy(start_snapshot)
end_snapshot["step_id"] = 120
end_snapshot["elapsed_seconds"] = 2.0
end_snapshot["match"] = {"status": "terminated", "winner": "red", "end_reason": "ring_exit"}
end_snapshot["robots"]["blue"]["inside_ring"] = False

feedback = FullStateFeedback(end_snapshot)
obs = feedback.observation("red")
reward = 1.0 if obs["winner"] == 1 else -1.0 if obs["winner"] == 2 else 0.0
obs, reward, terminated, truncated, info = feedback.gymnasium_step("red", reward)
print("reward:", reward, "terminated:", terminated)

# 3. pettingzoo style, both robots
feedback = FullStateFeedback(start_snapshot)
observations, infos = feedback.pettingzoo_reset()
print("\nagents:", list(observations))

feedback = FullStateFeedback(end_snapshot)
observations, rewards, terms, truncs, infos = feedback.pettingzoo_step(
    {"red": 1.0, "blue": -1.0}
)
print("done:", terms)

# 4. flat state vector (red's view)
print("\nstate length:", len(feedback.state()), "space:", make_state_space().shape)
