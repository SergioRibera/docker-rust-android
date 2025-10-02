package com.sergioribera.rustlib

import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.sergioribera.rustlib.R

class MainActivity : AppCompatActivity(), JNICallback {
    var textView: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        textView = findViewById(R.id.sample_text)

        invokeCallbackViaJNI(this)
    }

    override fun callback(string: String?) {
        textView!!.append("From JNI: $string\n")
    }

    /**
     * A native method that is implemented by the 'rust' native library,
     * which is packaged with this application.
     */
    external fun invokeCallbackViaJNI(callback: JNICallback?)

    companion object {
        // Used to load the 'rust' library on application startup.
        init {
            System.loadLibrary("rust_lib")
        }
    }
}
