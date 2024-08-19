$ tgsend --help

tgsend v1.3.4
Message/file sender from Bot. Use Telegram Bot API

Usage: /usr/bin/tgsend [options]
option:
  -t --token         Bot token (*required)
  -i --chatId        Unique identifier for the target chat (*required)

  -m --message       Text of message (SendMessage method)
                OR
  -f --file          Path of sending file (SendDocument method)
  -F --foto          Send file as photo (SendPhoto method)
  -A --audio         Send file as audio (SendAudio method)
  -V --voice         Send file as voice (SendVoice method)
  -C --caption       Caption (for Photo/Document/Voice/Audio)


  -c --config        Configuration file path
                     search order:
                             ~/.tgsend/tgsend.conf
                             /etc/tgsend.conf
                             /usr/local/etc/tgsend.conf
                             /opt/tgsend/etc/tgsend.conf

  -d --debug         Debug on

  -p --proxy         Proxy IP
  -P --proxy-port    Proxy port (8080 default)

  -h --help          This help

Example:

Send 'hello world' text
tgsend -t '12345:AAABBBCCCDDDEEEEFFFF' --chatId='12345' -m 'hello world'

Send jpg file with debug
tgsend -t '12345:AAABBBCCCDDDEEEEFFFF' --chatId='12345' -f /tmp/lo.jpg -d

Send jpg file as photo with caption and debug
tgsend -t '12345:AAABBBCCCDDDEEEEFFFF' --chatId='12345' -F -f /tmp/lo.jpg -C "photo caption" -d

Send mp3 file as audio with caption and debug
tgsend -t '12345:AAABBBCCCDDDEEEEFFFF' --chatId='12345' -A -f /tmp/sample.mp3 -C "audio caption" -d

Send voice file (ogg format only) as voice with caption and debug
tgsend -t '12345:AAABBBCCCDDDEEEEFFFF' --chatId='12345' -V -f /tmp/sample.ogg -C "voice caption" -d

All question welcome to: Anton Shevtsov <shevtsov.anton[ at ]gmail.com>

