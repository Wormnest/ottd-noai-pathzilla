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
 * Service.nut
 * 
 * A bus service between two towns.
 * 
 * Author:  George Weller (Zutty)
 * Created: 18/06/2008
 * Version: 1.0
 */

class Service {
	// Serialization constants
	CLASS_NAME = "Service";
	SRLZ_FROM_TOWN = 0;
	SRLZ_TO_TOWN = 1;
	SRLZ_CARGO = 2;
	SRLZ_ROAD_TYPE = 5;
	SRLZ_ENGINE = 3;
	SRLZ_GROUP = 4;
	
	fromTown = null;
	toTown = null;
	cargo = 0;
	roadType = null;
	engine = null;
	profitability = 0;
	vehicles = null;
	group = null;
	
	constructor(fromTown, toTown, cargo, roadType, engine) {
		this.fromTown = fromTown;
		this.toTown = toTown;
		this.cargo = cargo;
		this.roadType = roadType;
		this.engine = engine;

		this.vehicles = AIList();
		this.group = AIGroup.CreateGroup(AIVehicle.VEHICLE_ROAD);
		AIGroup.SetName(this.group, AITown.GetName(fromTown) + " to " + AITown.GetName(toTown));
	}
}

/*
 * Get the town this service goes from.
 */
function Service::GetFromTown() {
	return this.fromTown;
}

/*
 * Get the town this service goes to.
 */
function Service::GetToTown() {
	return this.toTown;
}

/*
 * Get the cargo this service carries.
 */
function Service::GetCargo() {
	return this.cargo;
}

/*
 * Get the cargo this service carries.
 */
function Service::GetRoadType() {
	return this.roadType;
}

/*
 * Get the engine that this service uses
 */
function Service::GetEngine() {
	return this.engine;
}

/*
 * Set the engine that this service uses
 */
function Service::SetEngine(e) {
	return this.engine = e;
}

/*
 * Check if the service visits a town
 */
function Service::GoesTo(town) {
	return (town == this.fromTown || town == this.toTown);
}

/*
 * Add a vehicle to the service
 */
function Service::AddVehicle(vehicleId) {
	this.vehicles.AddItem(vehicleId, 0);
	AIGroup.MoveVehicle(this.group, vehicleId);
}

/*
 * Get the vehicles that are currently operating this service.
 */
function Service::GetVehicles() {
	return this.vehicles;
}

/*
 * Get the number of vehicles that are currently operating this service.
 */
function Service::GetActualFleetSize() {
	return this.vehicles.Count();
}

/*
 * Get a string representation of this service.
 */
function Service::_tostring() {
	return AICargo.GetCargoLabel(this.cargo) + " from " + AITown.GetName(this.fromTown) + " to " + AITown.GetName(this.toTown);
}

/*
 * Saves data to a table.
 */
function Service::Serialize() {
	local data = {};
	data[SRLZ_FROM_TOWN] <- this.fromTown;
	data[SRLZ_TO_TOWN] <- this.toTown;
	data[SRLZ_CARGO] <- this.cargo;
	data[SRLZ_ROAD_TYPE] <- this.roadType;
	data[SRLZ_ENGINE] <- this.engine;
	data[SRLZ_GROUP] <- this.group;
	return data;
}

/*
 * Loads data from a table.
 */
function Service::Unserialize(data) {
	this.fromTown = data[SRLZ_FROM_TOWN];
	this.toTown = data[SRLZ_TO_TOWN];
	this.cargo = data[SRLZ_CARGO];
	this.roadType = data[SRLZ_ROAD_TYPE];
	this.engine = data[SRLZ_ENGINE];
	this.group = data[SRLZ_GROUP];
}

/*
 * Compare this service to another. This function returns 0 (i.e. equal) for 
 * services that go to/from the same towns, and otherwise orders services by
 * profitability (Errr... what?? I think this is a hangover from legacy code) 
 */
function Service::_cmp(svc) {
	if((fromTown == svc.fromTown && toTown == svc.toTown) || (fromTown == svc.toTown && toTown == svc.fromTown)) return 0;
	if(profitability > svc.profitability) return 1;
	return -1;
}