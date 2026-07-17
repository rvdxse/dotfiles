#!/usr/bin/env python3

import os
import json
import re
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union
import urllib.parse
import requests
from dateutil import parser

# --- Configuration & State Management ---


class Config:
    settings = {
        "colors": {
            "primary": "#5D8BBB",
            "very_cold": "#36A5CA",
            "cold": "#6DCEEB",
            "chilly": "#BEEEB8",
            "neutral": "#7FCF78",
            "warm": "#F0E68C",
            "hot": "#FF7979",
            "pop_low": "#EAD7FF",
            "pop_med": "#CFA7FF",
            "pop_high": "#BC85FF",
            "pop_vhigh": "#A855F7",
            "divider": "#24364D",
        },
        "icon_type": "nerd",
        "icon_position": "left",
        "font_size": 14,
        "unit": "Celsius",
        "hourly_number_of_hours": 24,
        "daily_number_of_days": 10,
        "snapshot_number_of_days": 2,
        "latitude": "auto",
        "longitude": "auto",
        "refresh_interval": 900,
        "time_format": "24h",
        "hour_display": "number",
        "color_weather_icons": False,
        "weather_colors": {},
        "pongo_size": {},
    }

    @classmethod
    def init(cls):
        user_config = cls.load_user_config()

        # Merge dictionaries
        if "colors" in user_config:
            cls.settings["colors"].update(user_config["colors"])
        if "weather_colors" in user_config:
            cls.settings["weather_colors"].update(user_config["weather_colors"])

        cls.settings["color_weather_icons"] = user_config.get(
            "color_weather_icons", cls.settings["color_weather_icons"]
        )

        # Mapping for simple keys
        keys = [
            "icon_type",
            "icon_position",
            "font_size",
            "unit",
            "hourly_number_of_hours",
            "daily_number_of_days",
            "snapshot_number_of_days",
            "latitude",
            "longitude",
            "refresh_interval",
            "time_format",
            "hour_display",
        ]

        for k in keys:
            if k in user_config:
                cls.settings[k] = user_config[k]

        cls.settings["hourly_number_of_hours"] = max(
            1, min(int(cls.settings["hourly_number_of_hours"]), 24)
        )
        cls.settings["snapshot_number_of_days"] = max(
            1, min(int(cls.settings["snapshot_number_of_days"]), 3)
        )
        cls.update_pongo_sizes()

    @classmethod
    def update_pongo_sizes(cls):
        fs = cls.settings["font_size"]
        cls.settings["pongo_size"] = {
            "small": (fs - 2) * 1000,
            "medium": fs * 1000,
            "large": (fs + 4) * 1000,
        }

    @classmethod
    def load_user_config(cls) -> Dict:
        path = Path(__file__).parent / "weather_settings.jsonc"
        if not path.exists():
            return {}
        content = path.read_text()
        # Remove comments for JSONC support
        content = re.sub(r"//.*$", "", content, flags=re.MULTILINE)
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            return {}

    @property
    def unit_label(self):
        return "°C" if self.settings["unit"] == "Celsius" else "°F"

    @property
    def precip_unit(self):
        return "mm" if self.settings["unit"] == "Celsius" else "in"


# --- Icons & UI ---


class Icons:
    _icon_map = []
    _ui_icons = {}

    @classmethod
    def init(cls):
        script_dir = Path(__file__).parent

        # Load weather icons
        try:
            with open(script_dir / "weather_icons.json") as f:
                cls._icon_map = json.load(f)
        except:
            cls._icon_map = []

        # Load UI icons
        try:
            with open(script_dir / "ui_icons.json") as f:
                data = json.load(f)
                cls._ui_icons = data.get(
                    Config.settings["icon_type"], data.get("nerd", {})
                )
        except:
            cls._ui_icons = {}

    @classmethod
    def get_ui(cls, key: str) -> str:
        parts = key.split(".")
        val = cls._ui_icons
        for p in parts:
            val = val.get(p, {}) if isinstance(val, dict) else ""
        return val if isinstance(val, str) else ""

    @classmethod
    def weather_icon(cls, code: int, is_day: bool) -> str:
        icon_type = Config.settings["icon_type"]
        for item in cls._icon_map:
            if int(item["code"]) == code:
                key = f"icon-{icon_type}" if is_day else f"icon-{icon_type}-night"
                fallback = f"icon-{icon_type}"
                return item.get(key, item.get(fallback, ""))
        return ""

    @classmethod
    def style(cls, glyph: str, color: str = None, size: int = None) -> str:
        color = color or Config.settings["colors"]["primary"]
        size = size or Config.settings["pongo_size"]["medium"]
        return f"<span foreground='{color}' size='{size}'>{glyph} </span>"


