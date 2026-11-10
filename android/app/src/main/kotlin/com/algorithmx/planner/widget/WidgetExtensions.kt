package com.algorithmx.planner.widget

import android.content.SharedPreferences

fun SharedPreferences.safeGetLong(key: String, defValue: Long = 0L): Long {
    // 1. Try string timestamp first (always safest across platform bridges)
    val strVal = getString("${key}_str", null) ?: getString(key, null)
    if (!strVal.isNullOrEmpty()) {
        strVal.toLongOrNull()?.let { return it }
    }

    // 2. Try native getLong
    return try {
        getLong(key, defValue)
    } catch (_: ClassCastException) {
        try {
            getInt(key, defValue.toInt()).toLong()
        } catch (_: Exception) {
            defValue
        }
    } catch (_: Exception) {
        defValue
    }
}

fun SharedPreferences.safeGetInt(key: String, defValue: Int = 0): Int {
    return try {
        getInt(key, defValue)
    } catch (_: ClassCastException) {
        try {
            getLong(key, defValue.toLong()).toInt()
        } catch (_: Exception) {
            try {
                getString(key, null)?.toIntOrNull() ?: defValue
            } catch (_: Exception) {
                defValue
            }
        }
    } catch (_: Exception) {
        defValue
    }
}

fun SharedPreferences.safeGetBoolean(key: String, defValue: Boolean = false): Boolean {
    return try {
        getBoolean(key, defValue)
    } catch (_: ClassCastException) {
        try {
            val str = getString(key, null)
            str?.toBoolean() ?: defValue
        } catch (_: Exception) {
            defValue
        }
    } catch (_: Exception) {
        defValue
    }
}
