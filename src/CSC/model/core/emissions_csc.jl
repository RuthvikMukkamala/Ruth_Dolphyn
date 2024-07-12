"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
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

@doc raw"""
    emissions_csc(EP::Model, inputs::Dict, setup::Dict)

This function creates expression to add the CO2 emissions for carbon supply chain in each zone, which is subsequently added to the total emissions. 

These include emissions from fuel utilization in DAC minus CO2 captured by flue gas CCS and also pipeline losses.

In addition, there is a constraint that specify that amount of CO2 that undergoes compression in each zone has to be equal to the amount of CO2 captured by DAC

```math
\begin{equation*}
    x_{z,t}^{\textrm{C,DAC}} = x_{z,t}^{\textrm{C,COMP}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
"""
function emissions_csc(EP::Model, inputs::Dict, setup::Dict)

	println("CO2 Emissions Module for CO2 Policy modularization")

	dfDAC = inputs["dfDAC"]
    DAC_RES_ALL = inputs["DAC_RES_ALL"]

    dfCO2CaptureComp = inputs["dfCO2CaptureComp"]

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

    # If setup["ParameterScale] = 1, emissions expression and constraints are written in ktonnes
    # If setup["ParameterScale] = 0, emissions expression and constraints are written in tonnes
    # Adjustment of Fuel_CO2 units carried out in load_fuels_data.jl

    #CO2 emitted by fuel usage per type of resource "k"
    if setup["ParameterScale"] ==1
        @expression(EP,eDAC_Fuel_CO2_Production_per_plant_per_time[k=1:DAC_RES_ALL,t=1:T], 
            inputs["fuel_CO2"][dfDAC[!,:Fuel][k]] * dfDAC[!,:etaFuel_MMBtu_per_tonne][k] * EP[:vDAC_CO2_Captured][k,t] *  (1-dfDAC[!, :Fuel_CCS_Rate][k]) * ModelScalingFactor) #As fuel CO2 is already scaled to kton/MMBtu we need to scale vDAC_CO2_Captured
    else
        @expression(EP,eDAC_Fuel_CO2_Production_per_plant_per_time[k=1:DAC_RES_ALL,t=1:T], 
        inputs["fuel_CO2"][dfDAC[!,:Fuel][k]] * dfDAC[!,:etaFuel_MMBtu_per_tonne][k] * EP[:vDAC_CO2_Captured][k,t] *  (1-dfDAC[!, :Fuel_CCS_Rate][k]))
    end

    #Total DAC carbon captured per zone by
    @expression(EP, eDAC_CO2_Captured_per_zone_per_time[z=1:Z, t=1:T], sum(EP[:vDAC_CO2_Captured][k,t] for k in dfDAC[(dfDAC[!,:Zone].==z),:R_ID]))


    #Total emission per zone, need to minus CO2 loss in pipelines
    @expression(EP, eDAC_Emissions_per_zone_per_time[z=1:Z, t=1:T], sum(eDAC_Fuel_CO2_Production_per_plant_per_time[k,t] for k in dfDAC[(dfDAC[!,:Zone].==z),:R_ID]))

    if setup["ModelCO2Pipelines"] ==1 & setup["CO2Pipeline_Loss"] ==1 
        @expression(EP, eCSC_Emissions_per_zone_per_time[z=1:Z, t=1:T], EP[:eDAC_Emissions_per_zone_per_time][z,t] + EP[:eCO2Loss_Pipes_zt][z,t])
    else
        @expression(EP, eCSC_Emissions_per_zone_per_time[z=1:Z, t=1:T], EP[:eDAC_Emissions_per_zone_per_time][z,t])
    end
    
    ###################################################################################################################################################################

    ##Compression
    #Amount of carbon compressed for storage or transport
    #Carbon compressed = Carbon captured per zone by DAC
    @expression(EP, eCO2_Capture_Compressed_per_zone[z=1:Z, t=1:T], sum(EP[:vCO2_Capture_Compressed][k,t] for k in dfCO2CaptureComp[(dfCO2CaptureComp[!,:Zone].==z),:R_ID]))
    @constraint(EP,cCaptured_Equals_Compressed_CO2[z=1:Z, t=1:T], eCO2_Capture_Compressed_per_zone[z,t] == eDAC_CO2_Captured_per_zone_per_time[z,t])
    ###################################################################################################################################################################

    return EP
end
