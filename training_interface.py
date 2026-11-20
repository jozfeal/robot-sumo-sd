"""
Robot Sumo training interface (adapted from the Godot RL Agents SB3 example).

References:
- PPO Docs: https://stable-baselines3.readthedocs.io/en/master/modules/ppo.html
- A2C Docs: https://stable-baselines3.readthedocs.io/en/master/modules/a2c.html
- DQN Docs: https://stable-baselines3.readthedocs.io/en/master/modules/dqn.html
- TRPO Docs: https://sb3-contrib.readthedocs.io/en/master/modules/trpo.html
- VecMonitor: https://stable-baselines3.readthedocs.io/en/master/_modules/stable_baselines3/common/vec_env/vec_monitor.html
- Stable Baseline 3 Tutorials: https://stable-baselines3.readthedocs.io/en/master/guide/examples.html
"""

# Regular imports
import argparse
import os
import pathlib
import traceback
from typing import Callable

# Gymnasium imports: used to check the action space type
from gymnasium import spaces

# SB3 imports: algorithms
from sb3_contrib import TRPO
from stable_baselines3 import PPO, A2C, DQN

# SB3 imports: general usage
from stable_baselines3.common.callbacks import CheckpointCallback
from stable_baselines3.common.evaluation import evaluate_policy
from stable_baselines3.common.vec_env.vec_monitor import VecMonitor

# Early stopping callback
from early_stopping import EarlyStopping

# Multidiscrete flattening
from flatten_multidiscrete import FlattenMultiDiscrete

# Godot plugin related imports
from godot_rl.core.utils import can_import
from godot_rl.wrappers.onnx.stable_baselines_export import export_model_as_onnx
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv

# To download the env source and binary:
# 1.  gdrl.env_from_hub -r edbeeching/godot_rl_BallChase
# 2.  chmod +x examples/godot_rl_BallChase/bin/BallChase.x86_64
if can_import("ray"):
    print("WARNING, stable baselines and ray[rllib] are not compatible")

# Algorithm lookup table: lets us pick an algorithm using the command line
ALGORITHMS = {
    "ppo": PPO,
    "a2c": A2C,
    "trpo": TRPO,
    "dqn": DQN,
}


# -------------------- Section 1. Argument Parsing --------------------


