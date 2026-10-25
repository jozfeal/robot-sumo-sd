import json
import sys
from pathlib import Path
from pprint import pprint

from sumo_feedback import FullStateFeedback

# use the sample unless a saved Godot JSON file is passed on the command line
path = Path(__file__).parent / "examples" / "sample_state.json"
if len(sys.argv) > 1:
    path = Path(sys.argv[1])

with path.open(encoding="utf-8") as file:
    feedback = FullStateFeedback(json.load(file))

for robot in ("red", "blue"):
    print(f"\n{robot}:")
    pprint(feedback.observation(robot), sort_dicts=False)

print("\nmatch:", feedback.info("red"))
