package com.sergioribera.rustlib;

import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity implements JNICallback {

    private static final String TAG = "MainActivity";

    // Used to load the 'rust' library on application startup.
    static {
        System.loadLibrary("rust_lib");
    }

    TextView textView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        textView = (TextView) findViewById(R.id.sample_text);

        invokeCallbackViaJNI(this);
    }

    /**
     * A native method that is implemented by the 'rust' native library,
     * which is packaged with this application.
     */
    public static native void invokeCallbackViaJNI(JNICallback callback);

    @Override
    public void callback(String string) {
        textView.append("From JNI: " + string + "\n");
    }
}