def parse_arguments():
    """
    Configure and parse the command-line arguments for RL training

    returns: (parser, args) the parser and the parsed arguments
    """
    parser = argparse.ArgumentParser(allow_abbrev=False)

    # --env-path : path to the Godot executable used to run the environment.
    parser.add_argument(
        "--env_path",
        default=None,
        type=str,
        help="The Godot binary to use, do not include for in editor training",
    )

    # --experiment_dir : directory where experiment logs and checkpoints are stored.
    parser.add_argument(
        "--experiment_dir",
        default="logs/sb3",
        type=str,
        help="The name of the experiment directory, in which the tensorboard logs and checkpoints (if enabled) are "
        "getting stored.",
    )

    # -experiment_name : the name used to identify the experiment in TensorBoard and checkpoint files.
    parser.add_argument(
        "--experiment_name",
        default="experiment",
        type=str,
        help="The name of the experiment, which will be displayed in tensorboard and "
        "for checkpoint directory and name (if enabled).",
    )

    # --seed : the random seed of the experiment, used to keep results reproducible
    parser.add_argument(
        "--seed", 
        type=int, 
        default=0, 
        help="seed of the experiment"
    )

    # --resume_model_path : path to a previously saved model to resume training or perform inference.
    parser.add_argument(
        "--resume_model_path",
        default=None,
        type=str,
        help="The path to a model file previously saved using --save_model_path or a checkpoint saved using "
        "--save_checkpoints_frequency. Use this to resume training or infer from a saved model.",
    )

    # --save_model_path : destination path for saving the final trained model.
    parser.add_argument(
        "--save_model_path",
        default=None,
        type=str,
        help="The path to use for saving the trained sb3 model after training is complete. Saved model can be used later "
        "to resume training. Extension will be set to .zip",
    )

    # --save_checkpoint_frequency : the number of environment steps between checkpoint saves.
    parser.add_argument(
        "--save_checkpoint_frequency",
        default=None,
        type=int,
        help=(
            "If set, will save checkpoints every 'frequency' environment steps. "
            "Requires a unique --experiment_name or --experiment_dir for each run. "
            "Does not need --save_model_path to be set. "
        ),
    )

    # --onnx_export_path : destination path for exporting the trained model in ONNX format.
    parser.add_argument(
        "--onnx_export_path",
        default=None,
        type=str,
        help="If included, will export onnx file after training to the path specified.",
    )

    # --timesteps : total number of environment steps to execute during training or inference.
    parser.add_argument(
        "--timesteps",
        default=1_000_000,
        type=int,
        help="The number of environment steps to train for, default is 1_000_000. If resuming from a saved model, "
        "it will continue training for this amount of steps from the saved state without counting previously trained "
        "steps",
    )

    # --inference : runs a previously trained model without performing additional training.
    parser.add_argument(
        "--inference",
        default=False,
        action="store_true",
        help="Instead of training, it will run inference on a loaded model for --timesteps steps. "
        "Requires --resume_model_path to be set.",
    )

    # --linear_lr_schedule : gradually decreases the learning rate throughout training.
    parser.add_argument(
        "--linear_lr_schedule",
        default=False,
        action="store_true",
        help="Use a linear LR schedule for training. If set, learning rate will decrease until it reaches 0 at "
        "--timesteps"
        "value. Note: On resuming training, the schedule will reset. If disabled, constant LR will be used.",
    )

    # --viz : displays the Godot simulation in a window during training.
    parser.add_argument(
        "--viz",
        action="store_true",
        help="If set, the simulation will be displayed in a window during training. Otherwise "
        "training will run without rendering the simulation. This setting does not apply to in-editor training.",
        default=False,
    )

    # --speedup : controls the physics speed multiplier of the environment.
    parser.add_argument(
        "--speedup", 
        default=1, 
        type=int, 
        help="Whether to speed up the physics in the env"
    )

    # --action_repeat : number of physics frames between agent actions and observations.
    parser.add_argument(
        "--action_repeat",
        default=None,
        type=int,
        help="Similar concept to frame skip, sends action/gets obs every n frames only. Uses sync node setting if not set here.",
    )

    # --n_parallels : Number of environment instances running at once.
    parser.add_argument(
        "--n_parallel",
        default=1,
        type=int,
        help="How many instances of the environment executable to " "launch - requires --env_path to be set if > 1.",
    )

    # --learning_rate : step size used by the optimizer when updating the model.
    parser.add_argument(
        "--learning_rate", 
        default=0.0003, 
        type=float, 
        help="The learning rate (default 0.0003)"
    )

    # --n_steps : number of environment steps run per environment before each policy update.
    parser.add_argument(
        "--n_steps",
        default=64,
        type=int,
        help="Number of steps to run for each environment per update (default 64).",
    )

    # --batch_size : number of samples used in each minibatch during model updates.
    parser.add_argument(
        "--batch_size",
        default=64,
        type=int,
        help="The minibatch size (default 64). The rollout size = n_steps × n_envs must be divisible by batch_size without remainder",
    )

    # --ent_coef : controls how strongly the model is encouraged to explore through entropy.
    parser.add_argument(
        "--ent_coef", 
        default=0.0001, 
        type=float, 
        help="The entropy coefficient for the loss calculation (default 0.0001)"
    )

    # clip_range : maximum allowed policy update deviation used by PPO's clipping mechanism.
    parser.add_argument(
        "--clip_range",
        default=0.2,
        type=float,
        help="The clipping range (default 0.2). This limits the policy changes per update",
    )

    # --algorithm : selects the SB3 learning algorithm to use for training
    parser.add_argument(
        "--algorithm",
        default="ppo",
        choices=list(ALGORITHMS.keys()),
        help="Which SB3 algorithm to train with (default PPO). Available algorithms include PPO, A2C, TRPO, and DQN"
    )

    # --gamma : determines how much the agent values future rewards compared to immediate rewards
    parser.add_argument(
        "--gamma", 
        default=0.99, 
        type=float, 
        help="The discount factor (default 0.99)"
    )

    # --buffer_size : maximum number of past experiences stored for off-policy learning algorithms
    parser.add_argument(
        "--buffer_size",
        default=200_000,
        type=int,
        help="Only for DQN: size of the replay buffer (default 200_000)."
    )

    # --learning_starts: number of environment steps collected before off-policy training begins
    parser.add_argument(
        "--learning_starts",
        default=1_000,
        type=int,
        help="Only for DQN: steps collected before learning starts (default 1_000).",
    )

    # --early_stop_patience : stop training if the reward hasn't improved for this many timesteps
    parser.add_argument(
        "--early_stop_patience",
        default=0,
        type=int,
        help="If > 0, stop training when the mean episode reward has not improved for this many "
        "timesteps (default 0 = early stopping off).",
    )

    # --early_stop_min_delta : define how much the reward has to go up to count as an improvement
    parser.add_argument(
        "--early_stop_min_delta",
        default=0.0,
        type=float,
        help="Minimum increase in mean episode reward that counts as an improvement (default 0.0).",
    )

    args, extras = parser.parse_known_args()
    return parser, args

