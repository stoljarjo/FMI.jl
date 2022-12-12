# Simulate an FMU in different modes
Tutorial by Johannes Stoljar, Tobias Thummerer

## License


```julia
# Copyright (c) 2021 Tobias Thummerer, Lars Mikelsons, Josef Kircher, Johannes Stoljar
# Licensed under the MIT license. 
# See LICENSE (https://github.com/thummeto/FMI.jl/blob/main/LICENSE) file in the project root for details.
```

## Motivation
This Julia Package *FMI.jl* is motivated by the use of simulation models in Julia. Here the FMI specification is implemented. FMI (*Functional Mock-up Interface*) is a free standard ([fmi-standard.org](http://fmi-standard.org/)) that defines a container and an interface to exchange dynamic models using a combination of XML files, binaries and C code zipped into a single file. The user can thus use simulation models in the form of an FMU (*Functional Mock-up Units*). Besides loading the FMU, the user can also set values for parameters and states and simulate the FMU both as co-simulation and model exchange simulation.

## Introduction to the example
In this example we want to show how fast and easy the simulation for an FMU is. For this purpose, the FMU is simulated in co-simulation mode and in model-exchange mode. After the FMU has been simulated, the simulation results are displayed in a graph. The graphs of the different modes are compared with each other. The used model is a one-dimensional spring pendulum with friction. The object-orientated structure of the *SpringFrictionPendulum1D* can be seen in the following graphic.

![svg](https://github.com/thummeto/FMI.jl/blob/main/docs/src/examples/pics/SpringFrictionPendulum1D.svg?raw=true)  


## Target group
The example is primarily intended for users who work in the field of simulations. The example wants to show how simple it is to use FMUs in Julia.


## Other formats
Besides, this [Jupyter Notebook](https://github.com/thummeto/FMI.jl/blob/examples/examples/simulate.ipynb) there is also a [Julia file](https://github.com/thummeto/FMI.jl/blob/examples/examples/simulate.jl) with the same name, which contains only the code cells and for the documentation there is a [Markdown file](https://github.com/thummeto/FMI.jl/blob/examples/examples/simulate.md) corresponding to the notebook.  


## Getting started

### Installation prerequisites
|     | Description                       | Command                   | Alternative                                    |   
|:----|:----------------------------------|:--------------------------|:-----------------------------------------------|
| 1.  | Enter Package Manager via         | ]                         |                                                |
| 2.  | Install FMI via                   | add FMI                   | add " https://github.com/ThummeTo/FMI.jl "     |
| 3.  | Install FMIZoo via                | add FMIZoo                | add " https://github.com/ThummeTo/FMIZoo.jl "  |
| 4.  | Install Plots via                 | add Plots                 |                                                |

## Code section

To run the example, the previously installed packages must be included. 


```julia
# imports
using FMI
using FMIZoo
using Plots
```

### Simulation setup

Next, the start time and end time of the simulation are set. Finally, a step size is specified to store the results of the simulation at these time steps.


```julia
tStart = 0.0
tStep = 0.01
tStop = 8.0
tSave = tStart:tStep:tStop
```




    0.0:0.01:8.0



### Import FMU

In the next lines of code the FMU model from *FMIZoo.jl* is loaded and the information about the FMU is shown.


```julia
# we use an FMU from the FMIZoo.jl
pathToFMU = get_model_filename("SpringFrictionPendulum1D", "Dymola", "2022x")

myFMU = fmiLoad(pathToFMU)
# fmiLoad("path/to/myFMU.fmu"; unpackPath = "path/to/unpacked/fmu/")

fmiInfo(myFMU)
```

    #################### Begin information for FMU ####################
    	Model name:			SpringFrictionPendulum1D
    	FMI-Version:			2.0
    	GUID:				{2e178ad3-5e9b-48ec-a7b2-baa5669efc0c}
    	Generation tool:		Dymola Version 2022x (64-bit), 2021-10-08
    	Generation time:		2022-05-19T06:54:12Z
    	Var. naming conv.:		structured
    	Event indicators:		24
    	Inputs:				0
    	Outputs:			0
    	States:				2
    		33554432 ["mass.s"]
    		33554433 ["mass.v", "mass.v_relfric"]
    	Supports Co-Simulation:		true
    		Model identifier:	SpringFrictionPendulum1D
    		Get/Set State:		true
    		Serialize State:	true
    		Dir. Derivatives:	true
    		Var. com. steps:	true
    		Input interpol.:	true
    		Max order out. der.:	1
    	Supports Model-Exchange:	true
    		Model identifier:	SpringFrictionPendulum1D
    		Get/Set State:		true
    		Serialize State:	true
    		Dir. Derivatives:	true
    ##################### End information for FMU #####################


### Simulate FMU

In the following, the FMU is simulated in the two different simulation modes.

#### Simulate as Co-Simulation

In the next steps the recorded values are defined. The first state is the position of the mass and the second state is the velocity. In the function `fmiSimulateCS()` the FMU is simulated in co-simulation mode (CS) with an adaptive step size but with fixed save points `tSave`. In addition, the start and end time and the recorded variables are specified.


```julia
vrs = ["mass.s", "mass.v"]

dataCS = fmiSimulateCS(myFMU, tStart, tStop; recordValues=vrs, saveat=tSave)
```




    Model name:
    	SpringFrictionPendulum1D
    Success:
    	true
    Values [801]:
    	0.0	(0.5, 0.0)
    	0.01	(0.5002235448486548, 0.042692491939260585)
    	0.02	(0.5008715291319449, 0.08568000508550636)
    	0.03	(0.5019478597521578, 0.12892136998736314)
    	0.04	(0.5034570452098334, 0.17232325681284336)
    	0.05	(0.5053993458877354, 0.2158440857658765)
    	0.06	(0.5077764240578201, 0.259420181133082)
    	0.07	(0.5105886522837868, 0.30295578207463486)
    	0.08	(0.5138351439717114, 0.3464184707972189)
    	...
    	8.0	(1.071367253976742, -1.000814138594347e-10)
    Events [0]:




#### Simulate as Model-Exchange

In the function `fmiSimulateME()` the FMU is simulated in model-exchange mode (ME) with an adaptive step size but with fixed save points `tSave`. In addition, the start and end time are specified. In contrast to the co-simulation, the values to be stored are not specified here, since the states and events of the FMU are always output as well. The identifiers given above just correspond to the states of the FMU.


```julia
dataME = fmiSimulateME(myFMU, tStart, tStop; saveat=tSave)
```

    [34mSimulating ME-FMU ... 100%|██████████████████████████████| Time: 0:00:08[39m





    Model name:
    	SpringFrictionPendulum1D
    Success:
    	true
    States [801]:
    	0.0	[0.5, 0.0]
    	0.01	[0.5002131418270838, 0.0426894507334239]
    	0.02	[0.5008548874900925, 0.08570846009092]
    	0.03	[0.5019281657668404, 0.12898390160770948]
    	0.04	[0.5034351795297135, 0.17244393632491634]
    	0.05	[0.5053774247131723, 0.21601821081124567]
    	0.06	[0.5077556991013391, 0.2596379123127895]
    	0.07	[0.5105701153011483, 0.3032358504004232]
    	0.08	[0.5138201146588821, 0.34674645322442477]
    	...
    	8.0	[1.0666323055577207, -7.603992128337398e-5]
    Events [6]:
    	State-Event #11 @ 0.0s
    	State-Event #11 @ 0.994s
    	State-Event #19 @ 1.9883s
    	State-Event #11 @ 2.9831s
    	State-Event #19 @ 3.9789s
    	State-Event #11 @ 4.977s




### Plotting FMU

After the simulation is finished the results of the FMU for the co-simulation and model-exchange mode can be plotted. In the plot for the FMU it can be seen that the oscillation continues to decrease due to the effect of the friction. If you simulate long enough, the oscillation comes to a standstill in a certain time.


```julia
fmiPlot(dataCS)
```




    
![svg](simulate_files/simulate_14_0.svg)
    




```julia
fmiPlot(dataME)
```




    
![svg](simulate_files/simulate_15_0.svg)
    



From both graphs it can be seen that the simulation calculates exactly the same results.

### Unload FMU

After plotting the data, the FMU is unloaded and all unpacked data on disc is removed.


```julia
fmiUnload(myFMU)
```

### Summary

Based on this tutorial it can be seen that simulating in the different mode is very easy, and it only takes a few commands to simulate the FMU. 