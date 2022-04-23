import os
import glob
import pickle

import random


class Sample:

    def __init__(self, speech, noise, name):
        self.speech = speech
        self.noise = noise
        self.name = name

    def get_noisy(self):
        return self.speech + self.noise


class DataBase:

    def __init__(self, n_samples=None):

        self.samples = []

        if not os.path.isdir("data"):
            print("data/ path doesn't exist!")
            return

        pickle_files = glob.glob("data/*.pkl")

        if n_samples is None:
            for pickle_file in pickle_files:
                with open(pickle_file, "rb") as file:
                    sample_obj = pickle.load(file)
                    self.samples.append(sample_obj)

        else:
            random.shuffle(pickle_files)
            for pickle_file in pickle_files[:n_samples]:
                with open(pickle_file, "rb") as file:
                    sample_obj = pickle.load(file)
                    self.samples.append(sample_obj)

        print(f"{len(self.samples)} pickle files are loaded.")
