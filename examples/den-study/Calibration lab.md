---
type: experiment
status: synthetic-check-passed
---
# Rotational flow, honest residuals

Start with a model small enough to falsify. Check the implementation on both hosts before trusting a physical calibration.

## The question

Does a rotational-flow gain predict held-out samples, or merely fit what it has already seen?

For the model $\hat y = kx$, the through-origin least-squares gain is

$$k = \frac{\sum_i x_i y_i}{\sum_i x_i^2}.$$

The synthetic check uses dimensionless, normalized $x,y$. A physical calibration must name its sensor units, frame convention and timing assumptions explicitly.

## Predict before fitting

Generate $y = 0.8x + \epsilon$, with seeded Gaussian noise of standard deviation $0.02$. A useful held-out fit should recover a gain near $0.8$ and residuals near $0.02$.

| Actual check | Arete | Homie |
|---|---:|---:|
| Gain | 0.799351 | 0.799351 |
| Held-out RMS | 0.020161 | 0.020161 |
| Null-model RMS | 0.797713 | 0.797713 |

Different NumPy patch versions, matching results. No hardware was attached to this check.

## What this does not prove

A low residual cannot rescue timestamp misalignment, a wrong coordinate frame or unobserved translation. An intercept can conceal bias; inspect it rather than silently folding it into the gain.

**Next physical test:** isolate rotation, record synchronized IMU/flow observations, preserve raw logs, then compare held-out residuals with the null model.

[[Mechanism.canvas|Follow the mechanism]] · [Actual Mongla source](https://github.com/fh1m/mongla_ws/blob/c67a0805206b88a25e541a5fe0c3a95afb168b40/tools/flow_derot_calibrate.py) · [Reproduce the synthetic check](https://github.com/fh1m/.dotfiles/blob/main/examples/den-calibration-check.py)
