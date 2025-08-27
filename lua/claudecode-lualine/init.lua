-- claudecode-lualine のメインモジュール
-- プラグインのエントリーポイントとバージョン情報を提供
local M = {}

-- プラグインのバージョン
M.version = "0.1.0"

-- スタンドアロン使用のためのセットアップ関数
-- （通常 lualine コンポーネントでは必要ありませんが、将来の拡張のため用意）
function M.setup(opts)
  -- 現在は特別なセットアップは不要
end

-- lualine コンポーネントを取得
-- 他のプラグインから直接コンポーネントを使用したい場合に便利
function M.get_component()
  return require('lualine.components.claudecode')
end

return M