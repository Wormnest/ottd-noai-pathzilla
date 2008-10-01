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
 * RoadManager.nut
 * 
 * Handles all road-based construction functions.
 * 
 * Author:  George Weller (Zutty)
 * Created: 27/07/2008
 * Version: 1.0
 */

class RoadManager {
	constructor() {
	}
}

/*
 * Get a list of all the road stations in a town for a specified cargo
 */
function RoadManager::GetStations(town, cargo, roadType) {
	local truckStation = !AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS);
	local stationType = (truckStation) ? AIStation.STATION_TRUCK_STOP : AIStation.STATION_BUS_STOP;
	
	// Ensure we get the right type of station
	local stationList = AIStationList(stationType);
	stationList.Valuate(AIStation.IsWithinTownInfluence, town);
	stationList.RemoveValue(0);
	
	// Ensure the stations have the correct road type
	stationList.Valuate(function (station, roadType) {
		return (AIRoad.HasRoadType(AIStation.GetLocation(station), roadType)) ? 1 : 0;
	}, roadType);
	stationList.RemoveValue(0);
	
	return stationList;
}

/*
 * Get the combined coverage area of all stations in a town for a specified
 * cargo, as a parcentage of all houses in that town. This helps determine how
 * many stations can be placed in a town. If the AI is set not to be agressive
 * it will count competitor's stations in the total coverage.
 */
function RoadManager::GetTownCoverage(town, cargo, roadType) {
	// Initialise a few details
	local truckStation = !AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS);
	local stationType = (truckStation) ? AIStation.STATION_TRUCK_STOP : AIStation.STATION_BUS_STOP;
	local radius = AIStation.GetCoverageRadius(stationType);
	local offset = AIMap.GetTileIndex(radius, radius);

	// Get a list of our stations in the town	
	local stationList = AIStationList(stationType);
	stationList.Valuate(AIStation.IsWithinTownInfluence, town);
	stationList.RemoveValue(0);
	
	// Ensure the stations have the correct road type
	stationList.Valuate(function (station, roadType) {
		return (AIRoad.HasRoadType(AIStation.GetLocation(station), roadType)) ? 1 : 0;
	}, roadType);
	stationList.RemoveValue(0);
	
	
	// Get a list of tiles that fall within the coverage area of those stations
	local coveredTiles = AITileList();
	foreach(station, _ in stationList) {
		local tile = AIStation.GetLocation(station);
		coveredTiles.AddRectangle(tile - offset, tile + offset);
	}
	
	// Include competitors stations if we are not agressive
	if(!PathZilla.IsAggressive()) {
		// Get a large area around the town
		local townTile = AITown.GetLocation(town);
		local searchRadius = min(AIMap.DistanceFromEdge(townTile) - 1, 20);
		local off = AIMap.GetTileIndex(searchRadius, searchRadius);
		local tileList = AITileList();
		tileList.AddRectangle(townTile - off, townTile + off);		

		// Find those tiles that are controlled by competitors
		foreach(tile, _ in tileList) {
			local owner = AITile.GetOwner(tile);
			local isCompetitors = (owner != AICompany.ResolveCompanyID(AICompany.MY_COMPANY) && owner != AICompany.ResolveCompanyID(AICompany.INVALID_COMPANY));
			
			// If its a station tile and not ours then look into it
			if(AITown.IsWithinTownInfluence(town, tile) && isCompetitors && AITile.IsStationTile(tile)) {
				// Identify the station type
				local stRadius = 0;
				if(AIRoad.IsRoadStationTile(tile)) {
					stRadius = AIStation.GetCoverageRadius(AIStation.STATION_BUS_STOP);
				} else if(AITile.HasTransportType(tile, AITile.TRANSPORT_RAIL)) {
					stRadius = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);
				} else if(AIMarine.IsDockTile(tile)) {
					stRadius = AIStation.GetCoverageRadius(AIStation.STATION_DOCK);
				} else if(AIAirport.IsAirportTile(tile)) {
					// TODO - This doesn't work - yet!
					stRadius = AIAirport.GetAirportCoverageRadius(AIAirport.GetAirportType(tile));
				}
				
				// Add the station's coverage radius to the list
				if(stRadius > 0) {
					local offs = AIMap.GetTileIndex(stRadius, stRadius);
					coveredTiles.AddRectangle(tile - offs, tile + offs);
				}
			}
		}
	}

	coveredTiles.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 0);
	coveredTiles.RemoveBelowValue(1);

	//AILog.Info(AITown.GetName(town) + " has " + AITown.GetHouseCount(town) + " houses");
	//AILog.Info(coveredTiles.Count() + " tiles covered");
	
	return (coveredTiles.Count() * 100) / AITown.GetHouseCount(town);
}