# Get the parsed arguments using the helper method
parser, args = parse_arguments()


# -------------------- Section 2. Saving Models, Handling Closing & Cleanup --------------------


def handle_onnx_export():
    """
    Exports the training model to an .onnx file so it can be loaded back into
    Godot or another visualization tool. Does nothing if --onnx_export_path was not given.
    """

    # Enforce the extension of onnx and zip when saving model to avoid potential conflicts in case of same name
    # and extension used for both
    if args.onnx_export_path is not None:
        path_onnx = pathlib.Path(args.onnx_export_path).with_suffix(".onnx")
        
        # Use try/except because exporter may not work for DQN
        try:
            print("Exporting ONNX to: " + os.path.abspath(path_onnx))
            export_model_as_onnx(model, str(path_onnx))
        
        except Exception as e:
            print("ONNX export failed for " + args.algorithm + ": ", e)
            traceback.print_exc() 

def handle_model_save():
    """
    Saves the trained model as a .zip file so training can be resumed later.
    Does nothing is --save_model_path was not given.
    """
    if args.save_model_path is not None:
        zip_save_path = pathlib.Path(args.save_model_path).with_suffix(".zip")  
        print("Saving model to: " + os.path.abspath(zip_save_path))
        model.save(zip_save_path)

def close_env():
    """
    Closes the Godot environment. Prints any errors.
    """
    try:
        print("closing env")
        env.close()

    except Exception as e:
        print("Exception while closing env: ", e)

def cleanup():
    """
    Runs everything that should happen when training ends.
    """
    handle_onnx_export()  # Export ONNX
    handle_model_save()   # Save the model (.zip file)  
    close_env()           # Close the environment


# -------------------- Section 3. Folder Set-Up, Environment Set-Up, Check Action Space --------------------


path_checkpoint = os.path.join(args.experiment_dir, args.experiment_name + "_checkpoints")
abs_path_checkpoint = os.path.abspath(path_checkpoint)

# Prevent overwriting existing checkpoints when starting a new experiment if checkpoint saving is enabled
if args.save_checkpoint_frequency is not None and os.path.isdir(path_checkpoint):
    raise RuntimeError(
        abs_path_checkpoint + " folder already exists. "
        "Use a different --experiment_dir, or --experiment_name,"
        "or if previous checkpoints are not needed anymore, "
        "remove the folder containing the checkpoints. "
    )

if args.inference and args.resume_model_path is None:
    raise parser.error("Using --inference requires --resume_model_path to be set.")

if args.env_path is None and args.viz:
    print("Info: Using --viz without --env_path set has no effect, in-editor training will always render.")

# Create the environment: used arguments defined above
env = StableBaselinesGodotEnv(
    env_path=args.env_path,
    show_window=args.viz,
    seed=args.seed,
    n_parallel=args.n_parallel,
    speedup=args.speedup,
    action_repeat=args.action_repeat,
)

# VecMonitor records data like episode reward, length, time etc.
env = VecMonitor(env)

# Robot Sumo should be MultiDiscrete: stop early if it isnt
if not isinstance(env.action_space, spaces.MultiDiscrete):
    close_env()
    raise ValueError("Expected MultiDiscrete actions but the env has: " + str(env.action_space))

# DQN needs a single Discrete action, so flatten MultiDiscrete
if args.algorithm == "dqn":
    env = FlattenMultiDiscrete(env)
print("Action space for " + args.algorithm + ": " + str(env.action_space))


# -------------------- Section 4. LR Schedule Implementation --------------------


# LR schedule code snippet from:
# https://stable-baselines3.readthedocs.io/en/master/guide/examples.html#learning-rate-schedule
def linear_schedule(initial_value: float) -> Callable[[float], float]:
    """
    Linear learning rate schedule.

    param initial_value: the initial learning rate.
    return: schedule that computes current learning rate depending on remaining progress
    """

    def func(progress_remaining: float) -> float:
        """
        Progress will decrease from 1 (beginning) to 0.

        param progress_remaining: how much training is left
        return: the current learning rate
        """
        return progress_remaining * initial_value

    return func


# -------------------- Section 5. Model Creation --------------------


