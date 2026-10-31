#!/usr/bin/env python3
"""Genera gli sfondi in assets/sprites/backgrounds/<linguaggio>.png: un editor di codice scuro con codice vero,
tenue ma leggibile, uno per linguaggio. Il codice è originale e a tema (venerdì, bug, rilascio, paperelle).

Uso: python3 tools/assets/make_background.py   (serve Pillow: pip install pillow)
Il testo è disegnato qui, una volta sola: in gioco ogni sfondo è un'unica immagine statica (nessun costo sul Pi).
"""
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "sprites" / "backgrounds"
FONT = ROOT / "assets" / "fonts" / "JetBrainsMono-Regular.ttf"

W, H = 800, 480
LINE_H = 20
FONT_SIZE = 12
GUTTER = 34
TEXT_X = GUTTER + 12
BG = "#12141c"
NO_LIGATURES = ["-liga", "-calt"]
ROWS = H // LINE_H  # righe visibili: ogni frammento deve starci
ALPHA = 0.30  # intensità del codice: i colori sono mescolati con lo sfondo (0 = invisibile, 1 = pieno)

# Colori dei token, prima di essere mescolati con lo sfondo.
COLORS = {
    "keyword": "#c792ea",
    "function": "#82aaff",
    "string": "#c3e88d",
    "type": "#ffcb6b",
    "punct": "#89ddff",
    "number": "#f78c6c",
    "comment": "#7f87b0",
    "text": "#a6accd",
}

