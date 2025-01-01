local json = require("json")
local http = require("simplehttp")
http.TIMEOUT = 0.5

local processor = {}
local translator = {}

local flag = false
local shortcut_key = "Control+y"
local memory
local commit_notifier

local function make_url(input, bg, ed)
  return 'https://olime.baidu.com/py?input=' .. input ..
      '&inputtype=py&bg=' .. bg .. '&ed=' .. ed ..
      '&result=hanzi&resultcoding=utf-8&ch_en=0&clientinfo=web&version=1'
end

---@param env Env
function processor.init(env)
  local config = env.engine.schema.config
  shortcut_key = config:get_string(env.name_space:match("%*(.-)%*") .. "/shortcut_key") or
      shortcut_key
  flag = false
end

---@param key KeyEvent
---@param env Env
function processor.func(key, env)
  local KEY_ACCEPTED = 1
  local KEY_NOOP = 2
  local context = env.engine.context
  if key:repr() == shortcut_key and context:is_composing() then
    flag = true
    context:refresh_non_confirmed_composition()
    return KEY_ACCEPTED
  end
  return KEY_NOOP
end

---@param env Env
function translator.init(env)
  local engine = env.engine
  memory = Memory(engine, engine.schema)

  -- 提交通知器，用户选词时触发回调
  commit_notifier = engine.context.commit_notifier:connect(function(ctx)
    local commit = ctx.commit_history:back()
    if commit and commit.type:sub(1, 13) == "cloud_pinyin:" then
      local dict_entry = DictEntry()
      dict_entry.text = commit.text
      dict_entry.custom_code = commit.type:sub(14) .. " "

      -- see https://github.com/hchunhui/librime-lua/commit/43229d766f1e0f3198f61dc9d2e38bc1f921387f
      memory:start_session()
      memory:update_userdict(dict_entry, 1, "")
      memory:finish_session()
    end
  end)
end

---@param input string
---@param seg Segment
---@param env Env
function translator.func(input, seg, env)
  if not flag then
    return
  end
  flag = false

  local url = make_url(input, 0, 5)
  local res = http.request(url)
  local _, j = pcall(json.decode, res)
  if j.status == "T" and j.result and j.result[1] then
    for _, v in ipairs(j.result[1]) do
      local code = string.gsub(v[3].pinyin, "'", " ")
      local c = Candidate("cloud_pinyin:" .. code, seg.start, seg.start + v[2], v[1], "(云输入)")

      c.quality = 99
      c.preedit = code
      yield(c)
    end
  end
end

---@param env Env
function translator.fini(env)
  commit_notifier:disconnect()
  memory:disconnect()
end

return { processor = processor, translator = translator }