def create_model(learning_rate):
    """
    Creates a new model for whichever algorithms --algorithms specifies.
    PPO is the default. 

    param learning_rate : constant learning rate, or the schedule function
    return: a new (untrained) SB3 model
    """

    # Case One: PPO model
    if args.algorithm == "ppo":
        return PPO(
            "MultiInputPolicy",
            env,
            ent_coef=args.ent_coef,
            verbose=2,
            n_steps=args.n_steps,
            tensorboard_log=args.experiment_dir,
            learning_rate=learning_rate,
            batch_size=args.batch_size,
            clip_range=args.clip_range,
            gamma=args.gamma
        )
    
    # Case Two: A2C model (no batch_size or clip_range)
    elif args.algorithm == "a2c":
        return A2C(
            "MultiInputPolicy",
            env,
            ent_coef=args.ent_coef,
            verbose=2,
            n_steps=args.n_steps,
            tensorboard_log=args.experiment_dir,
            learning_rate=learning_rate,
            gamma=args.gamma,
        )

    # Case Three: TRPO model
    elif args.algorithm == "trpo":
        return TRPO(
            "MultiInputPolicy",
            env,
            verbose=2,
            n_steps=args.n_steps,
            tensorboard_log=args.experiment_dir,
            learning_rate=learning_rate,
            batch_size=args.batch_size,
            gamma=args.gamma,
        )

    # Case Four: DQN model (off-policy)
    else:
        return DQN(
            "MultiInputPolicy",
            env,
            verbose=2,
            tensorboard_log=args.experiment_dir,
            learning_rate=learning_rate,
            batch_size=args.batch_size,
            buffer_size=args.buffer_size,
            learning_starts=args.learning_starts,
            gamma=args.gamma,
        )


# -------------------- Section 6. Evaluation --------------------


def evaluate_model(n_episodes):
    """
    Runs the trained model for n_episodes and prints the mean and standard deviation of the reward. 
    Uses the same env as training.

    param n_episodes: how many episodes to run
    return: mean reward, std of reward
    """

    # Get the mean reward and std reward using the evaluate_policy helper method
    mean_reward, std_reward = evaluate_policy(model, env, n_eval_episodes=n_episodes, deterministic=True)
    
    # Print the results
    print("Evaluation over " + str(n_episodes) + " episodes: " + str(mean_reward) + " +/- " + str(std_reward))
    return mean_reward, std_reward


# -------------------- Section 7. Running the Model --------------------


# Create the model (new or loaded from previous run)
if args.resume_model_path is None:
    learning_rate = args.learning_rate if not args.linear_lr_schedule else linear_schedule(args.learning_rate)
    model = create_model(learning_rate)
else:
    path_zip = pathlib.Path(args.resume_model_path)
    print("Loading model: " + os.path.abspath(path_zip))
    model = ALGORITHMS[args.algorithm].load(path_zip, env=env, tensorboard_log=args.experiment_dir)

# Inference handling: no training just run the loaded model
if args.inference:
    try:
        obs = env.reset()
        for i in range(args.timesteps):
            action, _state = model.predict(obs, deterministic=True)
            obs, reward, done, info = env.step(action)
    finally:
        handle_onnx_export()
        close_env()

# Training handling
else:
    callbacks = []

    # Early stopping (see early_stopping.py)
    if args.early_stop_patience > 0:
        print("Early stopping enabled: patient = " + str(args.early_stop_patience) + " timesteps")
        callbacks.append(
            EarlyStopping(
                patience=args.early_stop_patience,
                min_delta=args.early_stop_min_delta,
            )
        )

    # Periodic checkpoints
    if args.save_checkpoint_frequency:
        print("Checkpoint saving enabled. Checkpoints will be saved to: " + abs_path_checkpoint)
        callbacks.append(
            CheckpointCallback(
                save_freq=(args.save_checkpoint_frequency // env.num_envs),
                save_path=path_checkpoint,
                name_prefix=args.experiment_name,
            )
        )

    # Handling learning
    interrupted = False
    try:
        model.learn(total_timesteps=args.timesteps, tb_log_name=args.experiment_name, callback=callbacks)

    except (KeyboardInterrupt, ConnectionError, ConnectionResetError):
        interrupted = True  # remember this so we skip evaluation below
        print("""Training interrupted by user or a ConnectionError. Will save if --save_model_path was
            used and/or export if --onnx_export_path was used.""")

    finally:
        # Save and export right away, before anything slow (like evaluation) can get in the way
        cleanup()

    # Evaluate only after a full run (never after an interrupt), and always close the env at the end
    if interrupted:
        print("Training ended early.")
    else:
        print("Training completed.")