LANGUAGES = {
    "python": {
        "comment": "#",
        "keywords": "import from class def return while for in if else not and or None True False self with as pass",
        "code": '''\
# duck_debugger.py: the office closes at 18:00, the release doesn't
import random
from office import coffee_machine, release

BUGS_BEFORE_RELEASE = 20

class RubberDuck:
    """Listens in silence. Fixes everything."""

    def __init__(self, name="Quack"):
        self.name = name
        self.bugs_heard = []

    def listen(self, problem: str) -> str:
        self.bugs_heard.append(problem)
        return "...oh wait, I see the bug now!"

def friday_deploy(bugs):
    while bugs:
        bug = bugs.pop()
        print(f"fixed {bug}: {RubberDuck().listen(bug)}")
    coffee_machine.refill(cups=random.randint(3, 7))
    release.push(force=True)  # TODO: never on a Friday
''',
    },
    "java": {
        "comment": "//",
        "keywords": "package import public private protected class interface static final void int boolean return new "
                    "if else for while throw throws try catch extends implements this null true false",
        "code": '''\
package office.release;
import java.time.DayOfWeek;
import java.util.List;

// Friday 17:42. Nobody touches production.
public final class HotfixService implements Deployable {

    private static final int MAX_COFFEE = 5;
    private final List<Bug> openBugs;
    private int coffeeCups = 0;
    public HotfixService(List<Bug> openBugs) {
        this.openBugs = openBugs;
    }
    @Override
    public void deploy(DayOfWeek today) throws ReleaseException {
        if (today == DayOfWeek.FRIDAY && !openBugs.isEmpty()) {
            throw new ReleaseException("Too many bugs: " + openBugs.size());
        }
        while (coffeeCups < MAX_COFFEE) {
            coffeeCups++;
        }
        openBugs.removeIf(bug -> bug.explainTo(new RubberDuck()));
    }
}
''',
    },
    "c": {
        "comment": "//",
        "keywords": "include define typedef struct int char void return if else for while static const unsigned "
                    "sizeof NULL break size_t",
        "code": '''\
#include <stdio.h>
#include <stdlib.h>

#define MAX_BUGS 20
#define COFFEE_PER_BUG 0.25

typedef struct {
    const char *name;
    int severity;
    int fixed;
} bug_t;

/* Walk the list, explain each bug to the duck, free what's left. */
static int fix_all(bug_t *bugs, size_t count) {
    int fixed = 0;
    for (size_t i = 0; i < count; i++) {
        if (bugs[i].severity > 3 && !bugs[i].fixed) {
            printf("quack: %s\\n", bugs[i].name);
            bugs[i].fixed = 1;
            fixed++;
        }
    }
    return fixed;  // segfault-free since 17:42
}
''',
    },
    "javascript": {
        "comment": "//",
        "keywords": "const let var function return async await if else for of in new class extends this null "
                    "undefined true false throw try catch import export from default",
        "code": '''\
// release.js: ship it before the weekend
import { bugs, coffee } from "./office.js";

const DEADLINE = new Date("Fri 18:00");
const duck = { name: "Quack", patience: Infinity };

export async function hotfixFriday() {
  for (const bug of bugs.open()) {
    await explainTo(duck, bug);
    bug.status = "fixed";
  }
  if (Date.now() > DEADLINE) {
    console.warn("Still here? Have another coffee.");
    coffee.refill({ cups: 2, sugar: false });
  }

  return bugs.open().length === 0
    ? "Ship it!"
    : `${bugs.open().length} bugs left`;
}
function explainTo(listener, bug) {
  return new Promise((resolve) => setTimeout(resolve, bug.lines * 10));
}
''',
    },
    "rust": {
        "comment": "//",
        "keywords": "use fn let mut pub struct enum impl for in if else match return self Self Some None Ok Err "
                    "while loop mod const",
        "code": '''\
// The borrow checker approves this Friday deploy.
use std::collections::VecDeque;
#[derive(Debug)]
enum Bug {
    OffByOne { line: u32 },
    NullDuck,
    RaceCondition(String),
}

pub struct Duck {
    name: &'static str,
    heard: Vec<Bug>,
}
impl Duck {
    pub fn listen(&mut self, bug: Bug) -> Result<(), String> {
        match bug {
            Bug::NullDuck => Err(String::from("who am I talking to?")),
            other => {
                self.heard.push(other);
                Ok(())
            }
        }
    }
}
''',
    },
    "go": {
        "comment": "//",
        "keywords": "package import func return var const type struct for range if else go chan defer nil true "
                    "false select case break",
        "code": '''\
package hotfix

import (
	"fmt"
	"time"
)

// Deadline: Friday, 18:00 sharp.
const Deadline = 18 * time.Hour

type Bug struct {
	ID       int
	Severity int
}

func FixAll(bugs <-chan Bug, duck chan<- string) error {
	defer fmt.Println("coffee machine: refilled")
	for bug := range bugs {
		if bug.Severity > 3 {
			go func(b Bug) { duck <- fmt.Sprintf("quack #%d", b.ID) }(bug)
		}
	}
	return nil // works on my machine
}
''',
    },
    "html": {
        "comment": "<!--",
        "keywords": "",
        "code": '''\
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Release notes - Friday</title>
  <link rel="stylesheet" href="office.css">
</head>
<body>
  <!-- TODO: remove before the release -->
  <header class="banner">
    <h1>Hotfix Friday</h1>
    <p>All bugs fixed. Probably.</p>
  </header>
  <ul id="changelog">
    <li class="fixed">Off-by-one in the coffee counter</li>
    <li class="fixed">The duck was not listening</li>
    <li class="wontfix">Monday</li>
  </ul>
  <button onclick="deploy()" disabled>Deploy</button>
  <script src="release.js"></script>
</body>
</html>
''',
    },
    "sql": {
        "comment": "--",
        "keywords": "SELECT FROM WHERE AND OR ORDER BY GROUP UPDATE SET INSERT INTO VALUES CREATE TABLE PRIMARY KEY "
                    "NOT NULL INTEGER TEXT COUNT AS DESC LIMIT JOIN ON DEFAULT",
        "code": '''\
-- Which bugs are still open at 17:42 on a Friday?
CREATE TABLE bugs (
    id        INTEGER PRIMARY KEY,
    title     TEXT NOT NULL,
    severity  INTEGER DEFAULT 1,
    status    TEXT DEFAULT 'open'
);

INSERT INTO bugs (title, severity)
VALUES ('Duck not responding', 5),
       ('Coffee machine returns 418', 4),
       ('Off-by-one in the release date', 3);

SELECT title, severity
  FROM bugs
 WHERE status = 'open'
   AND severity >= 3
 ORDER BY severity DESC
 LIMIT 20;

UPDATE bugs SET status = 'fixed' WHERE id IN (1, 2, 3);
''',
    },
    "bash": {
        "comment": "#",
        "keywords": "if then else fi for in do done while case esac function return local echo exit set export",
        "code": '''\
#!/usr/bin/env bash
# deploy.sh: run only if you have explained it to the duck first
set -euo pipefail

DAY="$(date +%A)"
BUGS_LEFT="$(grep -c 'TODO' src/*.c || true)"

if [ "$DAY" = "Friday" ]; then
    echo "It's Friday. Are you sure? (y/N)"
    read -r answer
    [ "$answer" = "y" ] || exit 1
fi

for bug in $(seq 1 "$BUGS_LEFT"); do
    echo "quack $bug"
done

git tag -a "hotfix-$(date +%s)" -m "works on my machine"
git push origin main --tags
echo "Deployed. Going home."
''',
    },
}

