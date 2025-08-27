# claudecode-lualine.nvim

[Claude Code](https://github.com/coder/claudecode.nvim) の状態を [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) のステータスラインに表示するコンポーネントです。

A [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) component that displays the status of [Claude Code](https://github.com/coder/claudecode.nvim) in your statusline.

## 機能 / Features

- Claude Code のステータスをリアルタイムで表示
- 各状態に対応するカスタマイズ可能なアイコン:
  - `○` アイドル (リクエストなし)
  - `●` 処理中
  - `◐` レスポンス待機中
  - `✕` 未接続
- 各状態の色をカスタマイズ可能
- キャッシュによる最小限のパフォーマンス影響

- Real-time Claude Code status display
- Customizable icons for different states:
  - `○` Idle (no active requests)
  - `●` Busy (processing)
  - `◐` Waiting (for response)
  - `✕` Disconnected
- Customizable colors for each state
- Minimal performance impact with status caching

## インストール / Installation

[lazy.nvim](https://github.com/folke/lazy.nvim) を使用する場合:

```lua
{
  'ishiooon/claudecode-lualine.nvim',
  dependencies = {
    'nvim-lualine/lualine.nvim',
    'coder/claudecode.nvim',
  },
}
```

## 設定 / Configuration

lualine の設定にコンポーネントを追加してください:

```lua
require('lualine').setup {
  sections = {
    lualine_x = {
      {
        'claudecode',
        icons = {
          idle = '○',
          busy = '●', 
          wait = '◐',
          disconnected = '✕',
        },
        colors = {
          idle = nil, -- Use default color
          busy = 'DiagnosticInfo',
          wait = 'DiagnosticWarn', 
          disconnected = 'DiagnosticError',
        },
        show_status_text = false, -- Set to true to show "Claude: idle" etc.
      },
      'encoding',
      'fileformat',
      'filetype',
    },
  },
}
```

## オプション / Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `icons.idle` | string | `○` | Icon when Claude Code is idle |
| `icons.busy` | string | `●` | Icon when Claude Code is processing |
| `icons.wait` | string | `◐` | Icon when waiting for Claude's response |
| `icons.disconnected` | string | `✕` | Icon when Claude Code is not connected |
| `colors.idle` | string/nil | `nil` | Highlight group for idle state |
| `colors.busy` | string | `DiagnosticInfo` | Highlight group for busy state |
| `colors.wait` | string | `DiagnosticWarn` | Highlight group for waiting state |
| `colors.disconnected` | string | `DiagnosticError` | Highlight group for disconnected state |
| `show_status_text` | boolean | `false` | Show text description alongside icon |

## 動作原理 / How it Works

このプラグインは Claude Code の WebSocket サーバーステータスを監視して現在の状態を判定します。ステータスはキャッシュされ、パフォーマンスへの影響を最小限にするため定期的に更新されます。

This plugin monitors the WebSocket server status of Claude Code to determine its current state. The status is cached and updated at regular intervals to minimize performance impact.

## トラブルシューティング / Troubleshooting

### ステータスが常にアイドルと表示される場合

1. **Claude Code が正しく接続されているか確認**:
   ```vim
   :lua print(vim.inspect(require('claudecode.server.init').get_status()))
   ```

2. **デバッグモードを有効にして状態の更新を確認**:
   ```bash
   export CLAUDECODE_LUALINE_DEBUG=1
   nvim
   ```

3. **シンプルな実装を試す**:
   デフォルトのコンポーネントが動作しない場合は、シンプル版を使用してみてください:
   ```lua
   require('lualine').setup {
     sections = {
       lualine_c = {
         {
           require('lualine.components.claudecode_simple'),
           -- 同じオプションを使用
         },
       },
     },
   }
   ```

4. **手動でステータスをチェック**:
   ```vim
   :lua local c = require('lualine.components.claudecode'):new()
   :lua print(c:update_status())
   ```

### 既知の問題

- Claude Code が期待されるイベントを発火しない場合、ステータスがリアルタイムで更新されない可能性があります
- 現在、プラグインは WebSocket サーバーのステータスとターミナルアクティビティを監視しています
- 最も正確なステータスのためには、Claude Code が適切なイベントを発火する必要があります

## ライセンス / License

MIT License - see [LICENSE](LICENSE) for details.

## 貢献 / Contributing

貢献を歓迎します！イシューやプルリクエストはお気軽にどうぞ。

Contributions are welcome! Please feel free to submit issues or pull requests.

## 作者 / Author

[ishiooon](https://github.com/ishiooon)

## 謝辞 / Acknowledgments

このプラグインは以下の素晴らしいプロジェクトなしでは実現できませんでした：

- [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
- [Claude Code](https://github.com/coder/claudecode.nvim)
- [ccmanager](https://github.com/kbwo/ccmanager)
- [Neovim](https://neovim.io/)

This plugin wouldn't be possible without these amazing projects:

- [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
- [Claude Code](https://github.com/coder/claudecode.nvim)
- [ccmanager](https://github.com/kbwo/ccmanager)
- [Neovim](https://neovim.io/)