/*
 * Build enough stations in a town such that the combined coverage meets or
 * exceeds the target coverage percentage.
 * 
 * The function returns the number of stations that were added.
 */
function RoadManager::BuildStations(town, cargo, roadType, target) {
	local numStationsBuilt = 0;

	// Set the correct road type before starting
	AIRoad.SetCurrentRoadType(roadType);

	// Get the type of station that is needed	
	local truckStation = !AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS);
	local stationType = (truckStation) ? AIStation.STATION_TRUCK_STOP : AIStation.STATION_BUS_STOP;

	// Get the stations already built in the town
	local stationList = AIStationList(stationType);
	stationList.Valuate(AIStation.IsWithinTownInfluence, town);
	stationList.RemoveValue(0);
	
	// Build new stations if there are none or until the coverage exceeds the target
	local stationID = 0;
	while(((stationList.Count() + numStationsBuilt == 0) || RoadManager.GetTownCoverage(town, cargo, roadType) <= target) && stationID >= 0) {
		PathZilla.Sleep(1);

		stationID = RoadManager.BuildStation(town, cargo, roadType);
		if(stationID >= 0) {
			numStationsBuilt++;
		}
	}

	return numStationsBuilt;
}

/*
 * Build a single station in the specified town to accept the specified cargo.
 * The position of the station will be selected based on the maximum level
 * of acceptance.
 *
 * The function will attempt to build a DTRS if the selected position has road
 * either side of it.
 */
