#!/bin/bash
#This script is executed every time your instance is spawned.

#tmux.conf
# === tmux 設定を毎回用意＆読み込み（xclip優先／未導入は安全フォールバック） ===
if command -v tmux >/dev/null 2>&1 && [ -n "$HOME" ]; then
  mkdir -p "$HOME/.config/tmux"
  MANAGED="$HOME/.config/tmux/managed.conf"

  # xclip があればOSクリップボード連携、なければ内部バッファのみ
  if command -v xclip >/dev/null 2>&1; then
    CLIPLINE='bind -T copy-mode-vi y send -X copy-pipe-and-cancel "xclip -selection clipboard -in"'
  else
    CLIPLINE='bind -T copy-mode-vi y send -X copy-selection-and-cancel'
  fi

  # 管理用 tmux 設定を上書き生成（毎回最新化）
  cat > "$MANAGED" <<'EOF_TMUX'
##### ===== ステータスバー（nano風）＋ウィンドウ番号強調 ===== #####

set -g status on
set -g status-bg black
set -g status-fg white
set -g status-interval 0

# ステータスバー左右の最大長（見切れ防止）
set -g status-left-length 100
set -g status-right-length 150

# ウィンドウ番号を強調（通常:白背景, 現在:黄背景）
setw -g window-status-format         "#[bg=white,fg=black,bold]#I#[default]:#W"
setw -g window-status-current-format "#[bg=yellow,fg=black,bold]#I#[default]:#W"

# 左：セッション名
set -g status-left  "#S | "
# 右：nano風ヘルプ（見た目だけ。操作はtmuxデフォルト）
set -g status-right "^C New  ^X KillWin  ^W List  ^O SplitH  ^P SplitV  %H:%M %d-%b-%Y"

##### ===== 実用オプション ===== #####

set -g mouse on
setw -g mode-keys vi
set -g default-terminal "tmux-256color"
set -sa terminal-overrides ",xterm-256color:Tc,tmux-256color:Tc"
set -s escape-time 0
set -g history-limit 100000

##### ===== ペイン移動（Prefix不要・Alt+矢印） ===== #####

bind -n M-Left  select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up    select-pane -U
bind -n M-Down  select-pane -D

##### ===== コピー＆クリップボード連携（vi動作を明示） =====

bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi V send -X select-line
# ↓↓↓ この行は起動スクリプト側で $CLIPLINE に差し替えます ↓↓↓
__CLIPLINE_PLACEHOLDER__

# マウス操作：ドラッグで選択開始／トリプルクリック即コピー
bind -T copy-mode-vi MouseDrag1Pane   select-pane \; send -X begin-selection
bind -T copy-mode-vi TripleClick1Pane select-pane \; send -X select-line \; send -X copy-pipe-and-cancel

##### ===== （任意）ペインサイズ変更：Shift+矢印 =====
bind -n S-Left  resize-pane -L 3
bind -n S-Right resize-pane -R 3
bind -n S-Up    resize-pane -U 1
bind -n S-Down  resize-pane -D 1
EOF_TMUX

  # クリップボード行を差し替え
  sed -i "s|__CLIPLINE_PLACEHOLDER__|$CLIPLINE|" "$MANAGED"

  # ~/.tmux.conf に取り込み行を保証
  if [ ! -f "$HOME/.tmux.conf" ] || ! grep -qF 'source-file ~/.config/tmux/managed.conf' "$HOME/.tmux.conf"; then
    printf '\n# auto-include managed tmux config\nsource-file ~/.config/tmux/managed.conf\n' >> "$HOME/.tmux.conf"
  fi

  # 既に tmux サーバが動いていれば即時反映（失敗は無視）
  tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true
fi
# === /tmux 設定自動適用 ===



#vimrc
# ====== ~/.vimrc 自動生成 ======
mkdir -p ~/.vim/backup ~/.vim/swap ~/.vim/undo

cat > ~/.vimrc <<'EOF_VIM'
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

" =========================
" 使い方メモ（ヘルプ）
" =========================
" （以下、コメントなのでVim内で :help 的に確認できます）

" ■ インデント関連
"   - Tabキー → スペース4個挿入
"   - >> / <<  → インデント増減

" ■ 検索関連
"   - /word    → 大小無視検索
"   - /Word    → 大小区別検索
"   - n / N    → 次 / 前の一致へ
"   - :nohlsearch → ハイライト解除

" ■ 移動関連
"   - 数字+j/k → 相対移動
"   - 0/^/$    → 行頭/先頭非空白/行末

" ■ コピー＆ペースト
"   - yy       → 行コピー
"   - p / P    → 貼り付け
"   - V + 矢印 → 範囲選択 → y / d

" ■ 矩形選択
"   - Ctrl+v   → 矩形選択
"   - I        → 行頭一括挿入

" ■ Undo / Redo
"   - u        → 元に戻す
"   - Ctrl+r   → やり直す
"   - U        → 行単位Undo

" ■ その他
"   - :source ~/.vimrc → 再読み込み
"   - vimtutor         → チュートリアル開始
" =========================
EOF_VIM

