---@diagnostic disable: param-type-mismatch


-- global definitions
local MAV_SEVERITY = {EMERGENCY=0, ALERT=1, CRITICAL=2, ERROR=3, WARNING=4, NOTICE=5, INFO=6, DEBUG=7}
local PARAM_TABLE_KEY = 54
local PARAM_TABLE_PREFIX = "AVDASI2_"

-- bind a parameter to a variable
function bind_param(name)
   local p = Parameter()
   assert(p:init(name), string.format("AVDASI2: could not find %s parameter", name))
   return p
end

-- add a parameter and bind it to a variable
function bind_add_param(name, idx, default_value)
   assert(param:add_param(PARAM_TABLE_KEY, idx, name, default_value), string.format("AVDASI2: could not add param %s", name))
   return bind_param(PARAM_TABLE_PREFIX .. name)
end

-- setup quicktune specific parameters
assert(param:add_table(PARAM_TABLE_KEY, PARAM_TABLE_PREFIX, 3), "AVDASI2: could not add param table")

--[[
  // @Param: RC_FUNC
  // @DisplayName: Mode Switch RC Function
  // @Description: RCn_OPTION number to use to control the mode switch
  // @Values: 300:Scripting1, 301:Scripting2, 302:Scripting3, 303:Scripting4, 304:Scripting5, 305:Scripting6, 306:Scripting7, 307:Scripting8
  // @User: Standard
--]]
local RC_SCRIPTING = bind_add_param('RC_FUNC', 3, 300)

-- local variables and definitions
local UPDATE_INTERVAL_MS = 100
local last_rc_switch_pos = -1   -- last known rc switch position.  Used to detect change in RC switch position

-- initialisation
gcs:send_text(MAV_SEVERITY.INFO, "AVDASI2: started")

-- the main update function
function update()

  -- get RC switch position
  local rc_switch_pos = rc:get_aux_cached(RC_SCRIPTING:get())
  if not rc_switch_pos then
    -- if rc switch has never been set the return immediately
    return update, UPDATE_INTERVAL_MS
  end

  -- initialise RC switch at startup
  if last_rc_switch_pos == -1 then
    last_rc_switch_pos = rc_switch_pos
  end

  -- check if user has moved RC switch
  if rc_switch_pos == last_rc_switch_pos then
    return update, UPDATE_INTERVAL_MS
  end
  last_rc_switch_pos = rc_switch_pos

  -- set winch rate based on switch position
  if rc_switch_pos == 0 then -- LOW, Manual RC Control
    param:set("SERVO1_FUNCTION",4)
    gcs:send_text(6, string.format("Servo %d function set to %d", 1, 4))
  end
  if rc_switch_pos == 2 then -- HIGH, TELEM Servo Control
    param:set("SERVO1_FUNCTION",0)
    gcs:send_text(6, string.format("Servo %d function set to %d", 1, 0))
  end

  return update, UPDATE_INTERVAL_MS
end

return update()