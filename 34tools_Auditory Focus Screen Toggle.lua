-- Auditory Focus Screen (34tools)
-- Line: 34tools Edit
-- 34tools — Audio Tools by Alexey Vorobyov (34birds)
-- @version 1.0.0
-- @author Alexey Vorobyov (34birds)
-- @about
--   Part of 34tools (34tools Edit). REAPER Lua script. No js_ReaScriptAPI required.
-- @description 34tools: Auditory Focus Screen — One-track visual “focus blanket” for listening (fills screen). Line: 34tools Edit. Version: 1.0.0. License: MIT.
-- @license MIT

local r = reaper
local proj = 0

-- ===== Config =====
local EXT_KEY = "P_EXT:34tools_audfocus_single"
local EXT_VAL = "1"

local TRACK_NAME = "∪＾ェ＾∪"

-- Calm solid color (RGB 0..255)
local SOLID_R, SOLID_G, SOLID_B = 60, 60, 60

-- If project is empty/short, still create a visible item
local MIN_LEN = 30.0

-- Make it VERY tall to "fill the screen"
-- (REAPER clamps internally to what fits, so "very large" is enough)
local TRACK_HEIGHT = 2000

-- Arrange view span around cursor (seconds)
local VIEW_SPAN = 180.0

-- ===== Helpers =====
local function set_track_color(track, rr, gg, bb)
  local native = r.ColorToNative(rr, gg, bb)
  r.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", native | 0x1000000)
end

local function set_item_color(item, rr, gg, bb)
  local native = r.ColorToNative(rr, gg, bb)
  r.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", native | 0x1000000)
end

local function set_track_ext(track, key, val)
  r.GetSetMediaTrackInfo_String(track, key, val, true)
end

local function get_track_ext(track, key)
  local ok, val = r.GetSetMediaTrackInfo_String(track, key, "", false)
  if ok then return val end
  return ""
end

local function select_only_track(tr)
  r.Main_OnCommand(40297, 0) -- unselect all tracks
  if tr then r.SetOnlyTrackSelected(tr) end
end

-- Save/restore selection + arrange view
local function save_context()
  local sel = r.GetSelectedTrack(proj, 0)
  local prev_guid = sel and r.GetTrackGUID(sel) or ""
  r.SetProjExtState(proj, "34tools_audfocus", "prev_guid", prev_guid)

  local start_t, end_t = r.GetSet_ArrangeView2(proj, false, 0, 0, 0, 0)
  r.SetProjExtState(proj, "34tools_audfocus", "view_start", tostring(start_t))
  r.SetProjExtState(proj, "34tools_audfocus", "view_end", tostring(end_t))
end

local function restore_context()
  local _, s = r.GetProjExtState(proj, "34tools_audfocus", "view_start")
  local _, e = r.GetProjExtState(proj, "34tools_audfocus", "view_end")
  local start_t = tonumber(s or "")
  local end_t   = tonumber(e or "")
  if start_t and end_t and end_t > start_t then
    r.GetSet_ArrangeView2(proj, true, 0, 0, start_t, end_t)
  end

  local _, prev_guid = r.GetProjExtState(proj, "34tools_audfocus", "prev_guid")
  if prev_guid and prev_guid ~= "" then
    local n = r.CountTracks(proj)
    for i = 0, n - 1 do
      local tr = r.GetTrack(proj, i)
      if tr and r.GetTrackGUID(tr) == prev_guid then
        select_only_track(tr)
        break
      end
    end
  end
end

local function find_focus_track()
  local n = r.CountTracks(proj)
  for i = 0, n - 1 do
    local tr = r.GetTrack(proj, i)
    if tr and get_track_ext(tr, EXT_KEY) == EXT_VAL then
      return tr, i
    end
  end
  return nil, -1
end

local function delete_focus_track(idx)
  local tr = r.GetTrack(proj, idx)
  if tr then r.DeleteTrack(tr) end
end

local function set_arrange_view_span_around_cursor()
  local t = r.GetCursorPosition()
  local half = VIEW_SPAN * 0.5
  local a = math.max(0, t - half)
  local b = a + VIEW_SPAN
  r.GetSet_ArrangeView2(proj, true, 0, 0, a, b)
end

-- ===== Create =====
local function create_single_focus()
  save_context()

  local proj_len = r.GetProjectLength(proj)
  local item_len = math.max(MIN_LEN, proj_len)

  -- Insert at TOP
  r.InsertTrackAtIndex(0, true)
  local tr = r.GetTrack(proj, 0)

  set_track_ext(tr, EXT_KEY, EXT_VAL)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", TRACK_NAME, true)

  r.SetMediaTrackInfo_Value(tr, "I_HEIGHTOVERRIDE", TRACK_HEIGHT)

  set_track_color(tr, SOLID_R, SOLID_G, SOLID_B)

  local item = r.AddMediaItemToTrack(tr)
  r.SetMediaItemInfo_Value(item, "D_POSITION", 0.0)
  r.SetMediaItemInfo_Value(item, "D_LENGTH", item_len)
  set_item_color(item, SOLID_R, SOLID_G, SOLID_B)

  -- Blank take name to avoid "empty track" label
  local take = r.AddTakeToMediaItem(item)
  if take then
    r.GetSetMediaItemTakeInfo_String(take, "P_NAME", " ", true)
  end

  set_arrange_view_span_around_cursor()
  select_only_track(tr)
end

-- ===== Toggle =====
local function main()
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local tr, idx = find_focus_track()
  if tr and idx >= 0 then
    delete_focus_track(idx)
    restore_context()
  else
    create_single_focus()
  end

  r.PreventUIRefresh(-1)
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
  r.Undo_EndBlock("34tools: Auditory Focus Screen — Toggle", -1)
end

main()

