#!/usr/bin/env python3
"""Claude Code のプロジェクトメモリを静的監査する。

使い方: python3 audit_memory.py <memory_dir>

出力は「疑い」であって結論ではない。B/C は必ず gh/git で現物照合する。
"""
import re
import sys
from datetime import date
from pathlib import Path

MEM = Path(sys.argv[1])
TODAY = date.today()

# 「自分が現在である」と名乗る語。裸の「最新」「正式版」は普通名詞として頻出するので採らない
CURRENCY = re.compile(r"現行|最有力|権威版|最新版|現在の適応先|current authoritative")
# 既に死亡宣告済みの記述は除く
SUPERSEDED = re.compile(r"上書き済み|前版・|旧版・")
# 未完了を主張する語
PENDING = re.compile(r"未マージ|未 ?PR|未 ?push|未着手|未 ?publish|レビュー待ち|OPEN（|保留|宿題|残タスク|次は")
PR_RE = re.compile(r"#(\d{2,5})")
BRANCH_RE = re.compile(r"`((?:feature|fix|infra|chore|docs|protocol)/[\w./-]+)`")
VOLATILE = re.compile(r"\b\d+\s*commits?\b|\bv?\d+\.\d+\.\d+\b|\b\d+/\d+\b")

files = sorted(p for p in MEM.glob("*.md") if p.name != "MEMORY.md")
index_p = MEM / "MEMORY.md"
index = index_p.read_text(encoding="utf-8") if index_p.exists() else ""

def fm_of(text):
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    return (m.group(1), m.group(2)) if m else ("", text)

def field(fm, key):
    m = re.search(r"^%s:(.*)$" % key, fm, re.M)
    return m.group(1).strip() if m else ""

def hdr(s):
    print("\n" + "=" * 3 + " " + s + " " + "=" * 3)

print("監査: %s" % MEM)
print("%d ファイル / 合計 %.0f KB / 索引 %d bytes"
      % (len(files), sum(p.stat().st_size for p in files) / 1024, len(index.encode())))

# --- 鮮度 ---
hdr("鮮度")
newest = max(files, key=lambda p: p.stat().st_mtime)
age = (TODAY - date.fromtimestamp(newest.stat().st_mtime)).days
print("  最新: %s (%d日前)" % (newest.name, age))
if age > 14:
    print("  ⚠ %d日分の決定が未収録の可能性" % age)

# --- 二重の現在 ---
hdr("二重の現在（最優先）")
claims = []
for p in files:
    fm, _ = fm_of(p.read_text(encoding="utf-8"))
    d = field(fm, "description")
    if CURRENCY.search(d) and not SUPERSEDED.search(d):
        claims.append((p.name, d[:100]))
for name, d in claims:
    print("  [%s] %s" % (name, d))
if len(claims) > 1:
    print("  ⚠ %d件が『現在』を名乗っている。正しいのは通常1件——残りの語を外す" % len(claims))
elif not claims:
    print("  なし")

# --- 索引ドリフト ---
hdr("索引ドリフト")
linked = set(re.findall(r"\]\(([\w.-]+\.md)\)", index))
actual = {p.name for p in files}
for x in sorted(linked - actual):
    print("  デッドリンク: %s" % x)
for x in sorted(actual - linked):
    print("  孤児(索引に無い): %s" % x)
# 単語の有無ではなく、意味の対立だけを拾う
DONE = re.compile(r"マージ済|merge ?済|完了|公開済|解消|実装済|適用済")
NOTYET = re.compile(r"未マージ|未 ?PR|未着手|未 ?publish|レビュー待ち|保留|未了|未実装")
drift = 0
for p in files:
    fm, _ = fm_of(p.read_text(encoding="utf-8"))
    d = field(fm, "description")
    m = re.search(r"\]\(%s\)\s*—?\s*(.*)" % re.escape(p.name), index)
    line = m.group(1) if m else ""
    if not line:
        continue
    # 片側が「済」だけ・もう片側が「未」だけ、のときだけ本物の対立
    d_done, d_not = bool(DONE.search(d)), bool(NOTYET.search(d))
    l_done, l_not = bool(DONE.search(line)), bool(NOTYET.search(line))
    pairs = [("完了/未完了", d_done and not d_not and l_not and not l_done),
             ("完了/未完了", d_not and not d_done and l_done and not l_not),
             ("採用/不採用", ("不採用" in d) != ("不採用" in line) and "採用" in d and "採用" in line)]
    for label, hit in pairs:
        if hit:
            print("  [%s] 索引と description が『%s』で対立" % (p.name, label))
            print("      索引: %s" % line[:80])
            print("      desc: %s" % d[:80])
            drift += 1
            break
if not (linked - actual) and not (actual - linked) and not drift:
    print("  OK")

# --- 化石（完了したのに未完了のまま） ---
hdr("化石（要 gh/git 照合）")
prs, branches, rows = set(), set(), []
for p in files:
    for ln in p.read_text(encoding="utf-8").split("\n"):
        for sent in re.split(r"[。\n]", ln):
            if PENDING.search(sent) and (PR_RE.search(sent) or BRANCH_RE.search(sent)):
                rows.append((p.name, sent.strip()[:130]))
                prs.update(PR_RE.findall(sent))
                branches.update(BRANCH_RE.findall(sent))
for name, s in rows:
    print("  [%s] %s" % (name, s))
print("\n  照合 PR: %s" % (" ".join("#" + x for x in sorted(prs, key=int)) or "なし"))
print("  照合 branch: %s" % (" ".join(sorted(branches)) or "なし"))
if prs:
    print("\n  for n in %s; do printf '%%-7s' \"#$n\"; gh pr view $n --json state --jq .state; done"
          % " ".join(sorted(prs, key=int)))
if branches:
    print("  for b in %s; do printf '%%-45s' $b; git ls-remote --heads origin $b | wc -l; done"
          % " ".join(sorted(branches)))

# --- frontmatter ---
hdr("frontmatter")
bad = 0
for p in files:
    fm, _ = fm_of(p.read_text(encoding="utf-8"))
    if not fm:
        print("  [%s] frontmatter 無し" % p.name); bad += 1; continue
    name, d = field(fm, "name").strip("\"'"), field(fm, "description")
    if not name:
        print("  [%s] name が空" % p.name); bad += 1
    if not d:
        print("  [%s] description が空" % p.name); bad += 1
    elif not d.startswith('"') and " #" in d:
        print("  [%s] description が未クォートで ' #' を含む → YAML が以降を切り捨てる" % p.name); bad += 1
    if fm.count("metadata:") > 1:
        print("  [%s] metadata が二重ネスト" % p.name); bad += 1
    elif not re.search(r"^  type:", fm, re.M):
        print("  [%s] metadata が未ネスト" % p.name); bad += 1
if not bad:
    print("  OK")

# --- 肥大 ---
hdr("肥大（1ファイル=1事実）")
big = [p for p in files if p.stat().st_size > 15000]
for p in sorted(big, key=lambda x: -x.stat().st_size):
    lines = p.read_text(encoding="utf-8").split("\n")
    print("  %6d bytes / %3d行 / 最長1行 %5d字  %s"
          % (p.stat().st_size, len(lines), max(len(l) for l in lines), p.name))
if not big:
    print("  OK")

# --- 揮発値 ---
hdr("揮発値（結論の根拠になっていないか）")
n = 0
for p in files:
    found = sorted(set(VOLATILE.findall(p.read_text(encoding="utf-8"))))
    if found:
        print("  [%s] %s" % (p.name, ", ".join(found[:8])))
        n += 1
if not n:
    print("  なし")
