# Shell By Mail

What if the only way to interact with a remote server would be via SMTP?

This project consists of a `postfix` container to which you can send a mail with shell commands to be evaluated. You should get a reply with the evaluation result.

[Development Writeup](https://nevesnunes.github.io/blog/2019/08/27/Shell-By-Mail.html)

## Running

Start by copying each `*.example`, replacing each mock value, and removing the `.example` extension. Shell commands are specified in `request.txt`.

Build and run the image with `make`.

Send a mail with `./request.sh`.
