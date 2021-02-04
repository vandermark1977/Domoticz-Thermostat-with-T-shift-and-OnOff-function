# Domoticz Thermostat with heatcurve-shift and OnOff function for Panaosonic heatpimp
Simple Domoticz thermostat for Panasonic heatpump. 

## Prerequisits:
* You have setup the heatpump with a Heatcurve for the water outlet temperature. The built in thermostat of the Panasonic heatpump must be turned off.
* Script works in combination with the [Domoticz HeishamonMQTT plugin](https://github.com/MarFanNL/HeishamonMQTT/tree/main) and the [heishamon control board](https://www.tindie.com/stores/thehognl/)
* In Domoticz you have an accurate room temperature measurement available.

## How does the script work?
The thermostat script works with two functions to control the room temperature: 

1. Shift Heatcurve --> When the room temperature gets above a setpoint (based on thermostat device with hysteresis) --> Shift(-1) Target outlet water temperature. It works also the other way around: Shift(+1) when it gets colder then the setpoint.

2. In most situations there is a minimum temperature of the water outlet at which the heatpump still funcytions well. In my situation (and therefor in the script) this minimum water outlet temperature is 26 degrees. If the water outlet temperature based on the heatcurve is 26 degrees and the room tmeprature gets above the setpoit we don't want it to shift the water outlet temperature below 26 degrees. Therfor rhe script uses a On/Off function to turn Off the heatpump when the water outlet temperature is at the minimum. When the room temperature gets below the setpoint, the heatpump is turned on again.
