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

        local thermostaat = 146                     -- Dummy thermostaat device
        local roomTemperatureId = 42                -- Temperature measurement
        local wpSwitchId = 60                       -- Heatpump_State
        local DefrostSwitchId = 81                  -- Defrost_State
        local target_temp = domoticz.devices(66)    -- Fill in IDX of the Pana [Main_Target_Temp]
        local ShiftManual = domoticz.devices(149)   -- Fill in IDX of Your Manual TaShift [temperature thermostat]
        local Shift = 0                             -- Local variable
        local roomTemperature = tonumber(domoticz.devices(roomTemperatureId).rawData[1])
        local setPoint = domoticz.utils.round(domoticz.devices(thermostaat).setPoint, 2)

        if      ((roomTemperature > (setPoint + 0.1)) and
                (domoticz.devices(wpSwitchId).state == 'On') and
                (domoticz.devices(DefrostSwitchId).state == 'Off') and
                (target_temp.temperature <= 26) and
                (ShiftManual.lastUpdate.minutesAgo >= 90 ))
                then
                    domoticz.devices(wpSwitchId).switchOff()
                    domoticz.notify('Heatpump turned off by thermostat')
                    domoticz.log('Heatpump turned off: Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
        
        elseif  ((roomTemperature > (setPoint + 0.1)) and  --
                (domoticz.devices(wpSwitchId).state == 'On') and
                (domoticz.devices(DefrostSwitchId).state == 'Off') and
                (target_temp.temperature > 26) and
                (ShiftManual.lastUpdate.minutesAgo >= 90 )) then
                    Shift=((ShiftManual.setPoint) - 1)
                    ShiftManual.updateSetPoint(Shift)
                    domoticz.notify('Correction heating curve: '..Shift)
                    domoticz.log('Correction heating curve: '..Shift.. 'Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
        
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
        
        elseif  ((roomTemperature < setPoint) and 
                (domoticz.devices(wpSwitchId).state == 'Off')) then
                    domoticz.devices(wpSwitchId).switchOn()
                    domoticz.notify('Heatpump turned on by thermostat')
                    domoticz.log('Heatpump turned on by thermostat: Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
        
        elseif  ((target_temp.temperature < 26) and  -- Make sure Ta-target never gets below 26
                (ShiftManual.setPoint <= -1)) then
                    Shift=0
                    ShiftManual.updateSetPoint(Shift)
                    domoticz.log('Target water outlet temperature below 26 --> Shift manual set to [0]', domoticz.LOG_DEBUG)
        
        elseif  ((roomTemperature > (setPoint + 1)) or
                (roomTemperature < (setPoint - 1))) and
                (domoticz.devices(wpSwitchId).state == 'On') then
                    domoticz.notify('Check heatpump which is on! Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ')
                    domoticz.log('Check heatpump which is on! Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
        
        elseif  (roomTemperature > (setPoint - 1)) and
                (roomTemperature < (setPoint + 1) and
                (domoticz.devices(wpSwitchId).state == 'On')) then
                    domoticz.log('Heatpump is ON and not changed: Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
        
         elseif (domoticz.devices(wpSwitchId).state == 'Off') then
                    domoticz.log('Heatpump is OFF. Room temperature is: '.. roomTemperature .. ' oC and Setpoint is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
                    end
        
        domoticz.devices(thermostaat).updateSetPoint(setPoint) -- update dummy sensor in case of red indicator ;-)
        domoticz.log('End script. Shift manual last triggered: ' .. ShiftManual.lastUpdate.minutesAgo..' minutes ago', domoticz.LOG_INFO)
    end
}
