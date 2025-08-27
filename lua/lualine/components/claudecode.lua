-- Claude Code のステータスを lualine に表示するコンポーネント
-- lualine.component を継承して実装
local M = require('lualine.component'):extend()

-- グローバル状態管理
-- 複数のlualineインスタンス間で状態を共有するため
_G.claudecode_lualine_state = _G.claudecode_lualine_state or {
  request_state = 'idle',
  terminal_buffers = {},  -- 複数のターミナルバッファを追跡
  last_content = {},      -- 各バッファの最後のコンテンツ
  timer = nil,
}

-- デフォルトオプション
-- ユーザーは lualine の設定でこれらをカスタマイズできます
local default_options = {
  icons = {
    idle = '○',         -- アイドル状態（リクエストなし）
    busy = '●',         -- 処理中（Claude が作業中）
    wait = '◐',         -- 待機中（レスポンス待ち）
    disconnected = '✕', -- 未接続（サーバー停止中）
  },
  colors = {
    idle = nil,                  -- デフォルトカラーを使用
    busy = 'DiagnosticInfo',     -- 処理中: 青色系
    wait = 'DiagnosticWarn',     -- 待機中: 黄色系
    disconnected = 'DiagnosticError', -- 未接続: 赤色系
  },
  show_status_text = false,      -- true にすると "Claude: idle" のようなテキストも表示
}

-- コンポーネントの初期化
-- lualine からオプションを受け取り、デフォルト値とマージします
function M:init(options)
  M.super.init(self, options)
  -- ユーザー設定とデフォルト設定をマージ
  self.options = vim.tbl_deep_extend('force', default_options, options or {})
  self.status_cache = nil          -- ステータスのキャッシュ
  self.last_update = 0             -- 最後の更新時刻
  self.update_interval = 100       -- 更新間隔（ミリ秒）
  
  -- ターミナル監視を開始（一度だけ）
  if not _G.claudecode_lualine_state.timer then
    self:setup_terminal_monitoring()
  end
end

-- ターミナル監視をセットアップ
function M:setup_terminal_monitoring()
  local augroup = vim.api.nvim_create_augroup('ClaudeCodeLualine', { clear = true })
  
  -- ターミナルバッファを自動検出
  vim.api.nvim_create_autocmd({"TermOpen", "BufEnter", "BufWinEnter"}, {
    group = augroup,
    callback = function(event)
      local bufname = vim.api.nvim_buf_get_name(event.buf)
      -- Claude/Serena terminal detection (case insensitive)
      if vim.bo[event.buf].buftype == 'terminal' and 
         (bufname:lower():match("claude") or bufname:lower():match("serena")) then
        -- ターミナルバッファを登録
        _G.claudecode_lualine_state.terminal_buffers[event.buf] = true
        _G.claudecode_lualine_state.last_content[event.buf] = ""
      end
    end,
  })
  
  -- バッファが削除されたら追跡リストから削除
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(event)
      _G.claudecode_lualine_state.terminal_buffers[event.buf] = nil
      _G.claudecode_lualine_state.last_content[event.buf] = nil
    end,
  })
  
  -- シンプルなタイマーベースの監視
  local timer = vim.loop.new_timer()
  _G.claudecode_lualine_state.timer = timer
  
  timer:start(0, 200, vim.schedule_wrap(function()
    M:check_all_terminals()
  end))
end

