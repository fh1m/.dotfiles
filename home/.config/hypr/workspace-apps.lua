-- Initial placement only; manual moves remain yours. Modal/auth windows stay put.
local helpers = "(?i)^(sensei-deck|zenity|org\\.gnome\\.Zenity|pinentry.*|.*polkit.*|xdg-desktop-portal.*)$"
hl.window_rule({name="sensei-app-misc-default",match={class="negative:"..helpers,modal=false},workspace="7 silent"})
local routes = {
 {1,"(?i)^(Alacritty|kitty|foot|footclient|org\\.wezfurlong\\.wezterm|wezterm|konsole|org\\.gnome\\.Terminal|com\\.mitchellh\\.ghostty)$"},
 {2,"(?i)^(Google-chrome.*|chromium.*|firefox.*|org\\.mozilla\\.firefox|brave-browser.*|Brave-browser.*|vivaldi.*|opera.*|librewolf.*|zen|zen-browser|microsoft-edge.*)$"},
 {3,"(?i)^(Code|code-oss|VSCodium|Cursor|cursor.*|jetbrains-.*|jetbrains\\..*|QtCreator|qtcreator|neovide|nvim-qt|emacs|sublime_text|Arduino.*|STM32CubeIDE.*)$"},
 {4,"(?i)^(org\\.fh1m\\.Noesis|noesis|obsidian|md\\.obsidian\\.Obsidian|Notion|notion-app|Zotero|org\\.zotero\\.Zotero|zereto|Anki|anki|zathura|org\\.pwmt\\.zathura|sioyek|okular|org\\.kde\\.okular|org\\.gnome\\.Evince)$"},
 {5,"(?i)^(gazebo.*|gz.*|ignition.*|rviz.*|webots.*|coppeliasim.*|isaac.*|blender|FreeCAD.*|org\\.freecad\\.FreeCAD|KiCad.*|kicad.*|pcbnew|eeschema)$"},
 {6,"(?i)^(org\\.gnome\\.Nautilus|nautilus|org\\.kde\\.dolphin|dolphin|thunar|nemo|libreoffice.*|soffice.*|Gimp.*|org\\.gimp\\.GIMP|Inkscape|org\\.inkscape\\.Inkscape|krita|org\\.kde\\.krita|Slack|discord|telegram.*|org\\.telegram\\.desktop|Signal|thunderbird.*|zoom|org\\.gnome\\.Settings|pavucontrol|nm-connection-editor)$"},
 {7,"(?i)^(Spotify|spotify|vlc|mpv|steam.*|lutris.*|org\\.gnome\\.Calculator|gnome-calculator|org\\.gnome\\.Loupe|imv)$"},
}
for _, rule in ipairs(routes) do
 hl.window_rule({name="sensei-app-workspace-"..rule[1],match={class=rule[2],modal=false},workspace=tostring(rule[1])})
end
