local M = {}

local function cargo_metadata(root)
  local out = vim.fn.system({ "cargo", "metadata", "--no-deps", "--format-version", "1" }, root)
  if vim.v.shell_error ~= 0 then
    error(out)
  end
  return vim.json.decode(out)
end

local function select_bin(meta)
  local items = {}
  for _, pkg in ipairs(meta.packages) do
    for _, tgt in ipairs(pkg.targets) do
      if vim.tbl_contains(tgt.kind or {}, "bin") then
        table.insert(items, {
          label = pkg.name .. ":" .. tgt.name,
          pkg = pkg.name,
          bin = tgt.name,
        })
      end
    end
  end

  local choice
  vim.ui.select(items, {
    prompt = "选择 cargo bin",
    format_item = function(i) return i.label end,
  }, function(c) choice = c end)

  vim.wait(10000, function() return choice end)
  return choice
end

function M.cargo_program(opts)
  opts = opts or {}
  return function()
    local root = vim.fs.root(0, { "Cargo.toml" })
    assert(root, "Cargo.toml not found")

    local meta = cargo_metadata(root)
    local pkg, bin

    if opts.bin then
      bin = opts.bin
      pkg = opts.package or bin
    else
      local sel = select_bin(meta)
      pkg, bin = sel.pkg, sel.bin
    end

    vim.fn.system({ "cargo", "build", "-p", pkg, "--bin", bin }, root)
    if vim.v.shell_error ~= 0 then
      error("cargo build failed")
    end

    return meta.target_directory .. "/debug/" .. bin
  end
end

return M