-- すべてのターミナルをチェック
function M:check_all_terminals()
  local has_activity = false
  local has_valid_terminal = false
  
  -- 各ターミナルバッファをチェック
  for buf, _ in pairs(_G.claudecode_lualine_state.terminal_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      has_valid_terminal = true
      
      -- ジョブが実行中かチェック
      local ok, job_id = pcall(vim.api.nvim_buf_get_var, buf, 'terminal_job_id')
      if ok and job_id then
        local job_info = vim.fn.jobwait({job_id}, 0)
        if job_info and job_info[1] == -1 then -- ジョブが実行中
          -- 最後の数行を取得
          local ok_lines, lines = pcall(vim.api.nvim_buf_get_lines, buf, -20, -1, false)
          if ok_lines then
            -- 内容をチェック
            local current_content = table.concat(lines, "\n")
            local last_content = _G.claudecode_lualine_state.last_content[buf] or ""
            
            -- 内容が変更されていたらアクティビティあり
            if current_content ~= last_content then
              has_activity = true
              _G.claudecode_lualine_state.last_content[buf] = current_content
              
              -- デバッグ出力
              if vim.g.claudecode_lualine_debug then
                vim.notify(string.format('[ClaudeCodeLualine] Content changed in buffer %d', buf), vim.log.levels.INFO)
              end
            else
              -- 変更がない場合、プロンプトをチェック
              local is_at_prompt = M:check_prompt(lines)
              if is_at_prompt and not has_activity then
                -- プロンプトで待機中 = アイドル
                has_activity = false
              end
            end
          end
        end
      end
    else
      -- 無効なバッファは削除
      _G.claudecode_lualine_state.terminal_buffers[buf] = nil
      _G.claudecode_lualine_state.last_content[buf] = nil
    end
  end
  
  -- 状態を更新
  if has_activity then
    if _G.claudecode_lualine_state.request_state ~= 'busy' then
      _G.claudecode_lualine_state.request_state = 'busy'
      vim.cmd('redrawstatus!')
    end
  else
    if _G.claudecode_lualine_state.request_state ~= 'idle' then
      _G.claudecode_lualine_state.request_state = 'idle'
      vim.cmd('redrawstatus!')
    end
  end
end

-- プロンプトをチェック
function M:check_prompt(lines)
  -- 最後の非空行を探す
  for i = #lines, 1, -1 do
    local line = lines[i]
    if line and line:match("%S") then
      -- プロンプトパターン
      local prompts = {
        ">%s*$",           -- Simple prompt
        "❯%s*$",          -- Modern prompt  
        "[Cc]laude[>:]%s*$", -- Claude prompt
        "[Ss]erena[>:]%s*$", -- Serena prompt
        "%$%s*$",          -- Shell prompt
        "^%s*[%w@%-%_]+[>#$]%s*$", -- User@host prompt
      }
      
      for _, pattern in ipairs(prompts) do
        if line:match(pattern) then
          return true
        end
      end
      return false
    end
  end
  return true -- 空の場合もアイドルとみなす
end

-- Claude Code の現在のステータスを取得
-- パフォーマンスのためキャッシュを使用
function M:get_claudecode_status()
  local current_time = vim.loop.now()
  
  -- 最近のキャッシュがあればそれを使用（パフォーマンス最適化）
  if self.status_cache and (current_time - self.last_update < self.update_interval) then
    return self.status_cache
  end
  
  -- ステータスはグローバル状態から取得
  local status = _G.claudecode_lualine_state.request_state or 'idle'
  
  -- キャッシュを更新して返す
  self.status_cache = {
    status = status,
    connected = true,
  }
  self.last_update = current_time
  return self.status_cache
end

-- lualine が呼び出すステータス更新関数
-- 現在の状態に応じたアイコンと色を返します
function M:update_status()
  local claude_status = self:get_claudecode_status()
  
  -- デバッグ: ステータスをログ出力（デバッグモードの場合のみ）
  if vim.g.claudecode_lualine_debug then
    vim.notify(string.format('[ClaudeCodeLualine] update_status: status=%s, request_state=%s', 
      claude_status.status, _G.claudecode_lualine_state.request_state), vim.log.levels.INFO)
  end
  
  -- 状態に応じたアイコンを選択
  local icon = self.options.icons[claude_status.status] or self.options.icons.disconnected
  local color = self.options.colors[claude_status.status]
  
  -- テキスト表示オプションが有効な場合は状態名も表示
  local text = icon
  if self.options.show_status_text then
    text = string.format('Claude: %s %s', icon, claude_status.status)
  end
  
  -- 色が指定されている場合はハイライトグループを適用
  if color then
    self.status = self:format_hl(color) .. text
  else
    self.status = text
  end
  
  return self.status
end

-- ハイライトグループをフォーマット
-- lualine が認識できる形式に変換
function M:format_hl(name)
  return '%#' .. name .. '#'
end

return M