import pygame
import sys
import physics
import math
from robot import Robot

# Pygame Setup
pygame.init()
SCREEN_W, SCREEN_H = 1600, 900
screen = pygame.display.set_mode((SCREEN_W, SCREEN_H))
pygame.display.set_caption("Robot Sumo Wrestling - Pygame Demo")
clock = pygame.time.Clock()
FPS = 60
FONT = pygame.font.SysFont("arial", 48, bold=True)

# Ring properties
RING_CENTER = (SCREEN_W // 2, SCREEN_H // 2)
RING_RADIUS = 400

# RGB values for used colors
WHITE = (255, 255, 255)
BLACK = (20, 20, 20)
BLUE = (60, 120, 230)
RED = (220, 70, 70)

# Initialize robots
robots = [Robot("Blue", RING_CENTER[0], RING_CENTER[1] + 200, BLUE), Robot("Red", RING_CENTER[0], RING_CENTER[1] - 200, RED, angle=180)]
valid_robots= robots.copy()


# Check if a robot has left the ring and display winning text if one robot is left
def check_loss_condition(robot: Robot):
    if robot in valid_robots and math.hypot(robot.x - RING_CENTER[0], robot.y - RING_CENTER[1]) > RING_RADIUS:
        valid_robots.remove(robot)

    if len(valid_robots) == 1:
        text_surf = FONT.render(f"{valid_robots[0].robot_name} wins!", True, valid_robots[0].color)
        rect = text_surf.get_rect(center=(SCREEN_W // 2, SCREEN_H // 2))
        screen.blit(text_surf, rect)

# Main game loop
running = True
while running:
    # Checks for window being closed
    for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

    # Draw background first
    screen.fill(BLACK)
    pygame.draw.circle(screen, WHITE, RING_CENTER, RING_RADIUS, width=15)
    
    # Get input from player
    keys = pygame.key.get_pressed()
    forward = (keys[pygame.K_w]) - (keys[pygame.K_s])   # 1, -1, or 0 if both/neither pressed
    turn = (keys[pygame.K_d]) - (keys[pygame.K_a])       # 1, -1, or 0 if both/neither pressed
    robots[0].move_input(forward, turn)

    physics.push_apart(robots[0], robots[1])
    check_loss_condition(robots[0])
    check_loss_condition(robots[1])

    # Update robot positions on screen
    robots[0].draw(screen)
    robots[1].draw(screen)

    # Redraws screen and continues game
    pygame.display.flip()
    clock.tick(FPS)

pygame.quit()
sys.exit()

