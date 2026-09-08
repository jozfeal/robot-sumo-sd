import math
from robot import Robot

# Method provided by Claude AI to keep the robots from overlapping
def push_apart(a: Robot, b: Robot):
    dx = b.x - a.x
    dy = b.y - a.y
    dist = math.hypot(dx, dy)
    min_dist = (a.size + b.size) / 2

    # Avoid divide-by-zero if perfectly overlapped
    if dist == 0:
        dx, dy, dist = 1, 0, 1
 
    if dist < min_dist:
        overlap = min_dist - dist
        nx, ny = dx / dist, dy / dist

        # Push each robot away by half the overlap.
        # Whoever is "actively moving into" the other effectively wins
        # the push since their velocity keeps re-adding overlap next frame.
        a.x -= nx * overlap / 2
        a.y -= ny * overlap / 2
        b.x += nx * overlap / 2
        b.y += ny * overlap / 2