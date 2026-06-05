# 003 - Live mic pitch detection for the Tuner

## Context
The Tuner ships with a working reference-tone / visual mode. Live mic pitch detection
is a documented stub. The design intent is the bottom pointer tracking the played
pitch and going orange -> green when in tune.

## What to do
- Capture mic audio (web: getUserMedia + AudioWorklet/ScriptProcessor; mobile: a
  pitch package). Run a pitch detector (YIN/autocorrelation) on the buffer.
- Map detected frequency to the nearest target string note and drive the existing
  bottom-pointer position + in-tune color state.
- Degrade gracefully if mic permission is denied (keep reference-tone mode).
- Best validated on a real device (hardware mic) - flag for Joe to test.

## Acceptance
- Playing a string moves the bottom pointer and turns it green when in tune.
- No crash / clean fallback when mic is unavailable.
