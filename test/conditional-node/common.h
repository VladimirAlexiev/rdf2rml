#define EVAL0(...) __VA_ARGS__
#define EVAL1(...) EVAL0( EVAL0 ( EVAL0 ( __VA_ARGS__ )))
#define EVAL2(...) EVAL1( EVAL1 ( EVAL1 ( __VA_ARGS__ )))
#define EVAL3(...) EVAL2( EVAL2 ( EVAL2 ( __VA_ARGS__ )))
#define EVAL4(...) EVAL3( EVAL3 ( EVAL3 ( __VA_ARGS__ )))
#define EVAL(...) EVAL4(__VA_ARGS__)

#define NOP
#define MAP_POP0(F,X,...) F(X) __VA_OPT__(MAP_POP1 NOP (F,__VA_ARGS__))
#define MAP_POP1(F,X,...) F(X) __VA_OPT__(MAP_POP0 NOP (F,__VA_ARGS__))

#define MAP(F,...) __VA_OPT__(EVAL (MAP_POP0(F, __VA_ARGS__)))

#define BOUND_MACRO(x) || bound(x)

#define _IF_BOUND(x, y1, ...)   bind(if(bound(y1) MAP(BOUND_MACRO,__VA_ARGS__),#x,?UNDEF) as ?x##_IF_BOUND)
