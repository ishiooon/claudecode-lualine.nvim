-- Simplified Claude Code status component for lualine
local M = require('lualine.component'):extend()

-- Default options
local default_options = {
  icons = {
    idle = '○',
    busy = '●',
    wait = '◐', 
    disconnected = '✕',
  },
  colors = {
    idle = nil,
    busy = 'DiagnosticInfo',
    wait = 'DiagnosticWarn',
    disconnected = 'DiagnosticError',
  },
  show_status_text = false,
}

function M:init(options)
  M.super.init(self, options)
  self.options = vim.tbl_deep_extend('force', default_options, options or {})
end

function M:get_status()
  -- Check if claudecode module exists
  local ok, claudecode = pcall(require, 'claudecode')
  if not ok then
    return 'disconnected'
  end
  
  -- Check server status
  local server_ok, server = pcall(require, 'claudecode.server.init')
  if not server_ok or not server.get_status then
    return 'disconnected'
  end
  
  local status = server.get_status()
  
  if not status.running then
    return 'disconnected'
  elseif status.client_count > 0 then
    -- Check if any terminal buffer contains Claude
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
        if buftype == 'terminal' then
          local bufname = vim.api.nvim_buf_get_name(buf)
          if bufname:match('[Cc]laude') then
            -- Check if the terminal is active
            local wins = vim.fn.win_findbuf(buf)
            if #wins > 0 then
              -- Terminal is visible, assume busy
              return 'wait'
            end
          end
        end
      end
    end
    return 'idle'
  else
    return 'idle'
  end
end

function M:update_status()
  local status = self:get_status()
  local icon = self.options.icons[status] or self.options.icons.disconnected
  local color = self.options.colors[status]
  
  local text = icon
  if self.options.show_status_text then
    text = string.format('Claude: %s %s', icon, status)
  end
  
  if color then
    return '%#' .. color .. '#' .. text
  else
    return text
  end
end

return M