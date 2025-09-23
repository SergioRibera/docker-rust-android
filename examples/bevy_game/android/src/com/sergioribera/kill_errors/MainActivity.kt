package com.sergioribera.bevy_game

import android.view.View
import com.google.androidgamesdk.GameActivity

class MainActivity: GameActivity() {

    companion object {
        init {
            System.loadLibrary("bevy_game")
        }
    }
}
