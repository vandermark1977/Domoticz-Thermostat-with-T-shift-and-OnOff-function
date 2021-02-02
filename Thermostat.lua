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

        local switchWp = true                       -- set to true if you want to switch on/off the heater
        local thermostaat = 146                     -- Dummy thermostat device
        local roomTemperatureId = 42                -- Temperature measurement
        local wpSwitchId = 60                       -- Heatpump_State
        local DefrostSwitchId = 81                  -- Defrost_State
        local setPoint = domoticz.utils.round(domoticz.devices(thermostaat).setPoint, 2)
        local target_temp = domoticz.devices(66)    -- Fill in IDX of the Pana [Main_Target_Temp]
        local ShiftManual = domoticz.devices(149)   -- Fill in IDX of Your Manual TaShift [temperature thermostat]
        local Shift = 0                             -- Local variable

        -- script default values settings
        local roomTemperature = tonumber(domoticz.devices(roomTemperatureId).rawData[1])

        if      ((roomTemperature > setPoint) and
                (domoticz.devices(wpSwitchId).state == 'On') and
                (domoticz.devices(DefrostSwitchId).state == 'Off') and
                (target_temp.temperature <= 26) and
                (ShiftManual.lastUpdate.minutesAgo >= 90 ))
                then
                    if (true == switchWp) then
                    domoticz.devices(wpSwitchId).switchOff()
                    domoticz.notify('De warmtepomp is uitgezet door de thermostaat')
                    domoticz.log('WP UIT gezet: Temperatuur binnen is: '.. roomTemperature .. ' oC en doeltemperatuur is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
                    end
        elseif  ((roomTemperature > setPoint) and
                (domoticz.devices(wpSwitchId).state == 'On') and
                (domoticz.devices(DefrostSwitchId).state == 'Off') and
                (target_temp.temperature > 26) and
                (ShiftManual.lastUpdate.minutesAgo >= 90 )) then
                    if (true == switchWp) then
                    Shift=((ShiftManual.setPoint) - 1)
                    ShiftManual.updateSetPoint(Shift)
                    domoticz.notify('Correctie stooklijn: '..Shift)
                    domoticz.log('Correctie stooklijn: '..Shift.. 'Temperatuur binnen is: '.. roomTemperature .. ' oC en doeltemperatuur is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
                    end
        elseif  ((roomTemperature < (setPoint-0.2)) and
                (domoticz.devices(wpSwitchId).state == 'On') and
                (domoticz.devices(DefrostSwitchId).state == 'Off') and
                (ShiftManual.lastUpdate.minutesAgo >= 90 )) then
                    if (true == switchWp) then
                    Shift=((ShiftManual.setPoint) + 1)
                    ShiftManual.updateSetPoint(Shift)
                    domoticz.notify('Correctie stooklijn: '..Shift)
                    domoticz.log('Correctie stooklijn: '..Shift.. 'Temperatuur binnen is: '.. roomTemperature .. ' oC en doeltemperatuur is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
                    end
        elseif  ((roomTemperature < setPoint) and 
                (domoticz.devices(wpSwitchId).state == 'Off')) then
                    if (true == switchWp) then
                    domoticz.devices(wpSwitchId).switchOn()
                    domoticz.notify('De warmtepomp is aangezet door de thermostaat')
                    domoticz.log('WP AAN gezet: Temperatuur binnen is: '.. roomTemperature .. ' oC en doeltemperatuur is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
                    end
        elseif  ((target_temp.temperature < 26) and
                (ShiftManual.setPoint <= -1)) then
                    if (true == switchWp) then
                    Shift=0
                    ShiftManual.updateSetPoint(Shift)
                    domoticz.log('Ta-doel onder de 26 gekomen --> Shift manual op [0] gezet', domoticz.LOG_DEBUG)
                    end
        elseif  ((roomTemperature > (setPoint + 1)) or
                (roomTemperature < (setPoint - 1.0))) and
                (domoticz.devices(wpSwitchId).state == 'On') then
                    if (true == switchWp) then
                    domoticz.notify('Check WP die aan staat! Temperatuur binnen is: '.. roomTemperature .. ' oC en doeltemperatuur is: '  .. setPoint .. ' oC ')
                    domoticz.log('Check WP die aan staat! Temperatuur binnen is: '.. roomTemperature .. ' oC en doeltemperatuur is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
                    end 
        elseif  (roomTemperature > (setPoint - 1)) and
                (roomTemperature < (setPoint + 1) and
                (domoticz.devices(wpSwitchId).state == 'On')) then
                    if (true == switchWp) then
                    domoticz.log('WP AAN en niet veranderd: Temperatuur binnen is: '.. roomTemperature .. ' oC en doeltemperatuur is: '  .. setPoint .. ' oC ', domoticz.LOG_DEBUG)
                    end    
        end
        domoticz.devices(thermostaat).updateSetPoint(setPoint) -- update dummy sensor in case of red indicator ;-)
        domoticz.log('Einde script. Shiftmanueel laatst getriggerd: ' .. ShiftManual.lastUpdate.minutesAgo..' minuten geleden', domoticz.LOG_INFO)
    end
}
