#!/usr/bin/env python3
"""One-line current weather for the YASB bar. Same city rule as the Linux helper: no IP lookup.

Reads ~/.config/sensei-weather.json (written by the Linux helper's `city` command). Without it,
uses the repo default, Dhaka. Prints "<icon>  27°C · Clear sky", or "weather offline" if the
request fails. The icon is a Font Awesome 5 glyph from the Nerd Font, so the bar font draws it.
"""
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')

CONFIG = Path.home() / '.config' / 'sensei-weather.json'
DEFAULT = {'name': 'Dhaka', 'latitude': 23.8103, 'longitude': 90.4125}

SUN, CLOUD_SUN, CLOUD, SMOG = '', '', '', ''
RAIN, HEAVY_RAIN, SNOW, BOLT = '', '', '', ''
WMO = {
    0: (SUN, 'Clear sky'),
    1: (CLOUD_SUN, 'Mostly clear'),
    2: (CLOUD_SUN, 'Partly cloudy'),
    3: (CLOUD, 'Overcast'),
}


def describe(code):
    if code in WMO:
        return WMO[code]
    if code <= 48:
        return SMOG, 'Fog'
    if code <= 57:
        return RAIN, 'Drizzle'
    if code <= 67:
        return HEAVY_RAIN, 'Rain'
    if code <= 77:
        return SNOW, 'Snow'
    if code <= 82:
        return HEAVY_RAIN, 'Rain showers'
    if code <= 86:
        return SNOW, 'Snow showers'
    return BOLT, 'Thunderstorms'


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
        icon, text = describe(current['weather_code'])
        print(f"{icon}  {round(current['temperature_2m'])}°C · {text}")
    except (OSError, KeyError, ValueError):
        print('weather offline')


if __name__ == '__main__':
    main()