function RoadManager::BuildStation(town, cargo, roadType) {
	local townTile = AITown.GetLocation(town);
	
	// Get the type of station we should build	
	local truckStation = !AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS);
	local stationType = (truckStation) ? AIStation.STATION_TRUCK_STOP : AIStation.STATION_BUS_STOP;
	
	// Get a list of existing stations
	local stationList = AIStationList(stationType);
	stationList.Valuate(AIStation.IsWithinTownInfluence, town);
	stationList.RemoveValue(0);
	
	// Initialise some presets
	local radius = AIStation.GetCoverageRadius(stationType);
	local stationSpacing = (radius * 3) / 2;
	local comptSpacing = (PathZilla.IsAggressive() || stationList.Count() == 0) ? 1 : stationSpacing;

	// Get a list of tiles to search in
	local searchRadius = min(AIMap.DistanceFromEdge(townTile) - 1, 20);
	local offset = AIMap.GetTileIndex(searchRadius, searchRadius);
	local tileList = AITileList();
	tileList.AddRectangle(townTile - offset, townTile + offset);
		
	// Find a list of tiles that are controlled by competitors
	foreach(tile, _ in tileList) {
		local owner = AITile.GetOwner(tile);
		local isCompetitors = (owner != AICompany.ResolveCompanyID(AICompany.MY_COMPANY) && owner != AICompany.ResolveCompanyID(AICompany.INVALID_COMPANY));

		if(AITile.IsStationTile(tile) && isCompetitors) {
			local offs = AIMap.GetTileIndex(comptSpacing, comptSpacing);
			tileList.RemoveRectangle(tile - offs, tile + offs);
		} else if(AITile.IsStationTile(tile) || isCompetitors) {
			tileList.RemoveTile(tile);
		}
	}
	
	// Get the spacing offset for our stations
	offset = AIMap.GetTileIndex(stationSpacing, stationSpacing);
	
	// Iterate over the list of our stations, to ensure they aren't built too close
	foreach(station, _ in stationList) {
		local tile = AIStation.GetLocation(station);
		tileList.RemoveRectangle(tile - offset, tile + offset);
	}
	
	// Check if the game allows us to build DTRSes on town roads and get the road type
	local dtrsOnTownRoads = (AIGameSettings.GetValue("construction.road_stop_on_town_road") == 1);

	// Rank those tiles by their suitability for a station
	tileList.Valuate(function (tile, town, cargo, radius, dtrsOnTownRoads, roadType) {
		// Get the cargo acceptance around the tile
		local acceptance = AITile.GetCargoAcceptance(tile, cargo, 1, 1, radius);
		
		// Find suitable roads adjacent to the tile
		local adjRoads = LandManager.GetAdjacentTileList(tile);
		adjRoads.Valuate(function (_tile, roadType) {
			//return (AITile.HasTransportType(_tile, AITile.TRANSPORT_ROAD) && AIRoad.HasRoadType(_tile, roadType)) ? 1 : 0;
			return (AIRoad.IsRoadTile(_tile)) ? 1 : 0;
		}, roadType);
		adjRoads.KeepValue(1);
		
		// Check if the road tile is straight, i.e. if we can build a DTRS on it
		local straightRoad = AIRoad.IsRoadTile(tile) && (adjRoads.Count() == 1 || (adjRoads.Count() == 2 && adjRoads.Begin() == LandManager.GetApproachTile(tile, adjRoads.Next())));

		// Find the roads that would run parallel to a DTRS in this spot
		local parallelRoads = LandManager.GetAdjacentTileList(tile);
		if(adjRoads.Count() > 0) {
			local roadTile = adjRoads.Begin();
	
			parallelRoads.RemoveTile(roadTile);
			parallelRoads.RemoveTile(LandManager.GetApproachTile(tile, roadTile));
			parallelRoads.Valuate(AIRoad.IsRoadTile);
			parallelRoads.KeepValue(1);
		}

		// Check if this tile is acceptable
		local acceptable = AITown.IsWithinTownInfluence(town, tile) && LandManager.IsLevel(tile) && adjRoads.Count() > 0;
		
		// Check if we are allowed to build DTRSs on town roads
		if(dtrsOnTownRoads) {
			// If so and we are on a road tile, the road must be suitable for a DTRS
			acceptable = acceptable && (adjRoads.Count() < 3) && ((AIRoad.IsRoadTile(tile)) ? straightRoad : (parallelRoads.Count() == 0 && AITile.IsBuildable(tile)));
		} else {
			// If not, the tile must not be a road and be clearable
			acceptable = acceptable && !AIRoad.IsRoadTile(tile) && LandManager.IsClearable(tile);
		} 
		
		// If the spot is acceptable, return a the level of acceptance
		return (acceptable) ? acceptance : 0;
	}, town, cargo, radius, dtrsOnTownRoads, roadType);
			
	// Remove those tiles that don't produce enough
	tileList.RemoveBelowValue(8);
	
	// If we can't find any suitable tiles then just give up!			
	if(tileList.Count() == 0) {
		if(stationList.Count() == 0) {
			AILog.Error("  Bus stop could not be built in " + AITown.GetName(town) + "!");
		}
		
		return -1;
	}
	
	// Get the best location for the station
	local stationTile = tileList.Begin();
	
	// Check that we're able to build here first
	local rating = AITown.GetRating(town, AICompany.MY_COMPANY);
	local allowed = (rating == AITown.TOWN_RATING_NONE || rating > AITown.TOWN_RATING_VERY_POOR);
	if(!allowed) {
		AILog.Error(AITown.GetName(town) + " local authority refuses construction");
		return -1;
	}
	
	// Find the road tile that we should connect to
	local neighbourList = LandManager.GetAdjacentTileList(stationTile);
	neighbourList.Valuate(function (tile, stationTile) {
		local otherSide = LandManager.GetApproachTile(stationTile, tile);
		return (AIRoad.IsRoadTile(tile) && RoadManager.CanRoadTilesBeConnected(tile, stationTile, otherSide)) ? ((AIRoad.IsRoadTile(otherSide)) ? 2 : 1) : 0;
	}, stationTile);
	neighbourList.RemoveValue(0);
	local roadTile = neighbourList.Begin();
	
	// Check if the tile on the OTHER side is also road
	local otherSide = LandManager.GetApproachTile(stationTile, roadTile);
	
	// Test to see if we should demolish the tile on the other side of the road
	local demolished = true;
	if((dtrsOnTownRoads && LandManager.IsClearable(otherSide)
		 && !(AITile.HasTransportType(otherSide, AITile.TRANSPORT_ROAD) || AITile.IsBuildable(otherSide)))
		 || (!dtrsOnTownRoads && roadType == AIRoad.ROADTYPE_TRAM)) {
		demolished = AITile.DemolishTile(otherSide);
	}
	
	// If we could not demolish the tile then we can't continue
	if(!demolished) {
		AISign.BuildSign(stationTile, "COULD NOT DEMOLISH");
		local strType = (truckStation) ? "TRUCK" : ((roadType == AIRoad.ROADTYPE_TRAM) ? "TRAM" : "BUS");
		AILog.Error("COULD NOT CLEAR AREA FOR " + strType + " STOP!");
		return -1;
	}

	// Test to see if we should build a DTRS
	local useDtrs = (roadType == AIRoad.ROADTYPE_TRAM)
		 || ((AITile.HasTransportType(otherSide, AITile.TRANSPORT_ROAD) || AITile.IsBuildable(otherSide))
		 && RoadManager.CanRoadTilesBeConnected(roadTile, stationTile, otherSide));
	
	// Ensure we have a bit of cash available
	FinanceManager.EnsureFundsAvailable(PathZilla.FLOAT);
	
	// Connect the site to the road(s)
	local built = RoadManager.SafelyBuildRoad(roadTile, stationTile);
	if(useDtrs && built) {
		built = RoadManager.SafelyBuildRoad(otherSide, stationTile);
	}

	if(!built) {
		// TODO - Handle this situation more gracefully
		local strType = (truckStation) ? "TRUCK" : ((roadType == AIRoad.ROADTYPE_TRAM) ? "TRAM" : "BUS");
		AILog.Error("COULD NOT CONNECT ROAD TO " + strType + " STOP!");
		return -1;
	}
	
	AILog.Info("  Building a " + ((useDtrs)? "drive through " : "") + "station...");
	
	// Clean up little road stubs, if any
	if(AIRoad.IsRoadTile(stationTile)) {
		local sideRoads = LandManager.GetAdjacentTileList(stationTile);
		sideRoads.RemoveTile(roadTile);
		sideRoads.RemoveTile(otherSide);
		foreach(side, _ in sideRoads) {
			AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
			AIRoad.RemoveRoad(stationTile, side);
			AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_TRAM);
			AIRoad.RemoveRoad(stationTile, side);
		}

		// Reset the original road type
		AIRoad.SetCurrentRoadType(roadType); 
	}

	// Build the station
	local success = AIRoad.BuildRoadStation(stationTile, roadTile, truckStation, useDtrs, false);
	
	if(!success) {
		local strType = (truckStation) ? "TRUCK" : ((roadType == AIRoad.ROADTYPE_TRAM) ? "TRAM" : "BUS");
		AILog.Error(strType + " STOP WAS NOT BUILT");
		AISign.BuildSign(stationTile, ""+trnc(AIError.GetLastErrorString()));
		return -1;
	}
	
	// If we have built a DTRS, build a loop in the road to give vehicles somewhere to go
	if(success && useDtrs) {
		AILog.Info("  Building a loop...");
		local loopTile = (stationTile != townTile) ? townTile : roadTile;
		local sideRoads = LandManager.GetAdjacentTileList(stationTile);
		sideRoads.RemoveTile(roadTile);
		sideRoads.RemoveTile(otherSide);

		// Build the road loops
		PathFinder.FindPath(otherSide, loopTile, roadType, [stationTile], false)
		if(loopTile != roadTile) PathFinder.FindPath(roadTile, loopTile, roadType, [stationTile], false)
	}
	
	return AIStation.GetStationID(stationTile);
}

