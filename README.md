# shell-logger

Logger for shell script, working on Bash and Zsh.

This includes functions of `debug`, `info`(`information`), `notice`(`notification`), `warn`(`warning`) and `err`(`error`).
Each output is formatted with date-time and colored by each color definition.

These color codes are removed when the output is passed to a pipe or written into files.

* Use as interactive command

![shelllogger](https://github.com/rcmdnk/shell-logger/blob/images/shelllogger.jpg)

* Each output and color

![colors](https://github.com/rcmdnk/shell-logger/blob/images/colors.jpg)

* Traceback  at error

![traceback](https://github.com/rcmdnk/shell-logger/blob/images/traceback.jpg)


## Installation

You can use an install script on the web like:

    $ curl -fsSL https://raw.github.com/rcmdnk/shell-logger/install/install.sh| sh

This will install scripts to `/usr/etc`
and you may be asked root password.

If you want to install other directory, do like:

    $ curl -fsSL https://raw.github.com/rcmdnk/shell-logger/install/install.sh|  prefix=~/usr/local/ sh

On Mac, you can install **etc/shell-logger** by Homebrew:

    $ brew tap rcmdnk/rcmdnkpac/shell-logger

The file will be installed in **$(brew --prefix)/etc** (normally **/usr/local/etc**).

Otherwise download shell-logger and place it where you like.


Once **shell-logger** is installed,
source it in your `.bashrc` or `.zshrc` like:

```bash
source /path/to/shell-logger
```

## Usage

In your script, source shell-logger:

    source /path/to/shell-logger

Then, you can use such `info` or `err` command in your script like:

```bash
#!/bin/bash

source /usr/local/etc/shell-logger

test_command
ret=$?
if [ ret = 0 ];then
  info Command succeeded.
else
  err Command failed!
fi
```

Each level has each functions:

LEVEL|Functions
:----|:--------
DEBUG|`debug`
INFO|`info`, `information`
NOTICE|`notice`, `notification`
WARNING|`warn`, `warning`
ERROR|`err`, `error`

## Options

Variable Name|Description|Default
:------------|:----------|:-----
LOGGER_DATE_FORMAT|Output date format.|'%Y/%m/%d %H:%M:%S'
LOGGER_LEVEL|0: DEBUG, 1: INFO, 2: NOTICE, 3: WARN, 4: ERROR|1
LOGGER_STDERR_LEVEL|For levels greater than equal this level, outputs will go stderr.|4
LOGGER_DEBUG_COLOR|Color for DEBUG|"3;32" (Green Italic. Some terminal shows it as color inversion)
LOGGER_INFO_COLOR|Color for INFO|"95" (Bright Magenta)
LOGGER_NOTICE_COLOR|Color for NOTICE|"96" (Bright Cyan)
LOGGER_WARNING_COLOR|Color for WARNING|"93" (Bright Yellow)
LOGGER_ERROR_COLOR|Color for ERROR|"91" (Bright Red)
LOGGER_COLOR|Color mode: never->Always no color. auto->Put color only for terminal output. always->Always put color.|auto
LOGGER_LEVELS|Names printed for each level. Need 5 names.|("DEBUG" "INFO" "NOTICE" "WARNING" "ERROR")

About colors, you can find the standard definitions in
[Standard ECMA-48](https://ecma-international.org/wp-content/uploads/ECMA-48_5th_edition_june_1991.pdf)
(pages 61-62).

For more detailed information about ANSI escape code sequences see
[ANSI Escape Sequences](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797)

Most terminals support 8 and 16 colors, as well as 256 (8-bit) colors.
These colors are set by the user, but have commonly defined meanings:

| Color Name | Foreground Color Code | Background Color Code |
| :--------- | :-------------------- | :-------------------- |
| Black      | `30`                  | `40`                  |
| Red        | `31`                  | `41`                  |
| Green      | `32`                  | `42`                  |
| Yellow     | `33`                  | `43`                  |
| Blue       | `34`                  | `44`                  |
| Magenta    | `35`                  | `45`                  |
| Cyan       | `36`                  | `46`                  |
| White      | `37`                  | `47`                  |
| Default    | `39`                  | `49`                  |
| Reset      | `0`                   | `0`                   |
> **Note:** the _Reset_ color is the reset code that resets _all_ colors and text effects, Use _Default_ color to reset colors only.

Most terminals, apart from the basic set of 8 colors, also support the "bright" or "bold" colors. These have their
own set of codes, mirroring the normal colors, but with an additional `;1` in their codes:

```sh
# Set style to bold, red foreground.
\x1b[1;31mHello
# Set style to dimmed white foreground with red background.
\x1b[2;37;41mWorld
```

Terminals that support the [aixterm specification](https://sites.ualberta.ca/dept/chemeng/AIX-43/share/man/info/C/a_doc_lib/cmds/aixcmds1/aixterm.htm) provides bright versions of the ISO colors, without the need to use the bold modifier:

| Color Name     | Foreground Color Code | Background Color Code |
| :------------- | :-------------------- | :-------------------- |
| Bright Black   | `90`                  | `100`                 |
| Bright Red     | `91`                  | `101`                 |
| Bright Green   | `92`                  | `102`                 |
| Bright Yellow  | `93`                  | `103`                 |
| Bright Blue    | `94`                  | `104`                 |
| Bright Magenta | `95`                  | `105`                 |
| Bright Cyan    | `96`                  | `106`                 |
| Bright White   | `97`                  | `107`                 |

You can set display (letter's color) and background in the same time.
For example, if you want to use red background and white front color for error output,
set:

    LOGGER_ERROR_COLOR="37;41"

You can easily check colors by [escseqcheck](https://github.com/rcmdnk/escape_sequence/blob/master/bin/escseqcheck).
