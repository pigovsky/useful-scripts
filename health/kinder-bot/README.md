Create a telegram bot consuming user commands using the [`getUpdates`](https://core.telegram.org/bots/api#getupdates) 
endpoint. Use pydantic for data models.

It shall be running as a docker container with `restart unless stopped` policy and have 
the following environment variables:

`KB_SSH_USER` --- username on the host machine (machine the docker container is running on) to ssh on;
`KB_BOT_TOKEN` --- telegram bot token;
`KB_SECRET_PASSWORD` --- secret password;

it shall mount the `.kinder-bot.pigovsky.com` directory in the
`KB_SSH_USER` user's home directory on the host machine as a volume.

The bot shall handle a list of "admin" telegram user ids as a plain text file in the same 
`.kinder-bot.pigovsky.com` directory. 

"admin" users are those who have sent
the correct `KB_SECRET_PASSWORD` in a text message command in the following form:

```text
login {secret-password}
```

if @.kinder-bot.pigovsky.com/VERSION does not match those on the mounted 
`.kinder-bot.pigovsky.com` volume, then the bot shall copy all the files from 
@.kinder-bot.pigovsky.com to the mounted folder.

The bot shall generate an ssh key pair. The public ssh key shall be added to the
`~/.ssh/authorized_keys` for the `KB_SSH_USER` user's home directory on the host machine.

the bot shall run normal prompt commands, setting ~/.kinder-bot.pigovsky.com
as the current working directory, using ssh on the host machine.
The commands come as textual messages from the "admin" users. 
The stdout and stderr shall be redirected to the senders as response textual messages.

