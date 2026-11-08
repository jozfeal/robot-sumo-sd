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
py training_interface.py --env_path="simulation.exe" --n_parallel=4 --speedup=10 --timesteps=1000000 --experiment_name="name"
```
There are additional command line arguments to save training checkpoints and other utilities which have not been fully implemented yet, so training will currently just run until `timesteps` is reached or when it is stopped with `Ctrl + C`. All parameter values can be changed. To visually see training, you can add an additional command line parameter, `--viz`, which removes headless mode for the simulation. When visualizing training, it is better to run only one instance of the simulation:
```
py training_interface.py --env_path="simulation.exe" --n_parallel=1 --speedup=10 --timesteps=1000000 --experiment_name="name" --viz
```
