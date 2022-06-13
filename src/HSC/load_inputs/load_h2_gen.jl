function load_h2_gen(setup::Dict, path::AbstractString, sep::AbstractString, inputs_gen::Dict)

	#Read in H2 generation related inputs
    h2_gen_in = DataFrame(CSV.File(string(path,sep,"HSC_generation.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	h2_gen_in[!,:R_ID] = 1:size(collect(skipmissing(h2_gen_in[!,1])),1)

    # Store DataFrame of generators/resources input data for use in model
	inputs_gen["dfH2Gen"] = h2_gen_in

    # Index of H2 resources - can be either commit, no_commit production technologies, demand side, G2P, or storage resources
	inputs_gen["H2_RES_ALL"] = size(collect(skipmissing(h2_gen_in[!,:R_ID])),1)

	# Name of H2 Generation resources
	inputs_gen["H2_RESOURCES_NAME"] = collect(skipmissing(h2_gen_in[!,:H2_Resource][1:inputs_gen["H2_RES_ALL"]]))
	
	# Resource identifiers by zone (just zones in resource order + resource and zone concatenated)
	h2_zones = collect(skipmissing(h2_gen_in[!,:Zone][1:inputs_gen["H2_RES_ALL"]]))
	inputs_gen["H2_R_ZONES"] = h2_zones
	inputs_gen["H2_RESOURCE_ZONES"] = inputs_gen["H2_RESOURCES_NAME"] .* "_z" .* string.(h2_zones)

	# Set of flexible demand-side resources
	inputs_gen["H2_FLEX"] = h2_gen_in[h2_gen_in.H2_FLEX.==1,:R_ID]

	# To do - will add a list of storage resources or we can keep them separate
	# Set of H2 storage resources
	inputs_gen["H2_STOR_ALL"] = h2_gen_in[h2_gen_in.H2_STOR.==1,:R_ID]

	# Defining whether H2 storage is modeled as long-duration (inter-period energy transfer allowed) or short-duration storage (inter-period energy transfer disallowed)
	inputs_gen["H2_STOR_LONG_DURATION"] = h2_gen_in[(h2_gen_in.LDS.==1) .& (h2_gen_in.H2_STOR.==1),:R_ID]
	inputs_gen["H2_STOR_SHORT_DURATION"] = h2_gen_in[(h2_gen_in.LDS.==0) .& (h2_gen_in.H2_STOR.==1),:R_ID]

	# Set of all storage resources eligible for new energy capacity
	inputs_gen["NEW_CAP_H2_ENERGY"] = intersect(h2_gen_in[h2_gen_in.New_Build.==1,:R_ID], h2_gen_in[h2_gen_in.Max_Energy_Cap_tonne.!=0,:R_ID], inputs_gen["H2_STOR_ALL"])
	# Set of all storage resources eligible for energy capacity retirements
	inputs_gen["RET_CAP_H2_ENERGY"] = intersect(h2_gen_in[h2_gen_in.New_Build.!=-1,:R_ID], h2_gen_in[h2_gen_in.Existing_Energy_Cap_tonne.>0,:R_ID], inputs_gen["H2_STOR_ALL"])

	# Set of asymmetric charge/discharge storage resources eligible for new charge capacity, which for H2 storage refers to compression power requirements
	inputs_gen["NEW_CAP_H2_CHARGE"] = intersect(h2_gen_in[h2_gen_in.New_Build.==1,:R_ID], h2_gen_in[h2_gen_in.Max_Charge_Cap_tonne_p_hr.!=0,:R_ID], inputs_gen["H2_STOR_ALL"])
	# Set of asymmetric charge/discharge storage resources eligible for charge capacity retirements
	inputs_gen["RET_CAP_H2_CHARGE"] = intersect(h2_gen_in[h2_gen_in.New_Build.!=-1,:R_ID], h2_gen_in[h2_gen_in.Existing_Charge_Cap_tonne_p_hr.>0,:R_ID], inputs_gen["H2_STOR_ALL"])
	
	# Set of H2 generation resources
	# Set of h2 resources eligible for unit committment - either continuous or discrete capacity -set by setup["H2GenCommit"]
	inputs_gen["H2_GEN_COMMIT"] = intersect(h2_gen_in[h2_gen_in.H2_GEN_TYPE.==1 ,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!=1 ,:R_ID])
	# Set of h2 resources eligible for unit committment
	inputs_gen["H2_GEN_NO_COMMIT"] = intersect(h2_gen_in[h2_gen_in.H2_GEN_TYPE.==2 ,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!=1 ,:R_ID])

    #Set of all H2 production Units - can be either commit or new commit
    inputs_gen["H2_GEN"] = union(inputs_gen["H2_GEN_COMMIT"],inputs_gen["H2_GEN_NO_COMMIT"])

    # Set of all resources eligible for new capacity - includes both storage and generation
	# DEV NOTE: Should we allow investment in flexible demand capacity later on?
	inputs_gen["H2_GEN_NEW_CAP"] = intersect(h2_gen_in[h2_gen_in.New_Build.==1 ,:R_ID], h2_gen_in[h2_gen_in.Max_Cap_tonne_p_hr.!=0,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!= 1,:R_ID]) 
	# Set of all resources eligible for capacity retirements
	# DEV NOTE: Should we allow retirement of flexible demand capacity later on?
	inputs_gen["H2_GEN_RET_CAP"] = intersect(h2_gen_in[h2_gen_in.New_Build.!=-1,:R_ID], h2_gen_in[h2_gen_in.Existing_Cap_tonne_p_hr.>=0,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!=1,:R_ID])

	# Fixed cost per start-up ($ per MW per start) if unit commitment is modelled
	start_cost = convert(Array{Float64}, collect(skipmissing(inputs_gen["dfH2Gen"][!,:Start_Cost_per_tonne_p_hr])))
	
	inputs_gen["C_H2_Start"] = inputs_gen["dfH2Gen"][!,:Cap_Size_tonne_p_hr].* start_cost

    
	# Direct CO2 emissions per tonne of H2 produced for various technologies
	inputs_gen["dfH2Gen"][!,:CO2_per_tonne] = zeros(Float64, inputs_gen["H2_RES_ALL"])

	
	#### TO DO LATER ON - CO2 constraints

	# for k in 1:inputs_gen["H2_RES_ALL"]
	# 	# NOTE: When Setup[ParameterScale] =1, fuel costs and emissions are scaled in fuels_data.csv, so no if condition needed to scale C_Fuel_per_MWh
	# 	# IF ParameterScale = 1, then CO2 emissions intensity Units ktonne/tonne
	# 	# If ParameterScale = 0 , then CO2 emission intensity units is tonne/tonne
	# 	inputs_gen["dfH2Gen"][!,:CO2_per_tonne][g] =inputs_gen["fuel_CO2"][dfH2Gen[!,:Fuel][k]][t] * dfH2Gen[!,:etaFuel_MMBtu_p_tonne][k]))

	# end

	println("HSC_generation.csv Successfully Read!")

    return inputs_gen

end
