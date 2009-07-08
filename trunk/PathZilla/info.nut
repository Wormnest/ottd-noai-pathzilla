/*
 *	Copyright � 2008 George Weller
 *	
 *	This file is part of PathZilla.
 *	
 *	PathZilla is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 2 of the License, or
 *	(at your option) any later version.
 *	
 *	PathZilla is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *	
 *	You should have received a copy of the GNU General Public License
 *	along with PathZilla.  If not, see <http://www.gnu.org/licenses/>.
 *
 * info.nut
 * 
 * The basic descriptor for the PathZilla AI.
 * 
 * Author:  George Weller (Zutty)
 * Created: 27/05/2008
 * Version: 1.1
 */

class PathZilla extends AIInfo {
	function GetAuthor()      { return "George Weller"; }
	function GetName()        { return "PathZilla"; }
	function GetDescription() { return "A networking AI. The focus of this AI is on high level planning and neat, realistic construction. Supports buses/trams and mail trucks only."; }
	function GetVersion()     { return 5; }
	function GetDate()        { return "2009-01-24"; }
	function CreateInstance() { return "PathZilla"; }
	function GetShortName()   { return "PZLA"; }
	function GetSettings() {
		AddSetting({name = "latency", description = "Planning speed of AI", min_value = 0, max_value = 5, easy_value = 1, medium_value = 3, hard_value = 5, custom_value = 4, flags = 0});
		AddLabels("latency", {_0="Very Slow", _1="Slow", _2="Medium", _3="Fast", _4="Very Fast", _5="Fastest"});
		AddSetting({name = "aggressive", description = "Compete aggressively with other players", easy_value = 0, medium_value = 0, hard_value = 1, custom_value = 1, flags = AICONFIG_BOOLEAN});
		AddSetting({name = "traffic", description = "Level of traffic the AI should generate", min_value = 1, max_value = 4, easy_value = 1, medium_value = 2, hard_value = 3, custom_value = 2, flags = 0});
		AddLabels("traffic", {_1="Light", _2="Normal", _3="Heavy", _4="Very Heavy"});
		AddSetting({name = "rt_cargo_towns", description = "Route all cargo through towns", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = AICONFIG_BOOLEAN});
		AddSetting({name = "country_lanes", description = "Build windy country lanes in rural towns", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = AICONFIG_BOOLEAN});
	}
	function CanLoadFromVersion(version) {
		return (version == 5);
	}
}

RegisterAI(PathZilla());