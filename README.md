# Ribasim

[![codecov](https://codecov.io/gh/Deltares/Ribasim/branch/main/graph/badge.svg)](https://codecov.io/gh/Deltares/Ribasim)

**Documentation: https://deltares.github.io/Ribasim/**

Ribasim is a water resources model, designed to be the replacement of the regional surface
water modules Mozart and SIMRES in the Netherlands Hydrological Instrument (NHI). Ribasim is
a work in progress, it is a prototype that demonstrates all essential functionalities.
Further development of the prototype in a software release is planned in 2022 and 2023.

Ribasim is written in the [Julia programming language](https://julialang.org/) and is built
on top of the [SciML: Open Source Software for Scientific Machine Learning](https://sciml.ai/)
libraries, notably [ModelingToolkit.jl](https://mtk.sciml.ai/stable/).

The latest build can be downloaded here: [ribasim_cli.zip](https://ribasim.s3.eu-west-3.amazonaws.com/teamcity/Ribasim_Ribasim/BuildRibasimCliWindows/latest/ribasim_cli.zip).
Currently only Windows builds are available.

![Timeseries of
results](https://user-images.githubusercontent.com/4471859/179259333-070dfe18-8f43-4ac4-bb38-013b252e2e4b.png)

![Daily water
balance](https://user-images.githubusercontent.com/4471859/179259174-0caccd4a-c51b-449e-873c-17d48cfc8870.png)