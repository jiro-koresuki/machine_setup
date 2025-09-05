#!/bin/bash
# This script runs every time the instance is spawned.
# It sets up tmux and Vim configs fresh each time.

### ===== tmux: managed.conf を生成して読み込ませる =====
if command -v tmux >/dev/null 2>&1 && [ -n "$HOME" ]; then
  mkdir -p "$HOME/.config/tmux"
  MANAGED="$HOME/.config/tmux/managed.conf"

  cat > "$MANAGED" <<'EOF_TMUX'
##### ===== ステータスバー（nano風）＋ウィンドウ番号強調 ===== #####

set -g status on
set -g status-bg black
set -g status-fg white
set -g status-interval 0

# ステータスバー左右の最大長（見切れ防止）
set -g status-left-length 100
set -g status-right-length 200

# ウィンドウ番号を強調（通常:白背景, 現在:黄背景）
setw -g window-status-format         "#[bg=white,fg=black,bold]#I#[default]:#W"
setw -g window-status-current-format "#[bg=yellow,fg=black,bold]#I#[default]:#W"

# 左：セッション名
set -g status-left  "#S | "
# 右：ペイン＆ウィンドウ操作ヘルプ
set -g status-right "% SplitH  \" SplitV  x KillPane  c NewWin  , RenameWin  ! BreakPane  { SwapPrev  } SwapNext  z Zoom  %H:%M %d-%b-%Y"

##### ===== 実用オプション ===== #####

set -g mouse on                      # マウスでスクロール/選択/ペイン切替
setw -g mode-keys vi                 # コピー＆スクロールモードを vi キー操作
set -g default-terminal "tmux-256color"
set -sa terminal-overrides ",xterm-256color:Tc"
set -s escape-time 0                 # Esc遅延なし（Vimの体感改善）
set -g history-limit 100000          # 履歴増量

##### ===== ペイン移動（Prefix不要・Alt+矢印） ===== #####

bind -n M-Left  select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up    select-pane -U
bind -n M-Down  select-pane -D

##### ===== ペイン番号表示時間（10秒） ===== #####
# Prefix+q でペイン番号表示（デフォルトキー）を10秒間に延長
set -g display-panes-time 10000

##### ===== コピー＆クリップボード連携（vi動作を明示） ===== #####

# 選択開始/行選択（vi風）
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi V send -X select-line

# Linux (X11): xclip使用・エラー抑止付き
bind -T copy-mode-vi y if-shell "command -v xclip >/dev/null" \
    "send -X copy-pipe-and-cancel 'xclip -selection clipboard -in'" \
    "send -X copy-selection-and-cancel"

# マウス操作での選択開始/行トリプルクリックコピー
bind -T copy-mode-vi MouseDrag1Pane   select-pane \; send -X begin-selection
bind -T copy-mode-vi TripleClick1Pane select-pane \; send -X select-line \; run-shell -d 0.3 \; \
    if-shell "command -v xclip >/dev/null" \
    "send -X copy-pipe-and-cancel 'xclip -selection clipboard -in'" \
    "send -X copy-selection-and-cancel"

##### ===== ペインサイズ変更（Shift+矢印） ===== #####
bind -n S-Left  resize-pane -L 3
bind -n S-Right resize-pane -R 3
bind -n S-Up    resize-pane -U 1
bind -n S-Down  resize-pane -D 1
EOF_TMUX

  # ~/.tmux.conf に取り込み行を保証（重複防止）
  if [ ! -f "$HOME/.tmux.conf" ] || ! grep -qF 'source-file ~/.config/tmux/managed.conf' "$HOME/.tmux.conf"; then
    printf '\n# auto-include managed tmux config\nsource-file ~/.config/tmux/managed.conf\n' >> "$HOME/.tmux.conf"
  fi

  # 既に tmux サーバが動いていれば即時反映（失敗は無視）
  tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true
fi

### ===== Vim: ~/.vimrc を生成 =====
mkdir -p "$HOME/.vim/backup" "$HOME/.vim/swap" "$HOME/.vim/undo"

cat > "$HOME/.vimrc" <<'EOF_VIM'
" =========================
" 基本設定
" =========================

" --- インデント ---
set expandtab
set tabstop=4
set shiftwidth=4

" --- 検索 ---
set ignorecase
set smartcase
set hlsearch
set incsearch

" --- 表示 ---
set number
set relativenumber
set cursorline
set showmatch
syntax on

" --- 操作性 ---
set clipboard=unnamedplus
set wildmenu
set mouse=a
set scrolloff=5

" --- 安全性 ---
set undofile
set backup
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set undodir=~/.vim/undo//

" --- ステータスライン（主要ショートカット表示） ---
set laststatus=2
set statusline=%f\ %y\ [%l/%L]\ %p%%\ \|\ yy:Copy\ p:Paste\ dd:Cut\ ggVG:AllSel\ v:CharSel\ u:Undo\ Ctrl+R:Redo\ J:Join\ :%%s/old/new/g:Replace\ :saveas\ filename:SaveAs

" =========================
" 使い方メモ（ヘルプ）
" =========================
"
" ■ インデント関連
"   - Tabキー → スペース4個挿入
"   - >> / <<  → 選択行を右/左にインデント
"
" ■ 検索関連
"   - /word    → 大小無視で検索
"   - /Word    → 大小区別で検索
"   - n / N    → 次 / 前の一致へ移動
"   - :nohlsearch → ハイライト解除
"
" ■ 移動関連
"   - 0 行頭 / ^ 先頭非空白 / $ 行末
"   - gg ファイル先頭 / G ファイル末尾
"   - 数字+j/k → 相対移動
"
" ■ コピー＆ペースト
"   - yy       → 行コピー
"   - p / P    → 後/前に貼り付け
"   - Ny y     → N行コピー（例:3yy）
"   - Ny d     → N行切り取り
"   - "+y / "+p→ システムクリップボード
"
" ■ 全選択
"   - ggVG     → 全文選択
"
" ■ 文字選択
"   - v        → 文字単位のビジュアル選択開始
"
" ■ 矩形選択
"   - Ctrl+v   → 矩形選択開始
"   - I        → 行頭一括挿入
"
" ■ Undo / Redo
"   - u        → 元に戻す
"   - Ctrl+r   → やり直す
"   - U        → 行単位Undo
"
" ■ 行の結合
"   - J        → 次の行を結合（空白あり）
"   - gJ       → 次の行を結合（空白なし）
"
" ■ レジスタ
"   - :registers → 全レジスタ確認
"   - "ayy / "ap → レジスタaにコピー / 貼り付け
"
" ■ マーク
"   - ma        → マークa設定
"   - 'a / `a   → マーク位置へ移動（行頭 / 正確）
"
" ■ 検索と置換
"   - :%s/old/new/g   → 全文置換
"   - :%s/old/new/gc  → 確認付き置換
"   - :'<,'>s/old/new/g → 選択範囲置換
"
" ■ ウィンドウ分割と移動
"   - :split file      → 横分割
"   - :vsplit file     → 縦分割
"   - Ctrl+w h/j/k/l   → ウィンドウ移動
"
" ■ ファイル操作
"   - :w filename      → 名前を付けて保存
"   - :saveas filename → 名前を付けて新規保存
"   - :r filename      → ファイル挿入
"   - :r !cmd          → コマンド結果挿入
"
" ■ その他
"   - :source ~/.vimrc → 設定再読み込み
"   - vimtutor         → チュートリアル
"
" =========================
EOF_VIM

https://u.pcloud.link/publink/show?code=XZj0aD5ZCXLFfepy2xLPdrlEnK1qn5kAcfYy
