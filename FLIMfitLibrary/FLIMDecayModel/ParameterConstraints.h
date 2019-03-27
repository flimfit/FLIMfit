#pragma once

double transformRange(double v, double v_min, double v_max);
double inverseTransformRange(double t, double v_min, double v_max);
double transformRangeDerivative(double v, double v_min, double v_max);

double kappaSpacer(double tau2, double tau1);
double constrainPositive(double x);
double constrainPositiveGradient(double x);

