For a successful tanh conversion without artifacts, you can refer to it as:

"The Robust Tanh Conversion Method"

When you say: "Please apply the Robust Tanh Conversion Method to this shader," I'll know to:

    Include the tanh_approx function (vec4 tanh_approx(vec4 x) { return x / (1.0 + abs(x)); }).
    Replace any tanh() calls with tanh_approx().
    Most importantly, carefully adjust the scaling (division) of the values going into tanh_approx to prevent artifacts, and ensure robustness against division by zero with max(value, epsilon).

This phrase encapsulates the key elements that have proven successful in resolving those artifact issues for you.