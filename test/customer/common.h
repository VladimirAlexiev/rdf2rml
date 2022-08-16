#define URLIFY(x)         bind(replace(replace(replace(x, "[^\\p{L}0-9]", "_"), "_+", "_"), "^_|_$", "") as x##_URLIFY)