/*
 * Build a road from tileA to tileB, handling any errors that may occur.
 */
function RoadManager::SafelyBuildRoad(tileA, tileB) {
	local built = false;
	local tries = 0;
	local MAX_TRIES = 100;
	
	while(!built && tries++ < MAX_TRIES) {
		built = AIRoad.BuildRoad(tileA, tileB);
		
		if(!built) {
			switch(AIError.GetLastError()) {
				case AIError.ERR_ALREADY_BUILT:
					// Just don't worry about this!
					built = true;
				break;
				case AIError.ERR_AREA_NOT_CLEAR:
					// Something must have been built since we check the tile. Clear it.
					local cleared = AITile.DemolishTile(tileB);
					
					if(!cleared) {
						AILog.Error("    Construction of bus stop was blocked");
						return cleared;
					}
				break;
				case AIError.ERR_NOT_ENOUGH_CASH:
					AILog.Error("        CAN'T AFFORD IT!");
					if(!FinanceManager.CanAfford(PathZilla.FLOAT)) {
						// We cant afford to borrow any more money, so give up!
						AILog.Error("          ABORT!!");
						return false;
					} else {
						// Otherwise, borrow some more money
						FinanceManager.EnsureFundsAvailable(PathZilla.FLOAT);
					}
				break;
				case AIError.ERR_VEHICLE_IN_THE_WAY:
					AILog.Error("        Vehicle in the way");
					// Theres a vehicle in the way... just wait a bit.
					PathZilla.Sleep(100);
				break;
			}
		}
	}
	
	return built;
}

