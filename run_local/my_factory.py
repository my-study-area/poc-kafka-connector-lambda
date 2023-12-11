import factory
import random

# Define three different classes
class Robot:
    def __init__(self, name, model):
        self.name = name
        self.model = model

class Car:
    def __init__(self, make, year):
        self.make = make
        self.year = year

class Computer:
    def __init__(self, brand, cpu):
        self.brand = brand
        self.cpu = cpu

# Define factories for each class
class RobotFactory(factory.Factory):
    class Meta:
        model = Robot
    name = factory.Faker('name')
    model = factory.Sequence(lambda n: f"Model{n}")

class CarFactory(factory.Factory):
    class Meta:
        model = Car

    make = factory.Faker('company')
    year = factory.Faker('year')

class ComputerFactory(factory.Factory):
    class Meta:
        model = Computer

    brand = factory.Faker('company')
    cpu = factory.Faker('word')

# Function to create a random list of objects
def create_random_objects(number_of_objects):
    object_list = []
    factories = [RobotFactory, CarFactory, ComputerFactory]
    for _ in range(number_of_objects):
        # Randomly select a factory
        factory_choice = random.choice(factories)
        # Create an object using the selected factory
        object_list.append(factory_choice())
    return object_list

# Create a list of 10 random objects
random_objects_list = create_random_objects(10)

# Display the created objects
for obj in random_objects_list:
    if isinstance(obj, Robot):
        print(f"Robot: {obj.name}, {obj.model}")
    elif isinstance(obj, Car):
        print(f"Car: {obj.make}, {obj.year}")
    elif isinstance(obj, Computer):
        print(f"Computer: {obj.brand}, {obj.cpu}")
