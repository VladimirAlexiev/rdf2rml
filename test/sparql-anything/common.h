#define URLIFY(x)               bind(replace(replace(replace(replace(x,"[^\\p{L}0-9]+",""),"ä","ae"),"ü","ue"),"ö","oe") as x##_URLIFY)
