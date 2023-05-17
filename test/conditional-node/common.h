#define _IF_BOUND(x,...)   bind(if(bound(coalesce(__VA_ARGS__),#x,?UNDEF) as ?x##_IF_BOUND)
