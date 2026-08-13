---
name: cleanup
description: Post-merge housekeeping. Switches to the main integration branch, fast-forwards it, deletes the just-merged feature branch, and optionally tidies non-locked worktrees. Use when the user says "develop にマージしました", "merged", "後片付け", or invokes /cleanup.
---

# /cleanup — マージ後の後片付け

PR が統合ブランチ (通常 `develop`、リポジトリによっては `main`) にマージされた後の最小限の後片付けを行うスキル。「次のタスクに移る前のリセット」が目的。

## ゴール

- 統合ブランチに移動し最新化する
- 直前まで作業していた feature ブランチを安全に削除する
- agent 用ロック以外の worktree で「もう使わなさそうなもの」を対話で片付ける

**やらないこと**: 既に古い 100+ 件の merged ブランチを一掃する作業。`/cleanup` は「**直近マージ分**」だけ触る。広範な掃除は別途ユーザー判断で。

## 実行手順

### 1. 統合ブランチを特定する

```sh
git remote show origin | grep "HEAD branch"
```

通常 `develop` だが、`main` のみのリポジトリもある。git config の `init.defaultBranch` や、`origin/HEAD` の指す先を尊重する。CLAUDE.md に「`develop` が統合ブランチ」と明記されていればそちらを優先。

### 2. 直前の作業ブランチを記録

```sh
git branch --show-current
git status -s
```

未コミットの変更があれば**先に user に確認**。コミットされていない作業を `git checkout` で取り残してはいけない。`?? .claude/worktrees/` のような agent 用一時ディレクトリは無視して OK。

### 3. 統合ブランチへ切り替えて fast-forward

```sh
git fetch --prune origin
git checkout <integration-branch>
git pull --ff-only origin <integration-branch>
```

`--ff-only` は重要: 万一 local に勝手な commit が乗っていた時にマージコミットを作らせない。失敗したら user に状況を伝え、自分で `--ff-only` を外したり rebase したりしない。

### 4. マージ確認

直前の作業ブランチが本当に統合ブランチに含まれているか確認:

```sh
git branch --merged <integration-branch> | grep "^  <branch-name>$"
```

該当なし → user に「マージされていないように見えますが本当に消していいですか?」と確認。GitHub 側で squash merge された場合、git の `--merged` 判定では検出されないことがある。その場合は `gh pr view <PR#> --json state,mergedAt` で `MERGED` を確認する。

### 5. ローカルブランチを削除

```sh
git branch -d <branch-name>
```

`-d` (小文字) を使うこと。`-D` (force) は使わない: マージ未検出時に user の作業を破壊する危険がある。

`-d` が拒否された時の切り分け:

1. **squash merge の可能性**: GitHub 側で squash merge された場合、git の `--merged` 判定では検出されない。`gh pr view <PR#> --json state,mergedAt` で `MERGED` を確認し、user に判断を仰ぐ。

2. **local が tracked remote より進んでいるパターン** (`-d` が「not yet merged to refs/remotes/origin/...」と言う場合): feature ブランチに develop を merge して push し忘れ、等で発生する。**統合ブランチに対するユニーク commit があるかどうか**で安全性を判定:

   ```sh
   git log <branch> --not <integration-branch> --oneline
   ```

   空なら local の全 commit は統合ブランチに含まれており、データ損失リスクなし。user に「ユニーク commit なし → `-D` で消して OK?」と提示して承認を得る。空でなければ未マージの作業が残っているので削除しない。

どのケースでも **agent 判断で `-D` を発火させない**。必ず user 承認を経る。

### 6. worktree の対話的片付け (オプション)

```sh
git worktree list
```

判断ルール:

- `locked` 付きの agent 用 worktree (`.claude/worktrees/agent-*`) は**絶対に触らない**
- それ以外の worktree について、その branch が:
  - 統合ブランチに merged 済み → 削除候補
  - 未 push の commit がある → 削除候補に**しない**
  - tracked remote が存在しない (`gh pr view` で見えない) → user に確認

削除候補が見つかった場合は user に list を示して「これらを `git worktree remove` していい？」と確認。一括削除はせず、user の OK が出たら 1 件ずつ実行。

実際の削除:

```sh
git worktree remove <path>
git branch -d <branch>  # worktree の branch も一緒に消す
```

該当無しなら「worktree は触る必要なし」と一行報告して終了。

### 7. 完了報告

簡潔に:

- どのブランチを削除したか
- どの worktree を削除したか (あれば)
- 残ったメッセージ (例: 「189 件の古い merged ブランチが残っていますが、それらは `/cleanup` 範囲外です。一括掃除したい場合は別途指示してください」)

## 禁止事項

- **`develop` / `main` への直接 commit / push を発生させない**: pull --ff-only のみ
- **`-D` での強制削除を使わない**: 必ず `-d`。失敗したら user 判断
- **locked worktree に触らない**: `.claude/worktrees/agent-*` は parent agent の作業中ディレクトリ
- **`git stash` を勝手に積まない**: 未コミット変更があれば user に判断を仰ぐ
- **既存 merged ブランチを一掃しない**: 「直近マージ分」のスコープを守る。広域掃除は別タスク
