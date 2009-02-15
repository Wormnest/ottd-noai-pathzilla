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
 * Target.nut
 * 
 * An entity that can form part of a service, currently either a town or an
 * industry.
 * 
 * Author:  George Weller (Zutty)
 * Created: 30/01/2008
 * Version: 1.0
 */

class Target {
	TYPE_TOWN = 1;
	TYPE_INDUSTRY = 2;
	
	TILE_UNFIXED = -2;
	
	type = null;
	id = null;
	tile = null;
	
	constructor(type, id) {
		this.type = type;
		this.id = id;
		
		if(type == Target.TYPE_TOWN) {
			this.tile = AITown.GetLocation(id);
		} else if(type == Target.TYPE_INDUSTRY) {
			this.tile = AIIndustry.GetLocation(id) - 2;
			//this.tile = TILE_UNFIXED;
		}
	}
}

/*
 * Get the tile at to which all links should be made. This tile is guaranteed
 * to the buildable.
 */
function Target::GetTile() {
	return this.tile;
}

/*
 * Returns true if the position of the buildable tile has been fixed yet.
 */
function Target::IsTileFixed() {
	return (this.tile == Target.TILE_UNFIXED);
}

/*
 * Fix the seed tile to be a specified tile.
 */
function Target::FixTile(f) {
	if(!this.IsTileFixed()) this.tile = f;
}

/*
 * Get the rough location of this target. This tile should NOT be used for
 * construction, only for planning.
 */
function Target::GetLocation() {
	local tile = -1;
	if(this.type == Target.TYPE_TOWN) {
		tile = AITown.GetLocation(this.id);
	} else if(this.type == Target.TYPE_INDUSTRY) {
		tile = AIIndustry.GetLocation(this.id);
	}
	return tile;
}

/*
 * Returns this target as a vertex that preserves the underlying state.
 */
function Target::GetVertex() {
	local tile = this.GetLocation();
	return Vertex(AIMap.GetTileX(tile), AIMap.GetTileY(tile), this);
}

/*
 * Get the type of this target.
 */
function Target::GetType() {
	return this.type;
}

/*
 * Returns true if this target ponts to a town.
 */
function Target::IsTown() {
	return (this.type == Target.TYPE_TOWN);
}

/*
 * Get the underlying Id of the town or industry this target points to.
 */
function Target::GetId() {
	return this.id;
}

/*
 * Returns true if this target produces anything.
 */
function Target::IsProducer() {
	if(this.type == Target.TYPE_TOWN) return true;
	
	local indType = AIIndustry.GetIndustryType(this.id);
	return !AIIndustryType.GetProducedCargo(indType).IsEmpty();
}

/*
 * Returns true if this target accepts anything.
 */
function Target::IsAccepter() {
	if(this.type == Target.TYPE_TOWN) return true;
	
	local indType = AIIndustry.GetIndustryType(this.id);
	return !AIIndustryType.GetAcceptedCargo(indType).IsEmpty();
}

/*
 * Get the name of the underlying target from the API.
 */
function Target::GetName() {
	local name = "Unknown";
	
	if(type == Target.TYPE_TOWN) {
		name = AITown.GetName(this.id);
	} else if(type == Target.TYPE_INDUSTRY) {
		name = AIIndustry.GetName(this.id);
	}
	
	return name;
}

/*
 * A static method to be used to sort Targets by their profit making potential.
 */
function Target::SortByPotential(homeTown, cargo) {
	return function (a,b):(homeTown, cargo) {
		local aval = 0;
		local bval = 0;
		
		if(a.type == b.type) {
			if(a.type == Target.TYPE_TOWN) {
				aval = (a.id == homeTown) ? 1000000 : AITown.GetPopulation.call(a, a.id);
				bval = (b.id == homeTown) ? 1000000 : AITown.GetPopulation.call(b, b.id);
			} else {
				aval = AIIndustry.GetLastMonthProduction.call(a, a.id, cargo);
				bval = AIIndustry.GetLastMonthProduction.call(b, b.id, cargo);
			}
		} else {
			// TODO - Heterogenous services
		}
		
		if(aval < bval) return 1;
		else if(aval > bval) return -1;
		return 0;
	}
}