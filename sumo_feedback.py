"""Robot state -> RL observations."""

from copy import deepcopy

import numpy as np
from gymnasium import spaces

AGENTS = ("red", "blue")
STATUS_CODES = {"running": 0, "terminated": 1, "truncated": 2}


def make_observation_space():
    def robot_space():
        return spaces.Dict({
            "position": spaces.Box(-np.inf, np.inf, (3,), np.float32),
            "rotation": spaces.Box(-1.0, 1.0, (4,), np.float32),
            "linear_velocity": spaces.Box(-np.inf, np.inf, (3,), np.float32),
            "angular_velocity": spaces.Box(-np.inf, np.inf, (3,), np.float32),
            "steering": spaces.Box(-np.inf, np.inf, (1,), np.float32),
            "engine_force": spaces.Box(-np.inf, np.inf, (1,), np.float32),
            "brake": spaces.Box(0.0, np.inf, (1,), np.float32),
            "inside_ring": spaces.Discrete(2),
        })

    return spaces.Dict({
        "self": robot_space(),
        "opponent": robot_space(),
        "elapsed_seconds": spaces.Box(0.0, np.inf, (1,), np.float32),
        "status": spaces.Discrete(3),
        "winner": spaces.Discrete(3),  # none, self, opponent
    })


def make_state_space():
    flat = spaces.flatten_space(make_observation_space())
    return spaces.Box(
        flat.low.astype(np.float32), flat.high.astype(np.float32),
        dtype=np.float32,
    )


class FullStateFeedback:
    def __init__(self, snapshot):
        self._snapshot = deepcopy(snapshot)
        if snapshot["schema_version"] != 2:
            raise ValueError("expected a version 2 snapshot from this project")
        if set(snapshot["robots"]) != set(AGENTS):
            raise ValueError("need both robots here")
        if snapshot["match"]["winner"] not in (None, *AGENTS):
            raise ValueError(f"unexpected winner: {snapshot['match']['winner']!r}")
        self._space = make_observation_space()
        for agent in AGENTS:
            if not self._space.contains(self.observation(agent)):
                raise ValueError(f"bad observation for {agent}")

    def observation(self, agent):
        self._check_agent(agent)
        opponent = "blue" if agent == "red" else "red"
        match = self._snapshot["match"]
        winner = match["winner"]
        return {
            "self": self._read_robot(agent),
            "opponent": self._read_robot(opponent),
            "elapsed_seconds": np.array(
                [self._snapshot["elapsed_seconds"]], dtype=np.float32
            ),
            "status": STATUS_CODES[match["status"]],
            "winner": 0 if winner is None else (1 if winner == agent else 2),
        }

    def state(self):
        # fixed red / blue order
        return spaces.flatten(
            self._space, self.observation("red")
        ).astype(np.float32)

    def info(self, agent):
        self._check_agent(agent)
        state = self._snapshot
        return {
            "agent": agent,
            "schema_version": state["schema_version"],
            "episode_id": state["episode_id"],
            "step_id": state["step_id"],
            "match_status": state["match"]["status"],
            "winner": state["match"]["winner"],
            "end_reason": state["match"]["end_reason"],
        }

    def gymnasium_reset(self, agent="red"):
        self._check_reset()
        return self.observation(agent), self.info(agent)

    def gymnasium_step(self, agent, reward):
        reward = float(reward)
        if not np.isfinite(reward):
            raise ValueError("reward is NaN or inf")
        terminated, truncated = self._end_flags()
        return (
            self.observation(agent), reward, terminated, truncated,
            self.info(agent),
        )

    def pettingzoo_reset(self):
        self._check_reset()
        return (
            {agent: self.observation(agent) for agent in AGENTS},
            {agent: self.info(agent) for agent in AGENTS},
        )

    def pettingzoo_step(self, rewards):
        if set(rewards) != set(AGENTS):
            raise ValueError("rewards need red and blue")
        rewards = {agent: float(rewards[agent]) for agent in AGENTS}
        if not all(np.isfinite(value) for value in rewards.values()):
            raise ValueError("check rewards: NaN/inf")
        terminated, truncated = self._end_flags()
        # both done, winner included
        return (
            {agent: self.observation(agent) for agent in AGENTS},
            rewards,
            {agent: terminated for agent in AGENTS},
            {agent: truncated for agent in AGENTS},
            {agent: self.info(agent) for agent in AGENTS},
        )

    def _read_robot(self, agent):
        robot = self._snapshot["robots"][agent]
        return {
            "position": np.array(robot["position"], dtype=np.float32),
            "rotation": np.array(robot["rotation"], dtype=np.float32),
            "linear_velocity": np.array(robot["linear_velocity"], dtype=np.float32),
            "angular_velocity": np.array(robot["angular_velocity"], dtype=np.float32),
            "steering": np.array([robot["steering"]], dtype=np.float32),
            "engine_force": np.array([robot["engine_force"]], dtype=np.float32),
            "brake": np.array([robot["brake"]], dtype=np.float32),
            "inside_ring": int(robot["inside_ring"]),
        }

    def _end_flags(self):
        status = self._snapshot["match"]["status"]
        return status == "terminated", status == "truncated"

    def _check_reset(self):
        state = self._snapshot
        if (state["step_id"] != 0 or state["elapsed_seconds"] != 0
                or state["match"]["status"] != "running"):
            raise ValueError("reset needs the initial snapshot, before physics runs")

    @staticmethod
    def _check_agent(agent):
        if agent not in AGENTS:
            raise ValueError(f"Unknown robot: {agent}")
