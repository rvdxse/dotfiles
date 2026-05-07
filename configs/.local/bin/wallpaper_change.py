import os, random, subprocess, argparse

STATE_FILE = os.path.expanduser("~/.cache/wallpaper/current")


class Cmd:
    @staticmethod
    def run(cmd):
        print(f"-> {cmd}")
        subprocess.run(cmd, shell=isinstance(cmd, str), check=True)


parser = argparse.ArgumentParser()
parser.add_argument("wallpaper", nargs="?")
args = parser.parse_args()

wall = args.wallpaper or os.getenv("WALLPAPER")
if not wall:
    WALLPAPERS = os.path.expanduser("~/Pictures/Wallpapers")
    files = [
        os.path.join(WALLPAPERS, f)
        for f in os.listdir(WALLPAPERS)
        if f.endswith((".jpg", ".png", ".webp", ".gif"))
    ]
    wall = random.choice(files)


wall = os.path.expanduser(wall)

os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
with open(STATE_FILE, "w") as f:
    f.write(wall)
# subprocess.run(["swww", "img", "--namespace", "default", "-t", "grow", "--transition-fps", "90", wall])
#
# Cmd.run(f'swww img --namespace default -t grow --transition-fps 90 {wall}')
subprocess.run(
    [
        "awww",
        "img",
        "--namespace",
        "default",
        "-t",
        "wipe",
        "--transition-angle",
        "30",
        "--transition-fps",
        "90",
        wall,
    ]
)
# subprocess.run(["pkill", "hyprlax"])
subprocess.run(["wal", "-i", wall, "-n"])  # , "--saturate", '0.75'])
# subprocess.run(["hyprlax", "-d", "0.5", wall])
# subprocess.run(["wal", "-i", wall, "-n"]) #, "--saturate", '0.75'])
# Cmd.run(f'wal -i', wal, '-n')
# Cmd.run("killall -SIGUSR2 waybar")
# subprocess.run(["killall", "-SIGUSR2", "waybar"])
print(f"Set wallpaper to {wall}")
