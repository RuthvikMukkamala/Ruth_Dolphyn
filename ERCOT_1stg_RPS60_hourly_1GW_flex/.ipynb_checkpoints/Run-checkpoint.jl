"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

cd(dirname(@__FILE__))

settings_path = joinpath(pwd(), "Settings")

#environment_path = "../../package_activate.jl"
#include(environment_path) #Run this line to activate the Julia virtual environment for GenX; skip it, if the appropriate package versions are installed

### Set relevant directory paths
src_path = "../../../src/"

inpath = pwd()

### Load GenX
println("Loading packages")
push!(LOAD_PATH, src_path)

using DOLPHYN
using YAML

@info("PACKAGE LOADED")

genx_settings = joinpath(settings_path, "genx_settings.yml") #Settings YAML file path for GenX
hsc_settings = joinpath(settings_path, "hsc_settings.yml") #Settings YAML file path for HSC modelgrated model
mysetup_genx = YAML.load(open(genx_settings)) # mysetup dictionary stores GenX-specific parameters
mysetup_hsc = YAML.load(open(hsc_settings)) # mysetup dictionary stores H2 supply chain-specific parameters
global_settings = joinpath(settings_path, "global_model_settings.yml") # Global settings for inte
mysetup_global = YAML.load(open(global_settings)) # mysetup dictionary stores global settings
mysetup_global = YAML.load(open(global_settings)) # mysetup dictionary stores global settings
combined_settings = Dict()
combined_settings = merge(mysetup_hsc, mysetup_genx, mysetup_global) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings

## Update settings by adding default values for various unspecified parameters
mysetup = Dict()
mysetup = configure_settings(combined_settings)
# Start logging

## Cluster time series inputs if necessary and if specified by the user
TDRpath = joinpath(inpath, mysetup["TimeDomainReductionFolder"])
if mysetup["TimeDomainReduction"] == 1
    if (!isfile(TDRpath*"/Load_data.csv")) || (!isfile(TDRpath*"/Generators_variability.csv")) || (!isfile(TDRpath*"/Fuels_data.csv")) || (!isfile(TDRpath*"/HSC_generators_variability.csv")) || (!isfile(TDRpath*"/HSC_load_data.csv"))
        println("Clustering Time Series Data...")
        cluster_inputs(inpath, settings_path, mysetup)
    else
        println("Time Series Data Already Clustered.")
    end
end

# ### Configure solver
println("Configuring Solver")
OPTIMIZER = configure_solver(mysetup["Solver"], settings_path)

# #### Running a case

# ### Load inputs
# println("Loading Inputs")
 myinputs = Dict() # myinputs dictionary will store read-in data and computed parameters
 myinputs = load_inputs(mysetup, inpath)

# ### Load H2 inputs if modeling the hydrogen supply chain
if mysetup["ModelH2"] == 1
    myinputs = load_h2_inputs(myinputs, mysetup, inpath)
end

# ### Generate model
# println("Generating the Optimization Model")
EP = generate_model(mysetup, myinputs, OPTIMIZER)

### Solve model
println("Solving Model")
EP, solve_time = solve_model(EP, mysetup)
myinputs["solve_time"] = solve_time # Store the model solve time in myinputs

### Write power system output

println("Writing Output")
outpath = "$inpath/Results"
outpath=write_outputs(EP, outpath, mysetup, myinputs)

# Write hydrogen supply chain outputs
if mysetup["ModelH2"] == 1
    outpath_H2 = "$outpath/Results_HSC"
    write_HSC_outputs(EP, outpath_H2, mysetup, myinputs)
end

# Run MGA if the MGA flag is set to 1 else only save the least cost solution
# Only valid for power system analysis at this point
if mysetup["ModelingToGenerateAlternatives"] == 1
    println("Starting Model to Generate Alternatives (MGA) Iterations")
    mga(EP,inpath,mysetup,myinputs,outpath)
end


# Write combined_settings that was used to solve the model file to help with troubleshooting
YAML.write_file(joinpath(settings_path,"combined_settings_output.yml"), mysetup)

