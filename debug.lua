-- Debug helper for claudecode-lualine

-- Enable debug mode
vim.g.claudecode_lualine_debug = true

-- Add a command to check status
vim.api.nvim_create_user_command('ClaudeCodeStatus', function()
  print("=== ClaudeCode Lualine Status ===")
  print("request_state: " .. tostring(_G.claudecode_lualine_state.request_state))
  print("terminal_buffers count: " .. vim.tbl_count(_G.claudecode_lualine_state.terminal_buffers))
  
  -- Check all terminals
  for buf, _ in pairs(_G.claudecode_lualine_state.terminal_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      local bufname = vim.api.nvim_buf_get_name(buf)
      print("\nTerminal buffer " .. tostring(buf) .. ": " .. bufname)
      
      -- Check job status
      local ok, job_id = pcall(vim.api.nvim_buf_get_var, buf, 'terminal_job_id')
      if ok and job_id then
        local job_info = vim.fn.jobwait({job_id}, 0)
        print("  job_id: " .. tostring(job_id))
        print("  job_status: " .. tostring(job_info and job_info[1]))
      end
      
      -- Get last lines
      local ok_lines, lines = pcall(vim.api.nvim_buf_get_lines, buf, -10, -1, false)
      if ok_lines then
        print("  Last 10 lines:")
        for i, line in ipairs(lines) do
          print(string.format("    [%d] '%s' (len=%d)", i, line, #line))
        end
        
        -- Check state
        local comp = require('lualine.components.claudecode')
        local state = comp:detect_state_from_lines(lines)
        print("  Detected state: " .. state)
        
        -- Show lines with patterns
        print("  Pattern check:")
        for _, line in ipairs(lines) do
          if line:lower():match("esc to interrupt") then
            print("    [BUSY] " .. line)
          elseif line:match("│%s*Do you want") or line:match("│%s*Would you like") then
            print("    [WAIT] " .. line)
          end
        end
      end
    end
  end
end, {})

-- Add command to manually trigger activity check  
vim.api.nvim_create_user_command('ClaudeCodeCheck', function()
  print("Running check_all_terminals...")
  local comp = require('lualine.components.claudecode')
  comp:check_all_terminals()
  print("Done. New state: " .. tostring(_G.claudecode_lualine_state.request_state))
end, {})

-- Add command to reset state
vim.api.nvim_create_user_command('ClaudeCodeReset', function()
  _G.claudecode_lualine_state.request_state = 'idle'
  vim.cmd('redrawstatus!')
  print("Reset to idle state")
end, {})

-- Add command to force busy state
vim.api.nvim_create_user_command('ClaudeCodeBusy', function()
  _G.claudecode_lualine_state.request_state = 'busy'
  vim.cmd('redrawstatus!')
  print("Set to busy state")
end, {})

-- Add command to force wait state
vim.api.nvim_create_user_command('ClaudeCodeWait', function()
  _G.claudecode_lualine_state.request_state = 'wait'
  vim.cmd('redrawstatus!')
  print("Set to wait state")
end, {})

print("Debug commands loaded:")
print("  :ClaudeCodeStatus - Show current status")
print("  :ClaudeCodeCheck - Manually check terminal activity")
print("  :ClaudeCodeReset - Reset to idle state")
print("  :ClaudeCodeBusy - Force busy state")
print("  :ClaudeCodeWait - Force wait state")