-- Test script for claudecode-lualine status updates

-- Load debug commands
dofile(vim.fn.expand('~/dev_plugin/claudecode-lualine.nvim/debug.lua'))

print("\n=== Testing claudecode-lualine status updates ===\n")

-- Test sequence
print("1. Initial status check:")
vim.cmd('ClaudeCodeStatus')

print("\n2. Testing different states:")
print("   Setting to busy...")
vim.cmd('ClaudeCodeBusy')
vim.wait(500)

print("   Setting to wait...")
vim.cmd('ClaudeCodeWait')
vim.wait(500)

print("   Setting to idle...")
vim.cmd('ClaudeCodeReset')
vim.wait(500)

print("\n3. Running automatic check:")
vim.cmd('ClaudeCodeCheck')

print("\n=== Pattern Detection Test ===")
print("The plugin looks for these patterns:")
print("- BUSY: 'esc to interrupt' (case insensitive)")
print("- WAIT: '│ Do you want', '│ Would you like', '│ Select', '│ Choose'")
print("- IDLE: When none of above patterns are found")

print("\n=== Test complete ===")
print("Watch your statusline to see if the icon changes!")
print("The icon meanings:")
print("  ○ = idle")
print("  ● = busy (Claude is processing)")
print("  ◐ = wait (Claude is waiting for your response)")
print("\nTry running Claude/Serena commands to see real-time updates!")