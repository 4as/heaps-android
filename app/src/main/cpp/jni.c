#include <jni.h>
#include <SDL.h>

extern void hl_entry_point();

int SDL_main(int argc, char *argv[]) {
    (void)argc; // Unused parameter
    (void)argv; // Unused parameter
    hl_entry_point();
    return 0;
}
