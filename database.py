class Sample:

    def __init__(self, speech, noise, name):
        self.speech = speech
        self.noise = noise
        self.name = name

    def get_noisy(self):
        return self.speech + self.noise
