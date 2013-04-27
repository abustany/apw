-- Copyright 2013 mokasin
-- This file is part of the Awesome Pulseaudio Widget (APW).
-- 
-- APW is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- APW is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with APW. If not, see <http://www.gnu.org/licenses/>.


-- Simple pulseaudio command bindings for Lua.

local pulseaudio = {}

pulseaudio.Volume = 0     -- volume of default sink
pulseaudio.Mute = false   -- state of the mute flag of the default sink

local cmd = "pacmd"
local default_sink = "default"

function pulseaudio.GetState()
	local f = io.popen(cmd .. " dump")

	-- if the cmd can't be found
	if f == nil then
		f.close()
		return false
	end

	local out = f:read("*a")

	-- get the default sink
	default_sink = string.match(out, "set%-default%-sink ([^\n]+)")

	if default_sink == nil then
		return false
	end

	-- retreive volume of default sink
	for sink, value in string.gmatch(out, "set%-sink%-volume ([^%s]+) (0x%x+)") do
		if sink == default_sink then
			pulseaudio.Volume = tonumber(value) / 0x10000
		end
	end

	-- retreive mute state of default sink
	local m
	for sink, value in string.gmatch(out, "set%-sink%-mute ([^%s]+) (%a+)") do
		if sink == default_sink then
			m = value
		end
	end

	if m == "yes" then
		pulseaudio.Mute = true
	else
		pulseaudio.Mute = false
	end


	f.close()
end

-- Sets the volume of the default sink to vol from 0 to 1.
function pulseaudio.SetVolume(vol)
	if vol > 1 then
		vol = 1
	end

	if vol < 0 then
		vol = 0
	end

	vol = vol * 0x10000
	-- set…
	io.popen(cmd .. " set-sink-volume " .. default_sink .. " " .. string.format("0x%x", vol))

	-- …and update values.
	pulseaudio.GetState()
end


-- Toggles the mute flag of the default default_sink.
function pulseaudio.ToggleMute()
	if pulseaudio.Mute then
		io.popen(cmd .. " set-sink-mute " .. default_sink .. " 0")
	else
		io.popen(cmd .. " set-sink-mute " .. default_sink .. " 1")
	end
	
	-- …and update values.
	pulseaudio.GetState()
end


-- Fetch current state on module load.
pulseaudio.GetState()

return pulseaudio
