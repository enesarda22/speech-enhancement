import os
import soundfile as sf
import librosa
import random
import pickle
from scipy import io
import argparse

from database import Sample

speech_path = "raw_data/clean_speech"
noise_path = "raw_data/noise"


def read_clean_speech(t):
    speech_data = []
    speech_tags = []

    for root, dirs, files in os.walk(speech_path):
        if files:
            for file in files:
                if file.endswith(".flac"):
                    filepath = root + "/" + file

                    speech, sr = sf.read(filepath)
                    n_samples = t * sr

                    dur = len(speech) / sr
                    if dur > t:
                        speech_data.append(speech[:n_samples])
                        speech_tags.append(file.removesuffix(".flac"))

    print(f"There are {len(speech_data)} clean speech files longer than {t} seconds.")
    return speech_tags, speech_data


def read_noise(t):
    noise_data = []
    noise_tags = []

    for root, dirs, files in os.walk(noise_path):

        if files:
            for file in files:
                if file.endswith(".wav"):
                    filepath = root + "/" + file
                    dur = librosa.get_duration(filename=filepath)
                    n_samples = t * 48000

                    if dur >= t:
                        init_sample = random.randint(0, int(dur * 48000) - n_samples)
                        noise, sr = sf.read(filepath, start=init_sample, frames=t * 48000)

                        noise = noise[::3]
                        noise_data.append(noise[:, 0])
                        noise_tags.append(file.removesuffix(".wav"))

    print(f"There are {len(noise_data)} noise files longer than {t} seconds.")
    return noise_tags, noise_data


def create_pkl(t, n_files=None, ext="pkl"):

    if ext not in ["pkl", "mat"]:
        raise ValueError("Unknown extension. Available extensions are: pkl, mat")

    target_folder = f"data/{ext}/"
    if not os.path.exists(target_folder):
        os.makedirs(target_folder)

    speech_tags, speech_data = read_clean_speech(t)
    noise_tags, noise_data = read_noise(t)

    if n_files is not None:
        temp = list(zip(speech_tags, speech_data))
        random.shuffle(temp)
        speech_tags, speech_data = zip(*temp)

        speech_tags = speech_tags[:n_files]
        speech_data = speech_data[:n_files]

    for speech_tag, speech in zip(speech_tags, speech_data):
        for noise_tag, noise in zip(noise_tags, noise_data):
            name = speech_tag + "-" + noise_tag
            sample_obj = Sample(speech, noise, name)

            if ext == "pkl":
                pickle.dump(sample_obj, open(target_folder + name + ".pkl", "wb"))
                print(f"{name} is dumped")

                del sample_obj

            else:
                io.savemat(target_folder + name + ".mat", mdict={"speech": speech,
                                                                 "noise": noise,
                                                                 "name": name})


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Script to create dataset using clean speech files and noise files.")
    parser.add_argument("--t", required=True, type=int)
    parser.add_argument("--n_files", default=None, type=int)
    parser.add_argument("--ext", default="pkl")

    args = parser.parse_args()

    if not os.path.isdir(speech_path):
        raise FileNotFoundError(f"No folder named {speech_path}")
    elif not os.path.isdir(noise_path):
        raise FileNotFoundError(f"No folder named {noise_path}")

    create_pkl(args.t, n_files=args.n_files, ext=args.ext)
