package com.sergioribera.slint_test

import android.os.Bundle
import android.app.NativeActivity
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.annotation.Keep

class MainActivity : NativeActivity() {

    companion object {
        const val CONTENT_VIEW_ID = 10101010

        init {
            System.loadLibrary("slint_test")
        }
    }

    private var containerLayout: ViewGroup? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val frame = FrameLayout(this).apply {
            id = CONTENT_VIEW_ID
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        setContentView(frame)

        if (savedInstanceState == null) {
            containerLayout = FrameLayout(this).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
            }
        }
    }
}
