# Agents

各 subagent の使い方・動作確認・カスタマイズのガイド。

インストール手順はリポジトリルートの [README.md](../README.md) を参照。

## 共通ルール

このディレクトリに置かれる subagent はすべて以下の 3 原則を満たす:

1. **Read-only** — `tools` は `Read, Grep, Glob, Bash` のみ。Write/Edit は渡さない
2. **要約して返す** — 読み込んだ内容を全文でメインに戻さない
3. **自動発火設計** — description に `Use PROACTIVELY` / `MUST BE USED` を含め、
   適切な状況でメイン Claude が自動委任する

新しい agent を追加するときも同じ原則で書くこと。

## 使い方

### 自動発火（推奨）

両方の subagent は frontmatter の description に `Use PROACTIVELY` と `MUST BE USED` を
含めており、該当する作業時にメイン Claude が自動で委任を判断する。

つまり、普通に会話するだけで subagent が裏で起動する。

### 明示的な呼び出し

明示的に呼びたい場合:

```
codebase-explorer を使って、このリポジトリの認証周りがどこに実装されているか調べて
```

```
ui-design-reviewer でモックをレビューして
```

## 動作確認テスト

### Test 1: codebase-explorer

何らかのリポジトリで Claude Code を起動し、以下のいずれかを投げる:

```
このリポジトリで設定ファイルの読み込みはどう実装されてる？
```

```
ログイン処理のエントリポイントから最終的な状態遷移までの流れを追って
```

```
環境変数は全部でいくつ参照されている？用途別に分類して
```

**成功の兆候**:
- Claude が「codebase-explorer に委任します」等の表示を出す
- 子エージェントの実行ログが別枠で流れる
- 最終的に **要約だけ** がメインに戻ってくる
- メインのコンテキスト使用量（statusline で確認）がほぼ増えていない

**失敗の兆候**:
- Claude が自分で grep や Read を始めて大量のファイル内容を表示する
- コンテキストが急激に膨らむ

失敗する場合の対処:
- `/agents` で subagent が認識されているか確認
- description を見直し、該当するトリガー語（「調査」「どう実装」「どこにある」等）が
  強く示唆されるか確認

### Test 2: ui-design-reviewer

UI Bootstrap Kit で生成した SpecPilot モックのディレクトリで Claude Code を起動し:

```
生成したモック群をレビューして
```

または:

```
DESIGN.md 守れてるかチェックして
```

**成功の兆候**:
- Claude が「ui-design-reviewer に委任します」等の表示を出す
- レビュー結果が 5 レイヤで構造化されて返ってくる
- 「TOP 3 の優先修正」と「良かった点」が返ってくる
- メインのコンテキストは増えずに所見だけが残る

**失敗の兆候**:
- Claude がファイルを開いてダラダラと全ファイル走査を始める
- レビュー結果の形式がバラバラ

## 本当にコンテキスト分離が効いているか確認

subagent の価値は「コンテキスト分離」なので、以下で効果を実感する:

1. Claude Code 起動直後、`/statusline` で現在のコンテキスト使用率を確認（例: 5%）
2. subagent に重めの調査を投げる（大量ファイル読み込みが発生するタスク）
3. 完了後、再度コンテキスト使用率を確認
4. **5% のまま、または +1〜2% 程度** であれば subagent が効いている
5. もし 30% や 40% に膨らんでいたら、subagent ではなくメインが直接作業してしまっている

## よくある挙動の違い

### メインが直接やる場合
```
User: 「このリポジトリの認証周り調べて」
Main:  [Read src/auth/login.ts]
       [Read src/auth/session.ts]
       [Read src/middleware/auth.ts]
       [Grep "authenticate"]
       [Read 10 more files...]
       全部の内容が context に残る
Main:  "認証は [長々と...]"
```

### subagent に委任する場合
```
User: 「このリポジトリの認証周り調べて」
Main:  [delegate to codebase-explorer]
       ↓
     Subagent (別コンテキスト):
       [Read × 10]
       [Grep × 5]
       → 要約 500 token を返す
       ↓
Main:  "認証は JWT ベースで、src/auth/session.ts がメイン、
        ミドルウェアが src/middleware/auth.ts にあります。
        詳細は [subagent の要約]"
```

後者だと、メインは **要約だけを受け取る** ので、以降の会話で認証周りの議論を
続けても context 消費がほとんど増えない。

## 追加 tips

### Chain で使う
`codebase-explorer` で調査 → 結果を見て `ui-design-reviewer` でレビュー、のような
直列呼び出しも可能。Claude Code が状況に応じて自動判断してくれる。

### Parallel で使う
複数の subagent を同時に動かすこともできる（例: 認証周りの調査と DB 周りの調査を
並行）。「並行で調べて」のように指示すれば、メイン Claude が複数 subagent を同時起動する。

### CLAUDE.md との連携
プロジェクトの CLAUDE.md に以下のような一文を入れると、さらに自動発火しやすくなる:

```
## subagent の活用方針

- 3 ファイル以上を読む調査タスクは必ず codebase-explorer に委任する
- UI モック生成後は必ず ui-design-reviewer でレビューしてから報告する
```

## 拡張のアイデア

このセットを使い込んで体になじんできたら、以下を追加検討:

- **`pattern-reviewer`** — コードベース全体の命名・構造のパターンに沿っているかレビュー
- **`security-reviewer`** — OWASP Top 10 視点でのレビュー専門
- **`dependency-auditor`** — package.json / lock file の依存関係監査
- **`test-writer`** — 既存の実装から test を逆算して生成

いずれも本セットと同様に、`Use PROACTIVELY` / `MUST BE USED` を description に入れ、
**read-only かつ 要約のみ返す** 原則を守って設計する。
