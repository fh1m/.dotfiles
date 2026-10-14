"""Local-only tab renderer: native window count, layout and attention.

No subprocesses or polling in the draw path. Kitty owns tab selection and input.
"""
import os
from kitty.fast_data_types import get_boss, wcswidth
from kitty.tab_bar import as_rgb
from kitty.utils import color_as_int
from kitty.rgb import to_color

PINK = as_rgb(color_as_int(to_color('#f23d70')))
BLACK = as_rgb(color_as_int(to_color('#000000')))
DIM = as_rgb(color_as_int(to_color('#39342f')))
PAPER = as_rgb(color_as_int(to_color('#e8e2da')))


def bounded(text, width):
    text = ''.join(c for c in str(text) if c.isprintable())
    out = ''
    for character in text:
        if wcswidth(out + character) > width:
            return out[:-1] + '…' if out else ''
        out += character
    return out


def draw_tab(draw_data, screen, tab, before, max_title_length, index, is_last, extra_data):
    start = screen.cursor.x
    available = min(max_title_length, screen.columns-start)
    if available <= 0:
        return start
    boss = get_boss()
    native = boss.tab_for_id(tab.tab_id) if boss else None
    window = native.active_window if native else None
    cwd = os.path.basename(window.child.current_cwd or '') if window else ''
    mark = '󰂞' if tab.needs_attention else '●' if tab.has_activity_since_last_focus else ''
    title = tab.title or 'Terminal'
    details = f' {tab.num_windows}w · {tab.layout_name}'
    if cwd:
        details += f' · {cwd}'
    screen.cursor.bold = tab.is_active
    screen.cursor.fg = PINK
    screen.cursor.bg = DIM
    number = bounded(f' {index} ', available)
    screen.draw(number)
    remaining = available-wcswidth(number)-1
    screen.cursor.fg = BLACK if tab.is_active else PAPER
    screen.cursor.bg = PINK if tab.is_active else DIM
    screen.draw(bounded(f' {mark} {title}{details} ', max(0, remaining)))
    end = screen.cursor.x
    screen.cursor.bold = False
    screen.cursor.fg = PAPER
    screen.cursor.bg = BLACK
    if screen.cursor.x < screen.columns:
        screen.draw(' ')
    return end
