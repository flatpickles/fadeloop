# fadeloop

This is a video editing script that can create a perfect looping video from any input. It does this by cross-fading the video into itself.

Here's the editing process, provided `input_file` and `duration` (in seconds):

- `input_file` is split into three temporary files: A, B, and C. A and C are both `duration` long.
- One more temporary file is created, D, which fades from C into A, creating a crossfade for the final loop.
- B is concatenated with D,

There are some caveats to using this:

- Audio tracks aren't yet supported
- The output file will be shorter than the input by `duration`
- The output file will start `duration` into the original video input

Example usage:

```
./fadeloop.sh input.mp4 1
```
