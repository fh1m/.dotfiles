#!/usr/bin/env python3
"""One-line current weather for the YASB bar. Same city rule as the Linux helper: no IP lookup.

Reads ~/.config/sensei-weather.json (written by the Linux helper's `city` command). Without it,
uses the repo default, Dhaka. Prints "27°C · Clear sky", or "weather offline" if the request fails.
"""
import json
import urllib.parse
import urllib.request
from pathlib import Path

CONFIG = Path.home() / '.config' / 'sensei-weather.json'
DEFAULT = {'name': 'Dhaka', 'latitude': 23.8103, 'longitude': 90.4125}
WMO = {0: 'Clear sky', 1: 'Mostly clear', 2: 'Partly cloudy', 3: 'Overcast'}


def describe(code):
    if code in WMO:
        return WMO[code]
    if code <= 48:
        return 'Fog'
    if code <= 57:
        return 'Drizzle'
    if code <= 67:
        return 'Rain'
    if code <= 77:
        return 'Snow'
    if code <= 82:
        return 'Rain showers'
    if code <= 86:
        return 'Snow showers'
    return 'Thunderstorms'


def main():
    try:
        city = {**DEFAULT, **json.loads(CONFIG.read_text(encoding='utf-8'))}
    except (OSError, ValueError):
        city = DEFAULT
    query = urllib.parse.urlencode({
        'latitude': city['latitude'],
        'longitude': city['longitude'],
        'current': 'temperature_2m,weather_code',
    })
    try:
        with urllib.request.urlopen(f'https://api.open-meteo.com/v1/forecast?{query}', timeout=15) as r:
            current = json.load(r)['current']
        print(f"{round(current['temperature_2m'])}°C · {describe(current['weather_code'])}")
    except (OSError, KeyError, ValueError):
        print('weather offline')


if __name__ == '__main__':
    main()
