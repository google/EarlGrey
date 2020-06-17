#ifndef _EDISTANTOBJECT_SERVICE_SOURCES_EDOTIMINGFUNCTIONS_H_
#define _EDISTANTOBJECT_SERVICE_SOURCES_EDOTIMINGFUNCTIONS_H_

#include <mach/mach_time.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 *  Gets the elapsed time between now and the given @c machTime and converts
 *  into milliseconds.
 */
double EDOGetMillisecondsSinceMachTime(uint64_t machTime);

#ifdef __cplusplus
}
#endif

#endif  // _EDISTANTOBJECT_SERVICE_SOURCES_EDOTIMINGFUNCTIONS_H_
