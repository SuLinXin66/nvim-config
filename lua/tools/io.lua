local function read_file(filepath, allow_empty_content)
  allow_empty_content = allow_empty_content or false
  local ok, content = pcall(vim.fn.readfile, filepath)
  if not ok then
    return nil, "Failed to read file: " .. filepath
  end

  if not allow_empty_content and #content == 0 then
    return nil, "File is empty: " .. filepath
  end

  return content
end

local M = {}

function M.read_json_to_table(filepath)
  local content, err = read_file(filepath)
  if err ~= nil or content == nil then
    return nil, err
  end

  local json_str = table.concat(content, "\n")

  local ok, result = pcall(vim.fn.json_decode, json_str)
  if not ok then
    return nil, "Failed to decode JSON: " .. result
  end

  return result
end

function M.read_env_file_to_table(filepath)
  local content, err = read_file(filepath)
  if err ~= nil or content == nil then
    return nil, err
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

function M.get_cwd_file_path()
  local cwd = vim.fn.getcwd()
  return cwd:gsub(":", ""):gsub("[/\\]", "%%")
end

function M.get_state_file_path(tag, filename)
  tag = tag or ""
  filename = filename or M.get_cwd_file_path()
  if tag ~= "" then
    return vim.fs.joinpath(vim.fn.stdpath("state"), tag, filename)
  end
  return vim.fs.joinpath(vim.fn.stdpath("state"), filename)
end

return M
