local M = {}

function M.AdjustHeaderLevels(adjustment, remove_level_one)
  -- adjustment: positive to increase, negative to decrease
  -- remove_level_one: only matters when decreasing, determines what happens to level 1 headers
  
  local in_code_block = false
  local line_count = vim.api.nvim_buf_line_count(0)
  
  for line_num = 1, line_count do
    local current_line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    
    -- Check if we're entering or leaving a code block
    if string.match(current_line, "^```") then
      in_code_block = not in_code_block
    elseif not in_code_block and string.match(current_line, "^#+") then
      if adjustment > 0 then
        -- Increase header level: add adjustment number of # characters
        local prefix = string.rep("#", adjustment)
        vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {prefix .. current_line})
      else
        -- Decrease header level
        local header_level = 0
        for _ in string.gmatch(current_line, "#") do
          header_level = header_level + 1
        end
        
        -- Calculate new level, ensuring it doesn't go below 1 unless remove_level_one is true
        local new_level = math.max(header_level + adjustment, remove_level_one and 0 or 1)
        
        if new_level == 0 then
          -- Convert to regular text
          local new_line = string.gsub(current_line, "^#+%s*", "")
          vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {new_line})
        else
          -- Generate new header
          local new_prefix = string.rep("#", new_level)
          local content = string.gsub(current_line, "^#+%s*", "")
          vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {new_prefix .. " " .. content})
        end
      end
    end
  end
end

return M
