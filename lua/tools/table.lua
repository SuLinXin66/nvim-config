local M = {}

---判断一个值是否为普通 table
---@param v any
---@return boolean
local function is_table(v)
  return type(v) == "table"
end

---递归合并两个对象
---1. target: 要被覆盖/补充的对象
---2. source: 参考对象
---3. force:
---   - false: 仅当 target 中对应 key 为 nil 时，才使用 source 的值
---   - true : 直接使用 source 覆盖 target
---
---返回一个新对象，不会修改传入的 target/source
---
---@param target table|nil
---@param source table|nil
---@param force boolean|nil
---@return table
function M.merge(target, source, force)
  force = force == true

  local result = vim.deepcopy(target or {})

  if not is_table(source) then
    return result
  end

  for key, source_value in pairs(source) do
    local target_value = result[key]

    -- 两边都是 table：递归合并
    if is_table(target_value) and is_table(source_value) then
      result[key] = M.merge(target_value, source_value, force)

    -- force=true：无条件用 source 覆盖
    elseif force then
      result[key] = vim.deepcopy(source_value)

    -- force=false：仅在 target[key] == nil 时补充
    elseif target_value == nil then
      result[key] = vim.deepcopy(source_value)
    end
  end

  return result
end

return M
