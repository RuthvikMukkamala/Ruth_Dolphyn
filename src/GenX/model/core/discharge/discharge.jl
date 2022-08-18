"""
GenX: An Configurable Capacity Expansion Model
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

@doc raw"""
	discharge(EP::Model, inputs::Dict)

Sets up variables common to all generation resources.

This module defines the power generation decision variable $x_{k,t}^{E,THE} \forall k \in \mathcal{K}, t \in \mathcal{T}$, representing energy injected into the grid by thermal resource $k$ at time period $t$.

This module defines the power generation decision variable $x_{r,t}^{E,VRE} \forall r \in \mathcal{R}, t \in \mathcal{T}$, representing energy injected into the grid by renewable resource $r$ at time period $t$.

This module defines the power discharge decision variable $x_{s,t}^{E,DIS} \forall s \in \mathcal{S}, t \in \mathcal{T}$, representing energy injected into the grid by storage resource $s$ at time period $t$.

The variable defined in this file named after ```vP``` covers all variables $x_{k,t}^{E,THE}, x_{r,t}^{E,VRE}, x_{s,t}^{E,DIS}$.

```math
\begin{equation}
	x_{g,t}^{E,GEN} = 
	\begin{cases}
		x_{k,t}^{E,THE} if g \in \mathcal{K} \\
		x_{r,t}^{E,VRE} if g \in \mathcal{R} \\
		x_{s,t}^{E,DIS} if g \in \mathcal{S} \\
	\end{cases}
\end{equation}
```

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable O&M plus fuel cost) from all generation resources $g \in \mathcal{G}$ (thermal, renewable, storage, DR, flexible demand resources and hydro) over all time periods $t \in \mathcal{T}$:

```math
\begin{aligned}
	C^{E,GEN,o} =
	\sum_{g \in \mathcal{G} } \sum_{t \in \mathcal{T}}\omega_{t}\times\left(c_{g}^{E,VOM} + c_{g}^{E,FUEL}\right)\times x_{g,t}^{E,GEN}}
\end{aligned}
```
"""
function discharge(EP::Model, inputs::Dict)

	println("Discharge Module")

	dfGen = inputs["dfGen"]

	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps
	Z = inputs["Z"]     # Number of zones
	### Variables ###

	# Energy injected into the grid by resource "y" at hour "t"
	@variable(EP, vP[y=1:G,t=1:T] >=0);

	### Expressions ###

	## Objective Function Expressions ##

	# Variable costs of "generation" for resource "y" during hour "t" = variable O&M plus fuel cost
	@expression(EP, eCVar_out[y=1:G,t=1:T], (inputs["omega"][t]*(dfGen[!,:Var_OM_Cost_per_MWh][y]+inputs["C_Fuel_per_MWh"][y,t])*vP[y,t]))
	#@expression(EP, eCVar_out[y=1:G,t=1:T], (round(inputs["omega"][t]*(dfGen[!,:Var_OM_Cost_per_MWh][y]+inputs["C_Fuel_per_MWh"][y,t]), digits=RD)*vP[y,t]))
	# Sum individual resource contributions to variable discharging costs to get total variable discharging costs
	@expression(EP, eTotalCVarOutT[t=1:T], sum(eCVar_out[y,t] for y in 1:G))
	@expression(EP, eTotalCVarOut, sum(eTotalCVarOutT[t] for t in 1:T))

	# Add total variable discharging cost contribution to the objective function
	EP[:eObj] += eTotalCVarOut

	return EP

end
