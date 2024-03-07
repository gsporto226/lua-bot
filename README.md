# Discord Lua Bot

A discord bot written in lua featuring music playback on voice channels, text-to-speech and a few text games.

## Installation

You have to install a few dependencies before running the bot.

First install luvit following these [instructions](https://luvit.io/install.html).  

Next you need to get `libsodium`, `libopus` and `ffmpeg`, these should be available to install using your system's package manager.  

For instance this is how you would install both packages on Arch linux:
```bash
sudo pacman -S libsodium opus ffmpeg
```

Lastly you will need `yt-dlp`, there are detailed install instructions on the project's github [page](https://github.com/yt-dlp/yt-dlp?tab=readme-ov-file#installation).  

After installing it, you need to rename the binary to `youtube-dl` and have it be available through the PATH

## Usage

Head over to discord's developer page and get a bot token, then create an ENVIRONMENT VARIABLE named `BOT_TOKEN` with 
the value of the generated Token. *Becareful to not leak this token as it could be used maliciously.*

Finally, run `luvit bot.lua` and the bot should start working.

## Contributing

This is a deprecated project.

## License

[MIT](https://choosealicense.com/licenses/mit/)
