"""
Action space wrapper that lets Discrete-only algoriths (like DQN)
drive an env with MultiDiscrete actions (Robot Sumo).

Moved to its own file so the custom training interface stays readable.
"""

import numpy as np
from gymnasium import spaces
from stable_baselines3.common.vec_env import VecEnvWrapper

class FlattenMultiDiscrete(VecEnvWrapper):

    def __init__(self, venv):
        """
        Remembers the size of each action dimension and advertises a single
        Discrete space with one action per combination.

        param venv: the vectorized env to wrap (must have a MultiDiscrete action space)
        """
        self.nvec = tuple(int(n) for n in venv.action_space.nvec)  # example: (3, 3)
        super().__init__(venv, action_space=spaces.Discrete(int(np.prod(self.nvec))))

    def step_async(self, actions):
        """
        Converts the flat action numbers into one (throttle, steering) pair per env, 
        then sends them to the real env.

        param actions: array of flat Discrete actions, one per env
        """
        multi_actions = np.stack(np.unravel_index(actions, self.nvec), axis=-1)
        self.venv.step_async(multi_actions)

    def step_wait(self):
        """
        Nothing to convert on the way back: observations, rewards and dones pass through.
        """
        return self.venv.step_wait()

    def reset(self):
        """
        Nothing to convert here either: just resets the wrapped env.
        """
        return self.venv.reset()
