"""
Callback for early stopping for an SB3 training run. Moved to its own
file so the custom training interface stays readable.

Reference:
- https://stable-baselines3.readthedocs.io/en/master/guide/callbacks.html
- https://stable-baselines3.readthedocs.io/en/md-doc/_modules/stable_baselines3/common/base_class.html
"""

# SB3 imports for callbacks
from stable_baselines3.common.callbacks import BaseCallback
from stable_baselines3.common.utils import safe_mean

class EarlyStopping(BaseCallback):
    """
    Stops training if the mean episode reward has not improved for "patience" timesteps.

    The mean reward is read from SB3's own episode buffer, so it is exactly the number
    TensorBoard shows as rollout/ep_rew_mean.
    """

    def __init__(self, patience, min_delta=0.0, check_freq=1000, min_episodes=10):
        """
        param patience: timesteps allowed without improvement before stopping
        param min_delta: how much the mean reward must increase to count as an improvement
        param check_freq: how often (in timesteps) to check for improvement
        param min_episides: do not judge anything until this many episodes have completed
        """
        super().__init__()
        self.patience = patience
        self.min_delta = min_delta
        self.check_freq = check_freq
        self.min_episodes = min_episodes

        self.best_reward = -float("-inf")  # Best mean reward for far
        self.best_step = 0                 # Timestep where the best reward happend
        self.last_check = 0                # Timestep of the last check

    def _on_step(self):
        """
        Called by SB3 after every environment step. Every "check_freq" timesteps
        it compares the current mean reward to the best one seen so far.

        return: True to keep training, False to stop
        """

        # Only check every "check_freq" timesteps
        if self.num_timesteps - self.last_check < self.check_freq :
            return True
        self.last_check = self.num_timesteps

        # Wait until the minimum number of episodes is reached
        episodes = self.model.ep_info_buffer
        if len(episodes) < self.min_episodes:
            return True

        # Claude Suggested: each entry is a dict from VecMonitor: "r" = reward, "l" = length
        mean_reward = safe_mean([ep["r"] for ep in episodes])

        # Case 1: improvement, set new best reward
        if mean_reward > self.best_reward + self.min_delta:
            self.best_reward = mean_reward
            self.best_step = self.num_timesteps

        # Case 2: no improvement for too long so stop training
        elif self.num_timesteps - self.best_step >= self.patience:
            print("Early stopping at timestep " + str(self.num_timesteps) +
                  ": mean reward has not improved since timestep " + str(self.best_step) +
                  " (best mean reward: " + str(self.best_reward) + ")")
            return False
        
        return True

        