/*
 * Check if a road can be built at aTile that will connect to bTile from zTile
 */
function RoadManager::CanRoadTilesBeConnected(zTile, aTile, bTile, ...) {
	local origTile = zTile;
	if(origTile == null) {
		local tiles = LandManager.GetAdjacentTileList(aTile);
		tiles.RemoveTile(bTile);
		tiles.Valuate(AIRoad.IsRoadTile);
		tiles.KeepValue(1);
		if(tiles.Count() > 0) {
			origTile = tiles.Begin();
		} else {
			// Just make something up!!
			origTile = aTile - (bTile - aTile);
		}
	} else if(AITile.GetDistanceManhattanToTile(aTile, zTile) > 1) {
		origTile = LandManager.InferOtherEndTile(zTile, aTile);
	}
	
	local connectable = AIRoad.CanBuildConnectedRoadPartsHere(aTile, origTile, bTile) > 0;
	
	if(AIRoad.IsDriveThroughRoadStationTile(aTile)) {
		connectable = connectable && (AIRoad.GetRoadStationFrontTile(aTile) == bTile || AIRoad.GetDriveThroughBackTile(aTile) == bTile);
	}

	if(AIRoad.IsDriveThroughRoadStationTile(bTile)) {
		connectable = connectable && (AIRoad.GetRoadStationFrontTile(bTile) == aTile || AIRoad.GetDriveThroughBackTile(bTile) == aTile);
	} else if(AIRoad.IsRoadTile(bTile)) {
		local nRoads = LandManager.GetAdjacentTileList(bTile);
		nRoads.Valuate(function (tile, bTile) {
			return (AIRoad.IsRoadTile(tile) && AIRoad.AreRoadTilesConnected(tile, bTile)) ? 1 : 0;
		}, bTile);
		nRoads.KeepValue(1);
		
		foreach(roadTile, _ in nRoads) {
			connectable = connectable && (AIRoad.CanBuildConnectedRoadPartsHere(bTile, aTile, roadTile) != 0);
		}
	}
	
	return connectable;
}