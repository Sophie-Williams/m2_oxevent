--[[
	OX Event Quest
	Developed by Owsap | https://github.com/Owsap
	
	The MIT License (MIT)
	
	Copyright (c) 2017 Owsap Productions
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]
quest ox_event begin
	state start begin
		function settings()
			local settings = {}
			
			--[[ @!important
				note: you should not translate the weekdays in the settings! the weekdays have to be in english in order to make the os.date condition work. (line 76)
				: to transalte the weekdays, find the line 24 and change the values of the second column to your desired language.
			]]
			settings.open_datetime = {"Friday 21:00", "Saturday 21:00", "Sunday 10:30", "Sunday 21:00"} -- datetime to trigger event [weekday, hours, minutes]
			settings.open_time = 60*5 -- open time for gates [default: 60*5 = 5min] (note: time after open_datetime)
			settings.close_time = 60*5 -- close time for gates [default: 60*5 = 5min] (note: time after open_datetime + open_time)
			settings.start_time = 5 -- delay to start quiz [default: 5 = 5sec]
			settings.max_winners = 1 -- maximum winners [default: 1 = 1 player/winner]
			settings.reward = {50034, 1} -- event reward
			settings.end_time = 10 -- delay to end event [default: 10 = 10sec]
			
			return settings
		end
		
		function translate_weekday(datetime)
			translation = datetime
			
			local weekdays = {
				-- do not translate first column
				{"Monday",	"Monday"}, 
				{"Tuesday",	"Tuesday"},
				{"Wednesday",	"Wednesday"},
				{"Thursday",	"Thursday"},
				{"Friday",	"Friday"},
				{"Saturday",	"Saturday"},
				{"Sunday",	"Sunday"}
			}
			
			for index, weekday in ipairs(weekdays) do
				translation = string.gsub(translation, weekday[1], weekday[2])
			end
			
			return translation
		end
		
		function clear_timers()
			clear_server_timer("oxevent_opentime")
			clear_server_timer("oxevent_closetime")
			clear_server_timer("oxevent_starttime")
			clear_server_timer("oxevent_checktime")
			clear_server_timer("oxevent_endtime")
			game.set_event_flag("ox_event_time", 0)
			return
		end
		
		when login or enter begin -- trigger the server loop timer
			if game.get_event_flag("ox_event") > 0 and game.get_event_flag("ox_event_time") == 0 then -- check if game flag is set and ox start time 0
				server_loop_timer("oxevent_time", 1) -- set timer loop
			end
			
			if oxevent.get_status() == 1 then -- check if ox event gates are open
				notice_multiline("The gates to the OX event have opened![ENTER]Go talk to Uriel to participate!", notice) -- send notice to player
			end
		end
		
		when oxevent_time.server_timer begin
			local settings = ox_event.settings()
			
			-- check if ox event is closed and if game flag is set
			if oxevent.get_status() == 0 and game.get_event_flag("ox_event") > 0 and game.get_event_flag("ox_event_time") == 0 then
				-- check if os.date is equal to open_datetime
				for index, datetime in ipairs(settings.open_datetime) do
					if datetime == os.date("%A %H:%M") then
						clear_server_timer("oxevent_time") -- clear timer loop
						game.set_event_flag("ox_event_time", get_global_time()) -- set ox event start time (spam safe)
						
						server_timer("oxevent_opentime", settings.open_time) -- set notice timer before event starts
						notice_all("The OX event will start within "..(settings.open_time/60).." minutes.") -- send notice to all
					end
				end
			end
		end
		
		when oxevent_opentime.server_timer begin
			local settings = ox_event.settings()
			
			clear_server_timer("oxevent_opentime") -- clear timer
			
			oxevent.open() -- open gates
			server_timer("oxevent_closetime", settings.close_time) -- set close time for gates
			notice_multiline("The gates to the OX event have opened![ENTER]Go talk to Uriel to participate!", notice_all) -- send notice to all
			notice_all("The event will start within "..(settings.close_time/60).." minutes.") -- send notice to all
		end
		
		when oxevent_closetime.server_timer begin
			local settings = ox_event.settings()
			
			clear_server_timer("oxevent_closetime") -- clear timer
			
			oxevent.close() -- close gates
			server_timer("oxevent_starttime", settings.start_time) -- set quiz start delay
			notice_multiline("The gates to the OX event have closed.", notice_all) -- send notice to all
			notice_all("The event will start in a few seconds.") -- send notice to all
		end
		
		when oxevent_starttime.server_timer begin
			clear_server_timer("oxevent_starttime") -- clear timer
			
			if oxevent.get_attender() == 0 then -- check for attenders
				notice_all("The OX event was terminated because there were no attendees.") -- send notice to all
				ox_event.clear_timers() -- clear timers
				oxevent.end_event_force() -- force end event
				return
			end
			
			oxevent.quiz(1, 30) -- start quiz
			server_loop_timer("oxevent_checktime", 1) -- set timer loop to check max_winners
		end
		
		when oxevent_checktime.server_timer begin
			local settings = ox_event.settings()
			
			if oxevent.get_attender() <= settings.max_winners then -- check for max_winners
				clear_server_timer("oxevent_checktime") -- clear timer loop (if above condition returns true)
				
				oxevent.give_item(settings.reward[1], settings.reward[2]) -- give reward
				server_timer("oxevent_endtime", settings.end_time) -- set end time delay
			end
		end
		
		when oxevent_endtime.server_timer begin
			clear_server_timer("oxevent_endtime") -- clear timer
			
			notice_all("The OX event is over!") -- send notice to all
			oxevent.end_event() -- end event
			ox_event.clear_timers() -- clear server timers
		end
		
		when 20011.chat."OX Event" begin
			local settings = ox_event.settings()
			
			say_npc()
			say("Hey - you there! Yes, you - you seem very intelligent.[ENTER]",
				"There is a contest called OX Event. In it you can[ENTER]",
				"test your knowledge and if you win you[ENTER]",
				"will receive a good reward.")
			say_item_vnum(settings.reward[1])
			wait()
			
			say_npc()
			
			-- check if ox event is active and if gates are open
			if oxevent.get_status() == 1 then -- active and gates opened
				say("You will be teleported to the event map...")
				if select("Confirmar", locale.cancel) == 2 then return end
				pc.warp(896500, 24600) -- warp to attender position
			elseif oxevent.get_status() == 2 then -- active and gates closed
				say("Unfortunately you did not come in time to[ENTER]",
					"participate in the contest.")
				if select("Observe", locale.cancel) == 2 then return end
				pc.warp(896300, 28900) -- warp to observer position
			else
				say("I can let you participate in the event as soon[ENTER]",
					"as it starts.")
				say("The start time has not yet been set.[ENTER]",
					"I'll let you know when it's time, so[ENTER]",
					"prepare yourself!")
				return
			end
		end
		
		when 20358.chat."GM: OX Event" with pc.get_gm_level() == 5 begin
			local settings = ox_event.settings()
			
			say_title("OX Event")
			if oxevent.get_status() == 0 then
				if game.get_event_flag("ox_event_time") > 0 then
					say("Please wait while the countdown ends.")
					if select("End countdown", locale.cancel) == 2 then return end
					server_timer("oxevent_opentime", 1)
					return
				end
				
				say("The OX Event is closed.[ENTER]")
				if game.get_event_flag("ox_event") == 1 then
					say_title("Information")
					say("The event is set to start at:")
					for index, datetime in ipairs(settings.open_datetime) do
						say(color(240, 230, 140), ox_event.translate_weekday(datetime))
					end
					say()
				end
				say_reward("Do you want to open the gates now?")
				if select("Yes", "No") == 2 then return end
				
				local open_time
				repeat
					say_title("OX Event")
					say("Enter the opening time of the gates.")
					open_time = tonumber(input())
					if type(open_time) != "number" or open_time < 1 then
						say_title("OX Event")
						say("Please enter a valid number.")
						if select("Retry", locale.cancel) == 2 then return end
					end
				until type(open_time) == "number" and open_time > 0
				
				game.set_event_flag("ox_event_time", get_global_time()) -- set ox event start time (spam safe)
				
				server_timer("oxevent_opentime", 60*open_time) -- set notice timer before event starts
				notice_all("The OX event will start within "..open_time.." minutes.") -- send notice to all
			
			elseif oxevent.get_status() == 1 then
				say("The gates are still open.")
				say_reward("Participants: "..oxevent.get_attender())
				if select("Close the gates now!", locale.cancel) == 2 then return end
				
				server_timer("oxevent_closetime", 1) -- run timer without duplicating
				
			elseif oxevent.get_status() == 2 then
				say_reward("Participants: "..oxevent.get_attender())
				say_reward("Reward: "..settings.reward[1].." ("..settings.reward[2].." Unit/s)")
				say_item_vnum(settings.reward[1])
				
				local ox_options = select("End Event", "Force event termination", locale.cancel)
				
				if ox_options == 1 then
					notice_all("The OX event is over!") -- send notice to all
					oxevent.end_event() -- end event
					ox_event.clear_timers() -- clear server timers
				elseif ox_options == 2 then
					notice_all("The OX event is over!") -- send notice to all
					oxevent.end_event_force() -- force end event
					ox_event.clear_timers() -- clear server timers
				else
					return
				end
			end
		end
	end
end
