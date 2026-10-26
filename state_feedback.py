"""
state_feedback file. Simple class that holds
the information that Godot reports.

feedback = [winner, agent_dict, opponent_dict, ...]

feedback[0] =
    -1 if match is ongoing.
    0 if match ended in draw.
    >0 if there was a winner. Number corresponds to index of winner inside the feedback list.
feedback[1] = dictionary for state of the agent's robot.
feedback[2+] = dictionary for state of the other robots in the match.
Note: If the agent won, feedback[0] = 1. Otherwise, feedback[0] = 2+.

The state of each robot is a dictionary following this structure:
"active" = true / false
"position" = Vector3(x, y, z)
"rotation" = Vector3(x, y, z)
"engine_force" = float
"steering" = float
"linear_velocity" = Vector3(x, y, z)
"angular_velocity" = Vector3(x, y, z)

TODO(connection): Godots Vector3 will have to get here [x, y, z], converting Godot types
to Python will be the connections job.
"""

def to_vector3(value):
    """
    Helper method, converts three numbers into a tuple of floats.
    Will be used to process Godots vectors (Vector3).

    param value: [x, y, z]
    return: (x, y, z) as floats
    """
    x, y, z = value
    return(float(x), float(y), float(z))


class RobotState:
    """
    This class defines the state of one robot, built from the 
    dictionaries returned by the Godot simulation
    """

    def __init__(self, data):
        """
        param data: one robot's dictionary from Godot
        return: None
        """
        self.active = bool(data["active"])
        self.position = to_vector3(data["position"])
        self.rotation = to_vector3(data["rotation"])
        self.engine_force = float(data["engine_force"])
        self.steering = float(data["steering"])
        self.linear_velocity = to_vector3(data["linear_velocity"])
        self.angular_velocity = to_vector3(data["angular_velocity"])


class StateFeedback:
    """
    Defines the match state at one moment, built from Godots feedback
    list. 
    """

    def __init__(self, feedback):
        """
        param feedback: [winner, agent_dict, opponent_dict, ...]
        return: None
        """

        # Check: check that the feedback data is as expected, need the winner, agent, one other robot
        if len(feedback) < 3:
            raise ValueError("feedback needs [winner, agent, other robot]")

        # Get the winner code value
        self.winner = int(feedback[0])

        # Create one RobotState per robot dictionary provided
        self.robots = []
        for data in feedback[1:]:
            self.robots.append(RobotState(data))

        # Check: winning conditions fit the expected framework
        if self.winner < -1 or self.winner > len(self.robots):
            raise ValueError("winner code does not fit robots given")

        # Baseline Implementation: define the agent and the first opponent
        self.agent = self.robots[0]
        self.opponent = self.robots[1]

        # Winner codes
        self.match_over = self.winner != -1    # Match ongoing = -1
        self.draw = self.winner == 0           # Match ended in draw = 0
        self.agent_won = self.winner == 1      # Agent is the winner = 1
        self.agent_lost = self.winner >= 2     # Opponent is the winner = 2+
