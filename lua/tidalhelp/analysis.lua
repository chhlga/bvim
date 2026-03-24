local M = {}

local ns = vim.api.nvim_create_namespace('tidalhelp_analysis')

local kind_hl = {
  player   = 'TidalPlayer',
  ['function'] = 'TidalFunction',
  operator = 'TidalOperator',
  scale    = 'TidalScale',
  synth    = 'TidalSynth',
  sample   = 'TidalSample',
  pattern  = 'TidalPattern',
  number   = 'TidalNumber',
  keyword  = 'TidalKeyword',
  chord    = 'TidalSample',
  note     = 'TidalNumber',
}

local line_cache = {}
local hint_mark = {}

local timers = {}

local function debounce(key, ms, fn)
  if timers[key] then
    timers[key]:stop()
  end
  timers[key] = vim.defer_fn(function()
    timers[key] = nil
    fn()
  end, ms)
end

local function apply_highlights(bufnr, lnum, tokens)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, lnum, lnum + 1)

  for _, tok in ipairs(tokens) do
    local hl = kind_hl[tok.kind]
    if hl then
      vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, tok.start, {
        end_col = tok['end'],
        hl_group = hl,
        priority = 120,
      })
    end
  end
end

local function request_line(bufnr, lnum, line_text)
  local process = require('tidalhelp.process')
  if not process.is_running() then return end

  process.send('analyze ' .. line_text, function(raw)
    if not raw then return end
    local ok, resp = pcall(vim.json.decode, raw)
    if not ok or resp.type ~= 'analysis' then return end

    local tokens = resp.tokens or {}
    if not line_cache[bufnr] then line_cache[bufnr] = {} end
    line_cache[bufnr][lnum] = tokens

    if vim.api.nvim_buf_is_valid(bufnr) then
      apply_highlights(bufnr, lnum, tokens)
    end
  end)
end

function M.update(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, text in ipairs(lines) do
    local lnum = i - 1
    if text:match('%S') then
      request_line(bufnr, lnum, text)
    else
      if line_cache[bufnr] then line_cache[bufnr][lnum] = nil end
      vim.api.nvim_buf_clear_namespace(bufnr, ns, lnum, lnum + 1)
    end
  end
end

function M.update_cursor_hint(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  if hint_mark[bufnr] then
    pcall(vim.api.nvim_buf_del_extmark, bufnr, ns, hint_mark[bufnr])
    hint_mark[bufnr] = nil
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum = cursor[1] - 1
  local col  = cursor[2]

  local cache = line_cache[bufnr]
  if not cache or not cache[lnum] then return end

  local hint_text
  for _, tok in ipairs(cache[lnum]) do
    if col >= tok.start and col < tok['end'] then
      if tok.hint and tok.hint ~= '' then
        hint_text = tok.hint
      end
      break
    end
  end

  if not hint_text then return end

  local ok, mark_id = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, lnum, 0, {
    virt_text = { { '  → ' .. hint_text, 'TidalCursorHint' } },
    virt_text_pos = 'eol',
    priority = 110,
  })
  if ok then
    hint_mark[bufnr] = mark_id
  end
end

function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  vim.defer_fn(function()
    M.update(bufnr)
  end, 400)

  local group = vim.api.nvim_create_augroup('TidalAnalysis_' .. bufnr, { clear = true })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer = bufnr,
    group  = group,
    callback = function()
      debounce('update_' .. bufnr, 300, function()
        M.update(bufnr)
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    buffer = bufnr,
    group  = group,
    callback = function()
      debounce('hint_' .. bufnr, 80, function()
        M.update_cursor_hint(bufnr)
      end)
    end,
  })

  vim.api.nvim_create_autocmd('BufUnload', {
    buffer = bufnr,
    group  = group,
    once   = true,
    callback = function()
      line_cache[bufnr] = nil
      hint_mark[bufnr]  = nil
      timers['update_' .. bufnr] = nil
      timers['hint_'   .. bufnr] = nil
    end,
  })
end

function M.on_analysis(response, bufnr, lnum)
  if not bufnr or not lnum then return end
  local tokens = response.tokens or {}
  if not line_cache[bufnr] then line_cache[bufnr] = {} end
  line_cache[bufnr][lnum] = tokens
  if vim.api.nvim_buf_is_valid(bufnr) then
    apply_highlights(bufnr, lnum, tokens)
  end
end

return M
