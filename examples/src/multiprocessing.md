# Multiprocessing
Tutorial by Jonas Wilfert, Tobias Thummerer

## License


```julia
# Copyright (c) 2021 Tobias Thummerer, Lars Mikelsons, Josef Kircher, Johannes Stoljar, Jonas Wilfert
# Licensed under the MIT license. 
# See LICENSE (https://github.com/thummeto/FMI.jl/blob/main/LICENSE) file in the project root for details.
```

## Motivation
This Julia Package *FMI.jl* is motivated by the use of simulation models in Julia. Here the FMI specification is implemented. FMI (*Functional Mock-up Interface*) is a free standard ([fmi-standard.org](http://fmi-standard.org/)) that defines a container and an interface to exchange dynamic models using a combination of XML files, binaries and C code zipped into a single file. The user can thus use simulation models in the form of an FMU (*Functional Mock-up Units*). Besides loading the FMU, the user can also set values for parameters and states and simulate the FMU both as co-simulation and model exchange simulation.

## Introduction to the example
This example shows how to parallelize the computation of an FMU in FMI.jl. We can compute a batch of FMU-evaluations in parallel with different initial settings.
Parallelization can be achieved using multithreading or using multiprocessing. This example shows **multiprocessing**, check `multithreading.ipynb` for multithreading.
Advantage of multithreading is a lower communication overhead as well as lower RAM usage.
However in some cases multiprocessing can be faster as the garbage collector is not shared.


The model used is a one-dimensional spring pendulum with friction. The object-orientated structure of the *SpringFrictionPendulum1D* can be seen in the following graphic.

![svg](https://github.com/thummeto/FMI.jl/blob/main/docs/src/examples/pics/SpringFrictionPendulum1D.svg?raw=true)  


## Target group
The example is primarily intended for users who work in the field of simulations. The example wants to show how simple it is to use FMUs in Julia.


## Other formats
Besides, this [Jupyter Notebook](https://github.com/thummeto/FMI.jl/blob/examples/examples/src/multiprocessing.ipynb) there is also a [Julia file](https://github.com/thummeto/FMI.jl/blob/examples/examples/src/multiprocessing.jl) with the same name, which contains only the code cells and for the documentation there is a [Markdown file](https://github.com/thummeto/FMI.jl/blob/examples/examples/src/multiprocessing.md) corresponding to the notebook.  


## Getting started

### Installation prerequisites
|     | Description                       | Command                   | Alternative                                    |   
|:----|:----------------------------------|:--------------------------|:-----------------------------------------------|
| 1.  | Enter Package Manager via         | ]                         |                                                |
| 2.  | Install FMI via                   | add FMI                   | add " https://github.com/ThummeTo/FMI.jl "     |
| 3.  | Install FMIZoo via                | add FMIZoo                | add " https://github.com/ThummeTo/FMIZoo.jl "  |
| 4.  | Install FMICore via               | add FMICore               | add " https://github.com/ThummeTo/FMICore.jl " |
| 5.  | Install BenchmarkTools via        | add BenchmarkTools        |                                                |

## Code section



Adding your desired amount of processes:


```julia
using Distributed
n_procs = 2
addprocs(n_procs; exeflags=`--project=$(Base.active_project()) --threads=auto`, restrict=false)
```




    2-element Vector{Int64}:
     2
     3



To run the example, the previously installed packages must be included. 


```julia
# imports
@everywhere using FMI
@everywhere using FMIZoo
@everywhere using BenchmarkTools
```

Checking that we workers have been correctly initialized:


```julia
workers()

@everywhere println("Hello World!")

# The following lines can be uncommented for more advanced informations about the subprocesses
# @everywhere println(pwd())
# @everywhere println(Base.active_project())
# @everywhere println(gethostname())
# @everywhere println(VERSION)
# @everywhere println(Threads.nthreads())
```

    Hello World!
          From worker 2:	Hello World!
          From worker 3:	Hello World!


### Simulation setup

Next, the batch size and input values are defined.


```julia

# Best if batchSize is a multiple of the threads/cores
batchSize = 16

# Define an array of arrays randomly
input_values = collect(collect.(eachrow(rand(batchSize,2))))
```




    16-element Vector{Vector{Float64}}:
     [0.8115852940755863, 0.051662480900393826]
     [0.9552762970886637, 0.21583747897653338]
     [0.19087818431900927, 0.257838945545794]
     [0.8826317125176851, 0.023663451842458993]
     [0.5732888772749084, 0.5731585483547428]
     [0.5889736339417088, 0.01391715319225495]
     [0.32471184870266356, 0.9336849134169248]
     [0.5373823730072235, 0.104252021151514]
     [0.4833410178677554, 0.77769433789146]
     [0.8565709907357574, 0.5587777339192599]
     [0.48975641247288715, 0.002710939711934257]
     [0.2663841416958439, 0.5572587251118387]
     [0.3220744039154845, 0.6604437544783567]
     [0.8266102887926963, 0.1492649820948635]
     [0.9207381794718318, 0.4192768593797537]
     [0.053168669306802974, 0.23227369436286482]



### Shared Module
For Distributed we need to embed the FMU into its own `module`. This prevents Distributed from trying to serialize and send the FMU over the network, as this can cause issues. This module needs to be made available on all processes using `@everywhere`.


```julia
@everywhere module SharedModule
    using FMIZoo
    using FMI

    t_start = 0.0
    t_step = 0.1
    t_stop = 10.0
    tspan = (t_start, t_stop)
    tData = collect(t_start:t_step:t_stop)

    model_fmu = FMIZoo.fmiLoad("SpringPendulum1D", "Dymola", "2022x")
end
```

We define a helper function to calculate the FMU and combine it into an Matrix.


```julia
@everywhere function runCalcFormatted(fmu, x0, recordValues=["mass.s", "mass.v"])
    data = fmiSimulateME(fmu, SharedModule.tspan; recordValues=recordValues, saveat=SharedModule.tData, x0=x0, showProgress=false, dtmax=1e-4)
    return reduce(hcat, data.states.u)
end
```

Running a single evaluation is pretty quick, therefore the speed can be better tested with BenchmarkTools.


```julia
@benchmark data = runCalcFormatted(SharedModule.model_fmu, rand(2))
```




    BenchmarkTools.Trial: 7 samples with 1 evaluation.
     Range [90m([39m[36m[1mmin[22m[39m … [35mmax[39m[90m):  [39m[36m[1m764.016 ms[22m[39m … [35m785.305 ms[39m  [90m┊[39m GC [90m([39mmin … max[90m): [39m0.00% … 4.70%
     Time  [90m([39m[34m[1mmedian[22m[39m[90m):     [39m[34m[1m773.930 ms               [22m[39m[90m┊[39m GC [90m([39mmedian[90m):    [39m4.75%
     Time  [90m([39m[32m[1mmean[22m[39m ± [32mσ[39m[90m):   [39m[32m[1m776.056 ms[22m[39m ± [32m  8.157 ms[39m  [90m┊[39m GC [90m([39mmean ± σ[90m):  [39m4.06% ± 1.79%
    
      [39m█[39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m█[39m [39m [39m [39m [39m [39m [39m [34m█[39m[39m [39m [39m [39m█[39m [39m [39m [39m [39m [32m [39m[39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m [39m█[39m [39m [39m [39m [39m [39m [39m [39m█[39m█[39m [39m 
      [39m█[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m█[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[34m█[39m[39m▁[39m▁[39m▁[39m█[39m▁[39m▁[39m▁[39m▁[39m▁[32m▁[39m[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m█[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m▁[39m█[39m█[39m [39m▁
      764 ms[90m           Histogram: frequency by time[39m          785 ms [0m[1m<[22m
    
     Memory estimate[90m: [39m[33m152.68 MiB[39m, allocs estimate[90m: [39m[33m6801393[39m.



### Single Threaded Batch Execution
To compute a batch we can collect multiple evaluations. In a single threaded context we can use the same FMU for every call.


```julia
println("Single Threaded")
@benchmark collect(runCalcFormatted(SharedModule.model_fmu, i) for i in input_values)
```

    Single Threaded





    BenchmarkTools.Trial: 1 sample with 1 evaluation.
     Single result which took [34m12.357 s[39m (3.91% GC) to evaluate,
     with a memory estimate of [33m2.39 GiB[39m, over [33m108822290[39m allocations.



### Multithreaded Batch Execution
In a multithreaded context we have to provide each thread it's own fmu, as they are not thread safe.
To spread the execution of a function to multiple processes, the function `pmap` can be used.


```julia
println("Multi Threaded")
@benchmark pmap(i -> runCalcFormatted(SharedModule.model_fmu, i), input_values)
```

    Multi Threaded





    BenchmarkTools.Trial: 1 sample with 1 evaluation.
     Single result which took [34m6.941 s[39m (0.00% GC) to evaluate,
     with a memory estimate of [33m79.98 KiB[39m, over [33m1235[39m allocations.



As you can see, there is a significant speed-up in the median execution time. But: The speed-up is often much smaller than `n_procs` (or the number of physical cores of your CPU), this has different reasons. For a rule of thumb, the speed-up should be around `n/2` on a `n`-core-processor with `n` Julia processes.

### Unload FMU

After calculating the data, the FMU is unloaded and all unpacked data on disc is removed.


```julia
@everywhere fmiUnload(SharedModule.model_fmu)
```

### Summary

In this tutorial it is shown how multi processing with `Distributed.jl` can be used to improve the performance for calculating a Batch of FMUs.