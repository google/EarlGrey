//
// Copyright 2026 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "GREYWaitToken.h"

#include <pthread.h>
#include <sys/time.h>

#import "GREYFatalAsserts.h"

@implementation GREYWaitToken {
  pthread_mutex_t _mutex;
  pthread_cond_t _cond;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    pthread_mutexattr_t attr;
    int mutexattr_init_status = pthread_mutexattr_init(&attr);
    GREYFatalAssertWithMessage(mutexattr_init_status == 0, @"pthread_mutexattr_init failed");
    int mutexattr_setprotocol_status = pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT);
    GREYFatalAssertWithMessage(mutexattr_setprotocol_status == 0,
                               @"pthread_mutexattr_setprotocol failed");
    int mutex_init_status = pthread_mutex_init(&_mutex, &attr);
    GREYFatalAssertWithMessage(mutex_init_status == 0, @"pthread_mutex_init failed");
    int cond_init_status = pthread_cond_init(&_cond, NULL);
    GREYFatalAssertWithMessage(cond_init_status == 0, @"pthread_cond_init failed");
    int mutexattr_destroy_status = pthread_mutexattr_destroy(&attr);
    GREYFatalAssertWithMessage(mutexattr_destroy_status == 0, @"pthread_mutexattr_destroy failed");
    _signaled = NO;
  }
  return self;
}

- (void)dealloc {
  pthread_mutex_destroy(&_mutex);
  pthread_cond_destroy(&_cond);
}

- (pthread_mutex_t *)mutex {
  return &_mutex;
}

- (pthread_cond_t *)cond {
  return &_cond;
}

- (void)signal {
  int lock_status = pthread_mutex_lock(&_mutex);
  GREYFatalAssertWithMessage(lock_status == 0, @"pthread_mutex_lock failed");
  _signaled = YES;
  int signal_status = pthread_cond_signal(&_cond);
  GREYFatalAssertWithMessage(signal_status == 0, @"pthread_cond_signal failed");
  int unlock_status = pthread_mutex_unlock(&_mutex);
  GREYFatalAssertWithMessage(unlock_status == 0, @"pthread_mutex_unlock failed");
}

- (BOOL)wait {
  int lock_status = pthread_mutex_lock(&_mutex);
  GREYFatalAssertWithMessage(lock_status == 0, @"pthread_mutex_lock failed");
  while (!_signaled) {
    pthread_cond_wait(&_cond, &_mutex);
  }
  int unlock_status = pthread_mutex_unlock(&_mutex);
  GREYFatalAssertWithMessage(unlock_status == 0, @"pthread_mutex_unlock failed");
  return YES;
}

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout {
  struct timespec ts;
  struct timeval tv;
  gettimeofday(&tv, NULL);
  ts.tv_sec = tv.tv_sec + (long)timeout;
  ts.tv_nsec = (long)(tv.tv_usec * 1000 + (timeout - (long)timeout) * 1000000000L);
  if (ts.tv_nsec >= 1000000000L) {
    ts.tv_sec += 1;
    ts.tv_nsec -= 1000000000L;
  }

  int lock_status = pthread_mutex_lock(&_mutex);
  GREYFatalAssertWithMessage(lock_status == 0, @"pthread_mutex_lock failed");
  BOOL result = YES;
  while (!_signaled) {
    if (pthread_cond_timedwait(&_cond, &_mutex, &ts) != 0) {
      result = NO;
      break;
    }
  }
  int unlock_status = pthread_mutex_unlock(&_mutex);
  GREYFatalAssertWithMessage(unlock_status == 0, @"pthread_mutex_unlock failed");
  return result;
}

@end
