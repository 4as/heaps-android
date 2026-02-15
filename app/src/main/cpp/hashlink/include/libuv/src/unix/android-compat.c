#include <signal.h>

int uv__pthread_sigmask(int how, const sigset_t* set, sigset_t* oldset) {
  return pthread_sigmask(how, set, oldset);
}