TOKEN = re.compile(r'''
    (?P<string>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`[^`]*`)
  | (?P<number>\b\d+(?:\.\d+)?\b)
  | (?P<word>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<punct>[^\sA-Za-z0-9_])
''', re.VERBOSE)
HTML_TOKEN = re.compile(r'(?P<comment><!--.*?-->)|(?P<tag></?[A-Za-z!][A-Za-z0-9]*|/?>)|(?P<string>"[^"]*")'
                        r'|(?P<attr>\b[a-z-]+(?==))')


def blend(color, alpha=ALPHA, base=BG):
    c = [int(color[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(base[i:i + 2], 16) for i in (1, 3, 5)]
    return tuple(round(b[i] + (c[i] - b[i]) * alpha) for i in range(3))


# Divide una riga in (testo, tipo di token).
def tokens(line, lang):
    if lang["comment"] == "<!--":
        return html_tokens(line)
    marker = lang["comment"]
    if line.lstrip().startswith("/*"):
        return [(line, "comment")]
    out = []
    code, comment = line, ""
    index = comment_start(line, marker)
    if index >= 0:
        code, comment = line[:index], line[index:]
    keywords = set(lang["keywords"].split())
    pos = 0
    for m in TOKEN.finditer(code):
        if m.start() > pos:
            out.append((code[pos:m.start()], "text"))
        kind = m.lastgroup
        text = m.group()
        if kind == "word":
            after = code[m.end():m.end() + 1]
            if text in keywords:
                kind = "keyword"
            elif after == "(" or after == "!":
                kind = "function"
            elif text[0].isupper():
                kind = "type"
            else:
                kind = "text"
        out.append((text, kind))
        pos = m.end()
    if pos < len(code):
        out.append((code[pos:], "text"))
    if comment:
        out.append((comment, "comment"))
    return out


# Inizio del commento, ignorando i marcatori dentro le stringhe (e "#!", "#include" e "#[derive]").
def comment_start(line, marker):
    quote = None
    for i, ch in enumerate(line):
        if quote:
            if ch == quote and line[i - 1] != "\\":
                quote = None
        elif ch in "\"'`":
            quote = ch
        elif line.startswith(marker, i):
            if marker == "#" and (line.startswith("#!") or line.lstrip().startswith(("#include", "#define"))):
                return -1
            if marker == "#" and i > 0 and line[i - 1] in "$({[":
                continue
            return i
    return -1


def html_tokens(line):
    out = []
    pos = 0
    for m in HTML_TOKEN.finditer(line):
        if m.start() > pos:
            out.append((line[pos:m.start()], "text"))
        kind = {"tag": "keyword", "attr": "type"}.get(m.lastgroup, m.lastgroup)
        out.append((m.group(), kind))
        pos = m.end()
    if pos < len(line):
        out.append((line[pos:], "text"))
    return out


def render(name, lang, font):
    image = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(image)
    draw.rectangle([0, 0, GUTTER - 1, H], fill="#171a24")
    draw.rectangle([GUTTER, 0, GUTTER, H], fill="#232838")
    char_w = font.getlength("m")
    lines = lang["code"].expandtabs(4).rstrip("\n").split("\n")
    assert len(lines) <= ROWS, f"{name}: {len(lines)} righe, ne entrano {ROWS}"
    assert max(TEXT_X + char_w * len(line) for line in lines) <= W - 8, f"{name}: riga troppo lunga"
    for row in range(ROWS):
        y = row * LINE_H + 4
        number = str(row + 1)
        draw.text((GUTTER - 6 - font.getlength(number), y), number, font=font, fill="#2c3245", features=NO_LIGATURES)
        if row >= len(lines):
            continue
        x = TEXT_X
        for text, kind in tokens(lines[row], lang):
            draw.text((x, y), text, font=font, fill=blend(COLORS[kind]), features=NO_LIGATURES)
            x += char_w * len(text)
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{name}.png"
    image.save(path, optimize=True)
    return path


def main():
    font = ImageFont.truetype(str(FONT), FONT_SIZE)
    for name, lang in LANGUAGES.items():
        print(f"Scritto {render(name, lang, font).relative_to(ROOT)}")


if __name__ == "__main__":
    main()
