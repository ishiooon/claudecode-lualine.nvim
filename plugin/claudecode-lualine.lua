-- claudecode-lualine.nvim プラグインのエントリーポイント
-- このファイルはプラグインの二重読み込みを防ぎます
if vim.g.loaded_claudecode_lualine then
  return
end
vim.g.loaded_claudecode_lualine = 1

-- プラグインは lualine の設定で require されたときに自動的に読み込まれます
-- 実際のコンポーネント実装は lua/lualine/components/claudecode.lua にあります