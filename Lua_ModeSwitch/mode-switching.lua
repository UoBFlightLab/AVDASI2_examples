-- comments in luascript start with '--'

--####################
--# Example script for AVDASI2 UAV build unit
--# Enables switching of specified servo outputs between RC and ground station control
--# Author: Sid Reid
--# Adapted from https://github.com/ArduPilot/ardupilot/blob/master/libraries/AP_Scripting/applets/winch-control.lua
--# Useful documentation: https://ardupilot.org/plane/docs/common-lua-scripts.html#getting-started
--####################

---@diagnostic disable: param-type-mismatch
-- disable an error message - kept this from the example that this was built on, not sure if it's needed.

-- global definitions
local MAV_SEVERITY = {EMERGENCY=0, ALERT=1, CRITICAL=2, ERROR=3, WARNING=4, NOTICE=5, INFO=6, DEBUG=7} -- you can redefine MAVLINK error codes, these are defaults
local PARAM_TABLE_KEY = 54 -- things are stored in tables, you can have up to 200 - make sure they don't clash
local PARAM_TABLE_PREFIX = "AVDASI2_" -- arbitrary prefix, good for readability and sorting

-- bind a parameter to a variable, so you can address them using easy names rather than numbers
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

-- set up our table of parameters
assert(param:add_table(PARAM_TABLE_KEY, PARAM_TABLE_PREFIX, 3), "AVDASI2: could not add param table") -- assign 3 rows to table, in case we want to add anything else later

--[[ -- this is all documentation left over from the template function this script is developed from
  // @Param: RC_FUNC
  // @DisplayName: Mode Switch RC Function
  // @Description: RCn_OPTION number to use to control the mode switch
  // @Values: 300:Scripting1, 301:Scripting2, 302:Scripting3, 303:Scripting4, 304:Scripting5, 305:Scripting6, 306:Scripting7, 307:Scripting8
  // @User: Standard
--]]
local RC_SCRIPTING = bind_add_param('RC_FUNC', 3, 300) -- create a parameter called 'RC_FUNC', in position 3 in the table (just because), and look for changes in the RC input mapped to 'Scripting1' (which is what the '301' means) in Mission Planner

-- local variables and definitions
local UPDATE_INTERVAL_MS = 100 -- check for changes 10x/second
local last_rc_switch_pos = -1   -- last known rc switch position.  Used to detect change in RC switch position. Initially set to an impossible value.

-- initialisation
gcs:send_text(MAV_SEVERITY.INFO, "AVDASI2: started") -- just log an info message

-- the main update function
function update() -- we run this whole function every UPDATE_INTERVAL_MS by calling itself again on each 'return'

  -- get RC switch position
  local rc_switch_pos = rc:get_aux_cached(RC_SCRIPTING:get())
  if not rc_switch_pos then
    -- if rc switch has never been set then return immediately
    return update, UPDATE_INTERVAL_MS -- run the 'update' function again after UPDATE_INTERVAL_MS, don't do anything below here until things are initialised properly
  end

  -- initialise RC switch at startup
  if last_rc_switch_pos == -1 then
    last_rc_switch_pos = rc_switch_pos
  end

  -- check if user has moved RC switch
  if rc_switch_pos == last_rc_switch_pos then -- if nothing has changed...
    return update, UPDATE_INTERVAL_MS -- ...jump out and end here, setting things up to run again in UPDATE_INTERVAL_MS
  end
  last_rc_switch_pos = rc_switch_pos -- if things have changed then update last position

  -- set servo function based on switch position *** THIS IS WHERE YOU SET YOUR SERVOS ETC UP
  if rc_switch_pos == 0 then -- LOW, Manual RC Control
    param:set("SERVO2_FUNCTION",19) -- Servo2 (usually elevator) is set to '19' which tells it that it's an elevator
    gcs:send_text(6, string.format("AVDASI2: Servo %d function set to %d", 1, 19))
  end
  if rc_switch_pos == 2 then -- HIGH, TELEM Servo Control
    param:set("SERVO2_FUNCTION",0) -- SERVO2_FUNCTION is set to '0' which tells it that it's disabled, so we can control it from GCS
    gcs:send_text(6, string.format("AVDASI2: Servo %d function set to %d", 1, 0))
  end

  return update, UPDATE_INTERVAL_MS  -- run the 'update' function again after UPDATE_INTERVAL_MS
end

return update()
