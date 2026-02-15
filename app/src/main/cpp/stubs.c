#include <hl.h>
#include <jni.h>
#include <pcre2.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <_std/String.h>
#include <std/string.c>
#include "sdl2/include/SDL_system.h" // For SDL_AndroidGetJNIEnv

/*
 * Dummy implementations for PCRE2 JIT functions to satisfy the linker
 * when JIT is disabled.
 */

int pcre2_jit_compile_16(pcre2_code_16 *code, uint32_t options) {
    return PCRE2_ERROR_JIT_BADOPTION;
}

void pcre2_jit_free_16(pcre2_code_16 *code) {
    /* Do nothing */
}

int pcre2_jit_match_16(const pcre2_code_16 *code, PCRE2_SPTR16 subject, PCRE2_SIZE length,
                     PCRE2_SIZE startoffset, uint32_t options,
                     pcre2_match_data_16 *match_data, pcre2_match_context_16 *mcontext) {
    return PCRE2_ERROR_JIT_BADOPTION;
}

const uint8_t * pcre2_default_tables_16 = NULL;

/*
 * Create aliases for symbols that the linker expects with a leading underscore.
 */
void _pcre2_jit_free_16(pcre2_code_16 *code) __attribute__((alias("pcre2_jit_free_16")));
extern const uint8_t * _pcre2_default_tables_16 __attribute__((alias("pcre2_default_tables_16")));

extern hl_type t$String;

#define HL_NAME(n) forus_##n

HL_PRIM String HL_NAME(get_writable_directory)()
{
    // Use SDL's public API to get the JNIEnv for the current thread.
    // This function will handle attaching the thread to the VM if necessary.
    JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv();
    if (!env) {
        return NULL;
    }

    jclass activityClass = (*env)->FindClass(env, "io/heaps/android/HeapsActivity");
    if (!activityClass) {
        return NULL;
    }

    jmethodID getDir = (*env)->GetStaticMethodID(env, activityClass,
                                                 "getFilesDirPath",
                                                 "()Ljava/lang/String;");
    if (!getDir) {
        return NULL;
    }

    jstring result = (jstring)(*env)->CallStaticObjectMethod(env, activityClass, getDir);
    if (!result) {
        return NULL;
    }

    const char* path = (*env)->GetStringUTFChars(env, result, NULL);
    if (!path) {
        return NULL;
    }

    // Create a HashLink string from the Java string
    int length = 0;
    int *size = &length;
    vbyte *hl_path = hl_copy_bytes(path, (int)strlen(path) + 1);
    String r5 = (String)hl_alloc_obj(&t$String);
    r5->bytes = hl_utf8_to_utf16(hl_path, 0, size);
    r5->length = length >> 1;

    // Release the JNI string
    (*env)->ReleaseStringUTFChars(env, result, path);
    (*env)->DeleteLocalRef(env, result);
    (*env)->DeleteLocalRef(env, activityClass);

    return r5;
}

// Global variables for text input
static vclosure *text_input_callback = NULL;
static char *text_input_result = NULL;
static bool text_input_done = false;

JNIEXPORT void JNICALL Java_io_heaps_android_HeapsActivity_onTextInputResult(JNIEnv *env, jclass clazz, jstring text) {
    if (text) {
        const char *nativeString = (*env)->GetStringUTFChars(env, text, 0);
        if (text_input_result) free(text_input_result);
        text_input_result = strdup(nativeString);
        (*env)->ReleaseStringUTFChars(env, text, nativeString);
    } else {
        if (text_input_result) free(text_input_result);
        text_input_result = NULL;
    }
    text_input_done = true;
}

HL_PRIM void HL_NAME(request_text_input)(String msg, String defaultText, bool password, int maxLength, vclosure *cb) {
    if (text_input_callback) {
        hl_remove_root(&text_input_callback);
    }
    text_input_callback = cb;
    if (cb) hl_add_root(&text_input_callback);

    text_input_done = false;
    if (text_input_result) {
        free(text_input_result);
        text_input_result = NULL;
    }

    JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv();
    if (!env) return;

    jclass activityClass = (*env)->FindClass(env, "io/heaps/android/HeapsActivity");
    if (!activityClass) return;

    jmethodID method = (*env)->GetStaticMethodID(env, activityClass, "requestTextInput", "(Ljava/lang/String;Ljava/lang/String;ZI)V");
    if (!method) return;

    jstring jMsg = (msg && msg->bytes) ? (*env)->NewStringUTF(env, hl_to_utf8((uchar*)msg->bytes)) : NULL;
    jstring jDef = (defaultText && defaultText->bytes) ? (*env)->NewStringUTF(env, hl_to_utf8((uchar*)defaultText->bytes)) : NULL;

    (*env)->CallStaticVoidMethod(env, activityClass, method, jMsg, jDef, (jboolean)password, (jint)maxLength);

    (*env)->DeleteLocalRef(env, activityClass);
    if (jMsg) (*env)->DeleteLocalRef(env, jMsg);
    if (jDef) (*env)->DeleteLocalRef(env, jDef);
}

HL_PRIM void HL_NAME(poll_text_input)() {
    if (text_input_done) {
        if (text_input_callback) {
             String ret = NULL;
             if (text_input_result) {
                 ret = (String)hl_alloc_obj(&t$String);
                 ret->bytes = hl_to_utf16(text_input_result);
                 ret->length = ustrlen(ret->bytes);
             }

             hl_call1(void, text_input_callback, String, ret);

             hl_remove_root(&text_input_callback);
             text_input_callback = NULL;
        }
        text_input_done = false;
        if (text_input_result) {
            free(text_input_result);
            text_input_result = NULL;
        }
    }
}

DEFINE_PRIM(_VOID, request_text_input, _STRING _STRING _BOOL _I32 _FUN(_VOID, _STRING));
DEFINE_PRIM(_VOID, poll_text_input, _NO_ARG);
