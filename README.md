# ffmpeg-windows-build-script

Helper script to cross compile FFmpeg for 64bit Windows.

Assumed OS is Debian or derivatives (uses apt to install needed packages).

## Usage
`git clone https://github.com/JohannesKauffmann/ffmpeg-windows-build-script && cd ffmpeg-windows-build-script`
Make sure to clone the repo somewhere with plenty of free space and write permissions.

Next, give the files executable permission:
`chmod +x compileffmpeg.sh environment-x86_64-w64-mingw32`

Finally, run the script:
`./compileffmpeg.sh`

You might be prompted for admin rights, as this script will install some dependencies through `apt`.

Inspired by [rdp](https://github.com/rdp/ffmpeg-windows-build-helpers/).
