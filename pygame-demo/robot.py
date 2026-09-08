import pygame
import math

# Robot class used for representing the robots in space
class Robot:
    def __init__(self, robot_name, x, y, color, size=80, angle=0, speed=8, turn_speed = 6):
        self.robot_name = robot_name
        self.x = x
        self.y = y
        self.angle = angle
        self.color = color
        self.size = size
        self.speed = speed
        self.turn_speed = turn_speed

    # Returns the positional rectangle this robot occupies
    def rect(self):
        return pygame.Rect(self.x - self.size / 2, self.y - self.size / 2, self.size, self.size)

    # Displays robot on screen with its position and rotation
    def draw(self, surf):
        # Rotate a square surface to match self.angle so you can see facing direction
        base = pygame.Surface((self.size, self.size), pygame.SRCALPHA)
        pygame.draw.rect(base, self.color, base.get_rect(), border_radius=12)

        # Direction indicator for the front of the robot
        pygame.draw.rect(base, (255, 255, 255), ((self.size / 2 - 8), (self.size / 2) - 30, 16, 16))
        rotated = pygame.transform.rotate(base, -self.angle)
        rect = rotated.get_rect(center=(self.x, self.y))
        surf.blit(rotated, rect)

    # Adjusts robot's position based on given inputs
    def move_input(self, forward, turn):
        # Rotate based on turn input
        self.angle += turn * self.turn_speed

        # Move forward based on angle
        rad = math.radians(self.angle)
        self.y -= math.cos(rad) * forward * self.speed
        self.x += math.sin(rad) * forward * self.speed
