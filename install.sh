#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia/modules/session/Content.qml"
script_file="$HOME/.local/bin/codex-limits-widget.py"
for command in python3 codex; do
    command -v "$command" >/dev/null || { printf 'Missing dependency: %s\n' "$command" >&2; exit 1; }
done
[[ -f "$config_file" ]] || { printf 'Caelestia session file not found: %s\n' "$config_file" >&2; exit 1; }
[[ -f /usr/share/icons/Papirus/24x24/panel/indicator-chatgpt.svg ]] || { printf 'Missing Papirus ChatGPT icon; install Papirus icon theme first.\n' >&2; exit 1; }
python3 - "$config_file" "$project_dir/widget.qml" "$project_dir/codex-limits-widget.py" "$script_file" <<'PY'
from pathlib import Path
import datetime
import shutil
import sys

config, widget, source_script, target_script = map(Path, sys.argv[1:])
text = config.read_text()
if 'id: codexUsage' in text:
    sys.exit('Widget already present; no files were changed.')
anchor = '    AnimatedImage {'
if text.count(anchor) != 1 or 'import QtQuick.Controls as Controls' not in text:
    sys.exit('Unsupported Caelestia session layout; no files were changed.')
if 'import Quickshell.Io' not in text:
    if 'import Quickshell\n' not in text:
        sys.exit('Quickshell import not found; no files were changed.')
    text = text.replace('import Quickshell\n', 'import Quickshell\nimport Quickshell.Io\n', 1)
if target_script.exists():
    sys.exit(f'{target_script} already exists; no files were changed.')
backup = config.with_name(config.name + '.bak-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
shutil.copy2(config, backup)
target_script.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(source_script, target_script)
target_script.chmod(0o755)
config.write_text(text.replace(anchor, widget.read_text() + anchor, 1))
print(f'Installed. Configuration backup: {backup}')
PY
printf 'Restart Caelestia Shell in your graphical session: caelestia shell -k; caelestia shell -d\n'
