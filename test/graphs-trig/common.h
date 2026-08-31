#define SPLIT_SEMI(x)           optional {x##_SPLIT_SEMI apf:strSplit (x ";")}
#define SYSREFSYS(x)            bind(replace(x,"(.+):.*","$1") as x##_SYSREFSYS) 
#define SYSREFID(x)             bind(if(regex(x,".+:(.+)"),replace(x,".+:(.+)","$1"),?UNDEF) as x##_SYSREFID)
#define SYS_PRIMARY(x)          bind(if(x="engineeringbaseSap","engineeringbase",x) as x##_SYS_PRIMARY)
#define SYS_SECONDARY(x)        bind(if(x="engineeringbaseSap","sappm",?UNDEF) as x##_SYS_SECONDARY)
