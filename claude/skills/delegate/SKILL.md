---
name: delegate
description: 別エージェントに pane で委譲する。HERDR_ENV=1 で役割分担できる作業(調査、洗い出し、実装、テスト修正、web 調査、設計への反論)が来たら、最初のファイルを開く前に使う。
---

# delegate

herdr の環境(`HERDR_ENV=1`)があり、役割分担できる作業なら、抱え込まずに pane を起動して別エージェントに委譲する。pane の操作は `herdr` skill に従う。

ローカルで使える AI を確認し(`command -v claude codex cursor-agent`、`cursor-agent --list-models`)、作業の難しさで選ぶ。品質と token 料金の両方を最適化する。量が多い機械的な作業は安いモデルか残量の多いプランへ、設計判断や自信のない答えは強いモデルへ。残量は `$TMPDIR/statusline-cache/quota-*.json`。

## 事故から決まっていること

- 委譲先を操作するのは自分の tab の pane だけ。他のセッションの pane を閉じると、その作業が消える。
- 閉じる前に画面が止まっていることを確かめる。`idle` / `done` は作業中でも出る。
- 委譲先にキーボードはないので、承認プロンプトは固まる。cursor-agent は `--trust --force --approve-mcps`、codex は `-a never -s workspace-write`。
- pane は幅 50 列、高さ 10 行を下回らない。下回るとタスクが入力欄に残ったまま送信されない。
- cursor-agent は `--model` を `~/.cursor/cli-config.json` に書き戻す。起動の前後で `model` と `effort` を元に戻す。
- 結果を読んだ pane は閉じる。返ってきた答えは主張なので、diff を読み、検証してから報告する。
