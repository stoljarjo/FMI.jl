#
# Copyright (c) 2021 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

using FMI
import FMIZoo

# our simulation setup
t_start = 0.0
t_stop = 8.0

# we use a FMU from the FMIZoo.jl
pathToFMU = FMIZoo.get_model_filename("SpringFrictionPendulum1D", "Dymola", "2022x")

# load the FMU container
myFMU = fmiLoad(pathToFMU)

# print some useful FMU-information into the REPL
fmiInfo(myFMU)

# values we want to record 
rvs = ["mass.s"]

# make an instance from the FMU, this is optional if you are not interessted into instances
# fmiInstantiate!(myFMU; loggingOn=true)

# run the FMU in mode Model-Exchange (ME) with adaptive step sizes, result values are stored in `solution`
recordedValues = fmiSimulateME(myFMU, t_start, t_stop; recordValues=rvs)

# plot the results
using Plots
fig = fmiPlot(recordedValues)

# load in the FMI2.0.3 keywords like fmi2Component, fmi2Real, etc.
using FMICore 

# save, where the original `fmi2GetReal` function was stored, so we can access it in our new function
originalGetReal = myFMU.cGetReal

# custom function for fmi2GetReal!(fmi2Component, Union{Array{fmi2ValueReference}, Ptr{fmi2ValueReference}}, Csize_t, value::Union{Array{fmi2Real}, Ptr{fmi2Real}}::fmi2Status
# for information on how the FMI2-functions are structured, have a look inside FMICore.jl/src/FMI2_c.jl or the FMI2.0.3-specification on fmi-standard.org
function myGetReal!(c::fmi2Component, vr::Union{Array{fmi2ValueReference}, Ptr{fmi2ValueReference}}, nvr::Csize_t, value::Union{Array{fmi2Real}, Ptr{fmi2Real}})
    # first, we do what the original function does
    status = fmi2GetReal!(originalGetReal, c, vr, nvr, value)

    # if we have a pointer to an array, we must interprete it as array to access elements
    if isa(value, Ptr{fmi2Real})
        value = unsafe_wrap(Array{fmi2Real}, value, nvr, own=false)
    end

    # now, we multiply every value by two (just for fun!)
    for i in 1:nvr 
        value[i] *= 2.0 
    end 

    # ... and we return the original status
    return status
end

# no we overwrite the original function
fmiSetFctGetReal(myFMU, myGetReal!)

# run the *manipulated* FMU in mode Model-Exchange (ME) with adaptive step sizes, result values are stored in `solution`
recordedValues = fmiSimulateME(myFMU, t_start, t_stop; recordValues=rvs)

# plot the results, this time, everything has doubled!
fmiPlot!(fig, recordedValues; stateEvents=false, style=:dash)

# unload the FMU, remove unpacked data on disc ("clean up")
fmiUnload(myFMU)
