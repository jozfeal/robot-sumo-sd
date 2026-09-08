import pygame

# Robot class used for representing the robots in space
class Robot:
    def __init__(self, x, y, color, size=80, speed=8):
        self.x = x
        self.y = y
        self.color = color
        self.size = size

    # Returns the positional rectangle this robot occupies
    def rect(self):
        return pygame.Rect(self.x - self.size / 2, self.y - self.size / 2, self.size, self.size)

    # Displays robot on screen using its rectangle
    def draw(self, surf):
        pygame.draw.rect(surf, self.color, self.rect(), border_radius=6)