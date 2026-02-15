package io.heaps.android;

import org.libsdl.app.SDLActivity;
import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.widget.EditText;
import android.text.InputType;
import android.text.InputFilter;

public class HeapsActivity extends SDLActivity {
    private static HeapsActivity instance;

    // Used to load the native libraries on application startup.
    static {
        System.loadLibrary("openal");
        System.loadLibrary("SDL2");
        System.loadLibrary("heapsapp");
    }

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        instance = this;
    }

    @Override
    protected String[] getLibraries() {
        return new String[]{
                "openal",
                "SDL2",
                "heapsapp"
        };
    }

    public static Context getContext() {
        return instance.getApplicationContext();
    }

    /* Neither Heaps nor Haxe provide a way to find a writable application directory (in case you want to support save files, settings, etc.), which is why you need this method to provide an extern method in Haxe. */
    public static String getFilesDirPath() {
        return instance.getFilesDir().getAbsolutePath();
    }

    public static native void onTextInputResult(String text);

    public static void requestTextInput(final String message, final String initialText, final boolean isPassword, final int maxLength) {
        if (instance == null) return;
        instance.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                AlertDialog.Builder builder = new AlertDialog.Builder(instance);
                if (message != null) builder.setMessage(message);

                final EditText input = new EditText(instance);
                
                int inputType = InputType.TYPE_CLASS_TEXT;
                if (isPassword) {
                    inputType |= InputType.TYPE_TEXT_VARIATION_PASSWORD;
                }
                input.setInputType(inputType);

                if (initialText != null) input.setText(initialText);
                
                if (maxLength > 0) {
                    input.setFilters(new InputFilter[] { new InputFilter.LengthFilter(maxLength) });
                }

                builder.setView(input);

                builder.setPositiveButton("OK", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        onTextInputResult(input.getText().toString());
                    }
                });
                builder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        onTextInputResult(null);
                    }
                });
                
                builder.setCancelable(false);
                builder.show();
            }
        });
    }
}
