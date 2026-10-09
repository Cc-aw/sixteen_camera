#ifndef XDEBUG_H
#define XDEBUG_H

#define XDEBUG_ERROR 0U
#define XDEBUG_WARNING 0U
#define XDEBUG_INFO 0U
#define XDBG_DEBUG_GENERAL 0U
#define xdbg_printf(type, ...) do { (void)(type); } while (0)

#endif
