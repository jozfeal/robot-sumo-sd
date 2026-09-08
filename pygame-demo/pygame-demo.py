import pygame

# Pygame Setup
pygame.init()
SCREEN_W, SCREEN_H = 1600, 900
screen = pygame.display.set_mode((SCREEN_W, SCREEN_H))
pygame.display.set_caption("Robot Sumo Wrestling - Pygame Demo")
clock = pygame.time.Clock()
FPS = 60
