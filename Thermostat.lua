return {
   on = {
        timer = {
                   'every 5 minutes'
                }
         },

        logging = {
            level = domoticz.LOG_DEBUG, -- LOG_DEBUG or LOG_ERROR
            marker = "Thermostaat: "
        },

    execute = function(domoticz, item)

        local thermostaat = 146                     -- Dummy thermostat device. You use this device to set the target for the room temperature
        local roomTemperatureId = 42                -- Temperature measurement device of the room yoy want to control
        local wpSwitchId = 60                       -- Heatpump_State [On/Off]
        local DefrostSwitchId = 81                  -- Defrost_State [On/Off]
        local target_temp = domoticz.devices(66)    -- Water outlet target temperature [PANA: Main_Target_Temp]
        local ShiftManual = domoticz.devices(149)   -- Fill in IDX of Your Manual TaShift. If youy don't use my Slowstart script(Check the readme.md), Fill in the normal Shift IDX
        local Shift = 0                             -- Local variable, dont change
        local roomTemperature = tonumber(domoticz.devices(roomTemperatureId).rawData[1])
        local setPoint = domoticz.utils.round(domoticz.devices(thermostaat).setPoint, 2)

      -------------------------------------------------------------------------------
      -- (A) Room T > setpoint --> Heatpump turned off because water outlet temp is at lowest value      
      -------------------------------------------------------------------------------
        if      ((roomTemperature > (setPoint + 0.1)) and  -- I use a small hysteresis of 0.1 degrees. Adjust to your situation
                (domoticz.devices(wpSwitchId).state == 'On') and
                (domoticz.devices(DefrostSwitchId).state == 'Off') and  --Not during a defrost
                (target_temp.temperature <= 26) and
                (ShiftManual.lastUpdate.minutesAgo >= 90 ))  -- Prevent Turn off too soon after a T-Shift
                then
                    domoticz.devices(wpSwitchId).switchOff()
                    domoticz.notify('Heatpump turned off by thermostat')
                    domoticz.log('Heatpump turned off: Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
      -------------------------------------------------------------------------------
      -- (B) Room T > setpoint --> Shift water temperature -1      
      -------------------------------------------------------------------------------        
        elseif  ((roomTemperature > (setPoint + 0.1)) and  --
                (domoticz.devices(wpSwitchId).state == 'On') and
                (domoticz.devices(DefrostSwitchId).state == 'Off') and
                (target_temp.temperature > 26) and
                (ShiftManual.lastUpdate.minutesAgo >= 90 )) then -- Prevent T-shift happening too soon after the last one. 
                    Shift=((ShiftManual.setPoint) - 1)
                    ShiftManual.updateSetPoint(Shift)
                    domoticz.notify('Correction heating curve: '..Shift)
                    domoticz.log('Correction heating curve: '..Shift.. 'Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
      -------------------------------------------------------------------------------
      -- (C) Room T < setpoint --> Shift water temperature +1      
      -------------------------------------------------------------------------------               
        elseif  ((roomTemperature < (setPoint-0.2)) and
                (domoticz.devices(wpSwitchId).state == 'On') and
                (domoticz.devices(DefrostSwitchId).state == 'Off') and
                (ShiftManual.lastUpdate.minutesAgo >= 90 ) and
                (domoticz.time.hour > 8 and domoticz.time.hour < 22) and
                (wpSwitchId.lastUpdate.minutesAgo > 90)) then
                    Shift=((ShiftManual.setPoint) + 1)
                    ShiftManual.updateSetPoint(Shift)
                    domoticz.notify('Correction heating curve: '..Shift)
                    domoticz.log('Correction heating curve: '..Shift.. 'Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
      -------------------------------------------------------------------------------
      -- (D) Room T < setpoint and heatpump is off -->  Turn heatpump on again      
      -------------------------------------------------------------------------------               
        
        elseif  ((roomTemperature < setPoint) and -- Add hysteresis if needed in your situation
                (domoticz.devices(wpSwitchId).state == 'Off')) then
                    domoticz.devices(wpSwitchId).switchOn()
                    domoticz.notify('Heatpump turned on by thermostat')
                    domoticz.log('Heatpump turned on by thermostat: Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
      -------------------------------------------------------------------------------
      -- (E) Various LOGS for different situations      
      -------------------------------------------------------------------------------              
        elseif  ((roomTemperature > (setPoint + 1)) or
                (roomTemperature < (setPoint - 1))) and
                (domoticz.devices(wpSwitchId).state == 'On') then
                    domoticz.notify('Check heatpump which is on! Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ')
                    domoticz.log('Check heatpump which is on! Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
        
        elseif  (roomTemperature > (setPoint - 1)) and
                (roomTemperature < (setPoint + 1) and
                (domoticz.devices(wpSwitchId).state == 'On')) then
                    domoticz.log('Heatpump is ON and not changed: Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
        
        elseif  (domoticz.devices(wpSwitchId).state == 'Off') then
                    domoticz.log('Heatpump is OFF. Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
                    end
---------------------------------------------
-- Make sure Ta-target never gets below 26 --
---------------------------------------------
        if      ((target_temp.temperature < 26) and
                (ShiftManual.setPoint <= -1)) then
                    Shift=0
                    ShiftManual.updateSetPoint(Shift)
                    domoticz.log('Target water outlet temperature below 26 --> Shift manual set to [0]', domoticz.LOG_DEBUG)
                    end

        domoticz.devices(thermostaat).updateSetPoint(setPoint) -- update dummy sensor in case of red indicator ;-)
        domoticz.log('End script. Shift manual last triggered: ' .. ShiftManual.lastUpdate.minutesAgo..' minutes ago', domoticz.LOG_INFO)
    end
}
