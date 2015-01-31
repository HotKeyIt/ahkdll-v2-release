; AutoHotkey v2 alpha

; This is a substitute for "If value between low and high".  Note that
; using the expression directly can change the behaviour if the "value"
; part of the expression has side-effects.
between(value, low, high) {
    return value >= low && value <= high
}