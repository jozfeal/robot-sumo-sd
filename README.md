# robot-sumo-sd
https://jozfeal.github.io/robot-sumo-sd/

Website Code Files (HTML):
- about.html
- index.html

# Godot
This project uses Godot version 4.7.2

# VENV Setup
To perform training using the `training_interface.py`, you first need an environment.
Each person should create their own custom environment locally inside the resository folder, and it will be ignored by `.gitignore`.

First, ensure you have Python 3.11 installed. If you do not have it, you can install with this command:
```
winget install -e --id Python.Python.3.11
```

To create the environment, run the following commands inside the repository folder locally:
```
py -3.11 -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip
python -m pip install godot-rl
```

# Godot Simulation
Whenever a change is made in the Godot Simulation, you can test the changes by running the training interface and using the default play button in the editor.
To perform headless training or to speedup testing, a build of the simulation must be exported. To export a build with your changes, save the project then click: 
`Project -> Export -> Export Project -> Save`. Make sure "Export With Debug" is unchecked.

# Training
To perform a training run, navigate to the folder repository and activate the VENV with:
```
.venv\Scripts\Activate
```
Once the VENV is active, you can run `training_interface.py` to start a training run. If testing with the Godot editor, simply run the command below and press Play in the Godot editor.
```
py training_terface.py
```
To perform a headless training run, first make sure the latest version of the simulation is exported. You can run the training with:
```
py training_interface.py --env_path=simulation.exe --n_parallel=4 --speedup=10 --timesteps=1000000
```
There are additional command line arguments to save training checkpoints and other utilities which have not been fully implemented yet, so training will currently just run until `timesteps` is reached or when it is stopped with `Ctrl + C`. All parameter values can be changed. To visually see training, you can add an additional command line parameter, `--viz`, which removes headless mode for the simulation. When visualizing training, it is better to run only one instance of the simulation:
```
py training_interface.py --env_path=simulation.exe --n_parallel=1 --speedup=10 --timesteps=1000000 --viz
```

# Saving Progress and Exporting Models
To make checkpoints during training, the experiment name must be unique. One can use an automatically generated experiment name or name the experiment with the `experiment_name=name` argument. If a folder with the experiment name already exists, `training_interface.py` will throw an error. Ensure the experiment name is unique and/or that the previous folder with that name has been deleted before running a training experiment.

## Saving the Model
When running `training_interface.py`, the following arguments can be added to save and resume model training progress.
- `--save_model_path=model.zip` determines the .zip folder under which the model is saved. Including this argument ensures a final checkpoint is created at the end of training or when training is stopped with `Ctrl + C`.
- `--save_checkpoint_frequency=50_000` will save an instance of the model after every 50,000 timesteps.
- `--resume_model_path=model.zip` will run a new training experiment by loading the model in the .zip directory and resuming with its current weights / structure. A model can be loaded for testing and ran with the `--inference` argument to prevent its weights from updating.

## Exporting the Model
One can export the model in ONNX format for other uses, such as visualization or testing. An ONNX model path can also be passed as an argument in Godot's Sync node to test an already trained model inside the Godot editor. Exporting to ONNX will only occur once training completes by reaching its maximum timesteps or when training is stopped with `Ctrl + C`. To export the ONNX model, simply add the argument `--onnx_export_path=model.onnx`.
