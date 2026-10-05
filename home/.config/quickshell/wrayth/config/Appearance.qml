pragma Singleton

import QtQuick
import Quickshell

// Typography, spacing and geometry constants from the spec's design system.
Singleton {
    id: root

    function iconFor(name) {
  const s=String(name||"").toLowerCase();
  if(/^(‹|←|previous)/.test(s))return "\uf060";
  if(/^(›|→|next)/.test(s))return "\uf061";
  if(/queue|list/.test(s))return "\uf0cb";
  if(/library|album|artist/.test(s))return "\uf02d";
  if(/device|peripheral/.test(s))return "\uf2db";
  if(/account|profile/.test(s))return "\uf007";
  if(/hourly|clock/.test(s))return "\uf017";
  if(/history|recent|log/.test(s))return "\uf1da";
  if(/workspace|session|tab/.test(s))return "\uf009";
  if(/file|folder|project/.test(s))return "\uf07b";
  if(/overview|quick|details|info/.test(s))return "\uf05a";
  if(/wifi|network|hotspot/.test(s))return "\uf1eb";
  if(/bluetooth/.test(s))return "\uf293";
  if(/audio|sound|volume|speaker|mute/.test(s))return "\uf028";
  if(/microphone|mic/.test(s))return "\uf130";
  if(/screen|display|wallpaper/.test(s))return "\uf108";
  if(/gpu|nvidia|cuda|graphics/.test(s))return "\uf108";
  if(/cpu|hardware|performance/.test(s))return "\uf2db";
  if(/memory|ram|storage|disk/.test(s))return "\uf538";
  if(/phone|android/.test(s))return "\uf10b";
  if(/docker|container|image/.test(s))return "\uf308";
  if(/terminal|ssh|command/.test(s))return "\uf120";
  if(/package|update|upgrade|install/.test(s))return "\uf0ed";
  if(/calendar|date|today|schedule|remind/.test(s))return "\uf073";
  if(/time|timer|stopwatch|focus/.test(s))return "\uf017";
  if(/play|pause|track|song|playlist|music/.test(s))return "\uf001";
  if(/search|find/.test(s))return "\uf002";
  if(/edit|rename/.test(s))return "\uf044";
  if(/delete|remove|clear|cancel/.test(s))return "\uf1f8";
  if(/save|copy|clipboard/.test(s))return "\uf0c5";
  if(/refresh|reload|check/.test(s))return "\uf021";
  if(/power|shutdown|reboot|suspend/.test(s))return "\uf011";
  if(/lock|secure/.test(s))return "\uf023";
  if(/settings|config|control|system/.test(s))return "\uf013";
  if(/weather|forecast/.test(s))return "\uf0c2";
  if(/process|monitor|graph|diagnos/.test(s))return "\uf201";
  if(/open|launch|web/.test(s))return "\uf08e";
  return "\uf061";
 }

    readonly property QtObject font: QtObject {
        // Personal ZedMono Nerd typography for titles and clock.
        readonly property string display: "JetBrainsMono Nerd Font Mono"
        readonly property string heading: "JetBrainsMono Nerd Font Propo"
        readonly property string ui: "JetBrainsMono Nerd Font Propo"
        // ZedMono: labels, readouts and body text.
        readonly property string barUi: "JetBrainsMono Nerd Font Propo"
        readonly property string data: "JetBrainsMono Nerd Font Mono"
        // Russian accent labels use the same personal font.
        readonly property string accent: "JetBrainsMono Nerd Font Propo"
        // Icons that are somebody else's standard rather than ours -- the
        // Bluetooth rune, so far. It is the data family's own Nerd Font
        // patch, so an icon from it sits on the same metrics as the labels
        // beside it and is hinted at the sizes the bar uses.
        readonly property string icons: "ZedMono Nerd Font"

        readonly property int weightMedium: 500
        readonly property int weightBold: 700
        readonly property int weightRegular: 400
        readonly property int weightSemi: 600
    }

    readonly property QtObject size: QtObject {
        readonly property int label: 11      // uppercase tracked labels
        readonly property int ticker: 12
        readonly property int date: 11
        readonly property int katakana: 12
        readonly property int workspace: 12
        // Four-letter special-workspace labels, which have to fit the same slot.
        readonly property int workspaceSpecial: 9
        readonly property int body: 13       // readout values
        readonly property int logo: 18
        readonly property int clock: 19
        // The bar clock's seconds, raised beside HH:MM in accent.
        readonly property int clockSeconds: 12
    }

    // Fixed slot widths. Every changing number on the bar sits in one of these
    // so nothing on the bar ever moves when a value updates.
    readonly property QtObject slot: QtObject {
        readonly property int percent: 38
        readonly property int memory: 92
        readonly property int netRate: 50
        readonly property int idleValue: 34
        readonly property int btName: 120
    }

    // letter-spacing, as the em fractions the spec gives.
    readonly property real labelTracking: 0.07
    readonly property real tickerTracking: 0.04

    function tracking(pixelSize: real): real {
        return pixelSize * labelTracking;
    }

    // Digits that never change width, so fixed slots stay put. JetBrains Mono is
    // monospaced anyway; this is what keeps Chakra Petch's clock steady.
    readonly property var tabularFigures: ({
        tnum: 1,
        lnum: 1
    })

    readonly property QtObject chamfer: QtObject {
        readonly property int panel: 16
        readonly property int hud: 18
    }

    readonly property QtObject metrics: QtObject {
        readonly property int barHeight: 44
        // The ID block is a fixed width: its contents change -- the counter
        // ticks, the code is editable -- and nothing on the bar may move when
        // they do. It is also what the text is centred within.
        readonly property int idBlockWidth: 92
        // kitty's logical cell width at JetBrains Mono 11.5pt with the deck's
        // 120% cell-width setting. Keep deck layout on complete cells.
        // measured with `cell_size_for_window`. The deck terminal's width is
        // rounded down to a multiple of this so kitty's tab bar grid covers
        // the whole window: the pixels a partial cell would leave over are
        // what put a mark in the header strip's top corners. If the terminal
        // font size changes, this has to change with it.
        readonly property int terminalCellWidth: 11
        readonly property int hairline: 1
        readonly property int dividerHeight: 18
        // Every hairline divider on the bar stands off whatever is beside it by
        // this, on both sides, wherever it appears -- the readout row, the
        // ticker's two end rules, and the rules' outer neighbours. One number so
        // the whole strip keeps a single rhythm and no divider reads as more of
        // a break than another.
        readonly property int dividerGap: 14
        readonly property int deckMargin: 24
        readonly property int deckGap: 24

        // The deck at 1920x1080, all measured inside the area the bar leaves so
        // the same numbers hold once Caelestia's own bar stops reserving space.
        readonly property int deckColumnWidth: 420
        // The HUD takes the terminal's height and the signal panel the bottom
        // row's, so the right column lines up with the left.
        readonly property int deckBottomHeight: 272
        readonly property real deckPlannerRatio: 0.6

        // Bar furniture
        readonly property int workspaceWidth: 98
        readonly property int workspaceHeight: 28
        readonly property int meterSegments: 5
        readonly property int meterSegmentWidth: 5
        readonly property int meterSegmentHeight: 13
        readonly property int idleButtonHeight: 28
        // Short on purpose. The ticker keeps `dividerGap` of clear air off each
        // end rule, so this ramp starts beyond that gap rather than on top of
        // it: long enough that words do not pop in, short enough that the text
        // does not begin a whole word's width further from the left rule than
        // the katakana sits from the right one.
        readonly property int tickerFade: 20
        readonly property real tickerSpeed: 30 // px per second
    }

    // **The shared animation scale.** Four durations and one easing family, and
    // every animation in the shell is on one of them. They are named for what
    // they are *for*, not for how long they are, because the point of a scale
    // is that a press flash and a hover tint are the same length wherever they
    // appear -- see the animation pass in the decisions.
    //
    //   state     press flashes, toggles, hovers, anything acknowledging input
    //   move      something travelling from one place to another
    //   panel     a panel, an overlay or a section appearing or leaving
    //   wallpaper a wallpaper cross-fade
    //
    // Entry is `Easing.OutCubic` and exit `Easing.InCubic`, everywhere.
    // `enter` and `exit` below are the lengths that go with them: appearing is
    // a `panel` fade with an 8 px rise, leaving is quicker, because a thing on
    // its way out has nothing left to say.
    readonly property QtObject duration: QtObject {
        readonly property int state: 120
        readonly property int move: 160
        readonly property int panel: 190
        readonly property int wallpaper: 800

        readonly property int enter: 250
        readonly property int exit: 180

        // **Not on the scale, and deliberately.** A meter easing to a new
        // reading is data settling rather than an element arriving, and 0.9 s
        // is the spec's own figure for it.
        readonly property int meter: 900
        // **Not on the scale either.** It matches Hyprland's specialWorkspace
        // animation (speed 4), so the deck and the deck terminal come up as
        // one thing; retuning it alone would pull them apart.
        readonly property int deck: 400
    }

    // The rise an appearing element fades up through. A transform, never a
    // layout change: the space is already reserved, so nothing around it moves.
    readonly property int enterRise: 8

    readonly property string separator: " // "
}
