# Metin2 OX Event

## Install
Enter your locale quest folder and run `./qc ox_event.lua`

## Event Flag
To run the OX event automatically set the ox_event game flag to 1.
`/e ox_event 1`

## Configuration

> *Do not translate the weekdays in the settings!*
```lua
settings.open_datetime = {"Friday 21:00", "Saturday 21:00", "Sunday 10:30", "Sunday 21:00"} -- datetime to trigger event [weekday, hours, minutes]
settings.open_time = 60*5 -- open time for gates [default: 60*5 = 5min] (note: time after open_datetime)
settings.close_time = 60*5 -- close time for gates [default: 60*5 = 5min] (note: time after open_datetime + open_time)
settings.start_time = 5 -- delay to start quiz [default: 5 = 5sec]
settings.max_winners = 1 -- maximum winners [default: 1 = 1 player/winner]
settings.reward = {50034, 1} -- event reward
settings.end_time = 10 -- delay to end event [default: 10 = 10sec]
```

## Weekday Table

> *Line: 50 (Weekday translation)*
```Lua
-- do not translate first column
{"Monday",	"Monday"}, 
{"Tuesday",	"Tuesday"},
{"Wednesday",	"Wednesday"},
{"Thursday",    "Thursday"},
{"Friday",	"Friday"},
{"Saturday",	"Saturday"},
{"Sunday",	"Sunday"}
```

| Weekday (Default) | Weekday (Translated) |
|:--------------------:|:--------------------:|
| Monday | Monday |
| Tuesday | Tuesday |
| Wednesday | Wednesday |
| Thursday | Thursday |
| Friday | Friday
| Saturday | Saturday |
| Sunday | Sunday |

## License
m2_oxevent is released under the MIT License. See LICENSE for details.