# --- Weather Logic ---


class MoonPhase:
    KNOWN_NEW_MOON = datetime(2000, 1, 6, 18, 14, tzinfo=timezone.utc)
    LUNAR_CYCLE = 29.530588861

    @classmethod
    def calculate(cls, date_str: str) -> float:
        dt = parser.parse(date_str)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        diff = (dt - cls.KNOWN_NEW_MOON).total_seconds() / 86400.0
        return (diff % cls.LUNAR_CYCLE) / cls.LUNAR_CYCLE

    @classmethod
    def phase_name(cls, phase: float) -> str:
        if 0.0 <= phase < 0.0625 or 0.9375 <= phase <= 1.0:
            return "New Moon"
        if 0.0625 <= phase < 0.1875:
            return "Waxing Crescent"
        if 0.1875 <= phase < 0.3125:
            return "First Quarter"
        if 0.3125 <= phase < 0.4375:
            return "Waxing Gibbous"
        if 0.4375 <= phase < 0.5625:
            return "Full Moon"
        if 0.5625 <= phase < 0.6875:
            return "Waning Gibbous"
        if 0.6875 <= phase < 0.8125:
            return "Last Quarter"
        return "Waning Crescent"


# --- Data Fetching ---


def fetch_weather():
    settings = Config.settings
    # Geolocation
    if settings["latitude"] == "auto":
        geo = requests.get(
            "http://ip-api.com/json/?fields=lat,lon,city,regionName,country"
        ).json()
        lat, lon = geo["lat"], geo["lon"]
        loc_name = f"{geo['city']}, {geo['regionName']}, {geo['country']}"
    else:
        lat, lon = float(settings["latitude"]), float(settings["longitude"])
        loc_name = None

    # Open-Meteo
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": "temperature_2m,apparent_temperature,is_day,precipitation,weather_code",
        "hourly": "temperature_2m,precipitation_probability,precipitation,weather_code,is_day",
        "daily": "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,sunrise,sunset",
        "temperature_unit": "celsius"
        if settings["unit"] == "Celsius"
        else "fahrenheit",
        "precipitation_unit": "mm" if settings["unit"] == "Celsius" else "inch",
        "timezone": "auto",
        "daily_number_of_days": settings["daily_number_of_days"],
    }

    resp = requests.get("https://api.open-meteo.com/v1/forecast", params=params).json()
    return resp, loc_name


# --- Mode & Cache ---


class WeatherMode:
    MODES = ["default", "weekview"]

    @classmethod
    def get_path(cls):
        path = (
            Path(os.getenv("XDG_STATE_HOME", Path.home() / ".local/state")) / "waybar"
        )
        path.mkdir(parents=True, exist_ok=True)
        return path / "weather_mode"

    @classmethod
    def get(cls):
        p = cls.get_path()
        if p.exists():
            m = p.read_text().strip()
            return m if m in cls.MODES else "default"
        return "default"

    @classmethod
    def cycle(cls):
        curr = cls.get()
        new_m = cls.MODES[(cls.MODES.index(curr) + 1) % len(cls.MODES)]
        cls.get_path().write_text(new_m)


# --- Main Logic ---


def main():
    if len(sys.argv) > 1 and sys.argv[1] in ["--toggle", "--next"]:
        WeatherMode.cycle()
        return

    Config.init()
    Icons.init()

    try:
        data, loc_name = fetch_weather()
        curr = data["current"]

        # Simple Waybar Output
        temp = round(curr["temperature_2m"])
        unit = "°C" if Config.settings["unit"] == "Celsius" else "°F"
        code = curr["weather_code"]
        is_day = bool(curr["is_day"])

        icon = Icons.weather_icon(code, is_day)
        styled_icon = Icons.style(icon, size=Config.settings["pongo_size"]["small"])

        text = f"{styled_icon}{temp}{unit}"

        # Tooltip Building (Simplified for example, following Ruby logic)
        tooltip = f"<b>{loc_name or data['timezone']}</b>\n"
        tooltip += f"{styled_icon} {temp}{unit} (Feels like {round(curr['apparent_temperature'])}{unit})\n"

        # Classes for CSS
        pop = data["hourly"]["precipitation_probability"][0]
        classes = ["weather", f"mode-{WeatherMode.get()}"]
        if pop >= 60:
            classes.append("pop-high")

        print(json.dumps({"text": text, "tooltip": tooltip, "class": classes}))

    except Exception as e:
        print(json.dumps({"text": "!", "tooltip": str(e)}))


if __name__ == "__main__":
    main()
