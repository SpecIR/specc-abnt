---Gaussian Distribution view type module.
---Pure-schema alias of the abnt model's GAUSS view: `extends` inherits the
---`dataset` hook through the host's extends chain (no cross-model require).
return {
    kind = "view",
    schema = {
        id = "GAUSSIAN",
        extends = "GAUSS",
        long_name = "Gaussian Distribution",
        description = "Gaussian/Normal distribution curve data (alias for gauss)",
    },
}
