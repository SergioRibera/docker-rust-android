package com.sergioribera.bevy_game

import android.os.Bundle
/* import androidx.activity.ComponentActivity */
import android.app.NativeActivity
import android.content.Intent
import android.content.Context
import android.util.Log
import android.content.pm.PackageManager
import android.app.Activity
import android.app.Fragment
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.LayoutParams
import android.widget.FrameLayout
import androidx.annotation.CallSuper
import androidx.core.app.ActivityCompat
import androidx.annotation.Keep

class MainActivity: NativeActivity() {

    private var containerLayout: ViewGroup? = null

    companion object {
        const val CONTENT_VIEW_ID = 10101010

        init {
            System.loadLibrary("bevy_game")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val frame = FrameLayout(this)
        frame.setId(CONTENT_VIEW_ID)
        setContentView(frame, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))

        if (savedInstanceState === null) {
            containerLayout = FrameLayout(this)
            containerLayout?.setLayoutParams(
                ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
            )
        }
    }

    override fun onDestroy() {
        /* Log.v(TAG, "Destroying Game App...") */
        super.onDestroy()
    }
}
