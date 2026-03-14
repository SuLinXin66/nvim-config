local M = {}

function M.read_json_to_table(file_path)
  local content = vim.fn.readfile(file_path)
  if not content then
    return nil, "Failed to read file: " .. file_path
  end

  local json_str = table.concat(content, "\n")
  local ok, result = pcall(vim.fn.json_decode, json_str)
  if not ok then
    return nil, "Failed to decode JSON: " .. result
  end

  return result
end

function M.read_env_file_to_table(file_path)
  local content = vim.fn.readfile(file_path)
  if not content then
    return nil, "Failed to read file: " .. file_path
  end

  local result = {}
  for _, line in ipairs(content) do
    local key, value = line:match("^%s*([^=]+)%s*=%s*(.*)%s*$")
    if key and value then
      result[key] = value
    end
  end

  return result
end

return M
