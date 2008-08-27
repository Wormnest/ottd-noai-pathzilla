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
 * Version: 1.0
 */

class PathZilla extends AIInfo {
	function GetAuthor()      { return "Zutty"; }
	function GetName()        { return "PathZilla"; }
	function GetDescription() { return "A road networking AI"; }
	function GetVersion()     { return 3; }
	function GetDate()        { return "2008-08-16"; }
	function CreateInstance() { return "PathZilla"; }
	function GetSettings() {
		SetSetting({name = "latency", description = "Latency", min_value = 0, max_value = 5, easy_value = 4, medium_value = 2, hard_value = 0, custom_value = 1, flags = 0});
		SetSetting({name = "aggressive", description = "Aggressive", min_value = 0, max_value = 1, easy_value = 0, medium_value = 0, hard_value = 1, custom_value = 1, flags = 0});
	}
}

RegisterAI(PathZilla());