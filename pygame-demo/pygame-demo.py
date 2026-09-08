import pygame
import sys

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

# Main game loop
running = True
while running:
    # Checks for window being closed
    for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

    # Black background with white ring
    screen.fill(BLACK)
    pygame.draw.circle(screen, WHITE, RING_CENTER, RING_RADIUS, width=15)

    # Redraws screen and continues game
    pygame.display.flip()
    clock.tick(FPS)

pygame.quit()
sys.exit()
