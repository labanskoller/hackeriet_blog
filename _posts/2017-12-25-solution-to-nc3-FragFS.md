---
layout: post
title: "Solution to nc3 FragFS"
author: capitol
category: ctf
---
![acab](/images/acab3.jpg)

##### name:
FragFS

##### category:
programing

##### points:
n/a

#### Writeup

The next problem in the danish police CTF was named named FragFS and we got a small [filesystem image]({% link /assets/three.dd %})
and a [manual]({% link /assets/three.md %})

Looking at the manual the filesystem consisted of four parts.
 
* First part was only a name, 512 bytes long.
* Second part was a lookup table that mapped path + filename to a md5sum. Table was located from byte 512 to 10935.
* Third part was another lookup table, from md5sum to a list of sectors where 
  the file content is located, each sector is 4096 bytes large. Table was located from byte 10940 to 23037.
* Fourth and last part is the actual file content, located from byte 81920 to the end of the image.

We wrote a small program to read the file content from the filesystem and write them out to disc.

```python
#!/usr/bin/python

import os

file = open("three.dd", "r")
r = file.read()

table = r[512:10935]

md5tofile = {}
for x in r[512:10935].split(chr(0) + chr(255) + chr(255)):
    k = x.split(chr(0))
    md5tofile[k[0]] = k[1]


for x in r[10940:23037].split(chr(0) + chr(255)):
    parts = x.split(chr(0))
    filename = md5tofile[parts[0]]
    pathn = filename[0:filename.rfind("/")]
    if not os.path.exists(pathn):
        os.makedirs(pathn)
    f = open(filename, "w")
    out = "";
    for y in parts[1].split(" "):
        out += r[(4096*int(y)):(4096*(int(y)+1))]
    f.write(out)
    f.close()
```

Running that gave us this filesystem content

```bash
└── filsystem
    ├── docs
    │   └── stack_smashing.pdf
    ├── gits
    │   ├── gef
    │   │   ├── binja_gef.py
    │   │   ├── docs
    │   │   │   ├── api.md
    │   │   │   ├── commands
    │   │   │   │   ├── aliases.md
    │   │   │   │   ├── aslr.md
    │   │   │   │   ├── assemble.md
    │   │   │   │   ├── canary.md
    │   │   │   │   ├── capstone-disassemble.md
    │   │   │   │   ├── checksec.md
    │   │   │   │   ├── config.md
    │   │   │   │   ├── context.md
    │   │   │   │   ├── dereference.md
    │   │   │   │   ├── edit-flags.md
    │   │   │   │   ├── elf-info.md
    │   │   │   │   ├── entry-break.md
    │   │   │   │   ├── eval.md
    │   │   │   │   ├── format-string-helper.md
    │   │   │   │   ├── gef-remote.md
    │   │   │   │   ├── heap-analysis-helper.md
    │   │   │   │   ├── heap.md
    │   │   │   │   ├── help.md
    │   │   │   │   ├── hexdump.md
    │   │   │   │   ├── hijack-fd.md
    │   │   │   │   ├── ida-interact.md
    │   │   │   │   ├── ksymaddr.md
    │   │   │   │   ├── memory.md
    │   │   │   │   ├── nop.md
    │   │   │   │   ├── patch.md
    │   │   │   │   ├── pattern.md
    │   │   │   │   ├── pcustom.md
    │   │   │   │   ├── process-search.md
    │   │   │   │   ├── process-status.md
    │   │   │   │   ├── registers.md
    │   │   │   │   ├── reset-cache.md
    │   │   │   │   ├── retdec.md
    │   │   │   │   ├── ropper.md
    │   │   │   │   ├── search-pattern.md
    │   │   │   │   ├── set-permission.md
    │   │   │   │   ├── shellcode.md
    │   │   │   │   ├── stub.md
    │   │   │   │   ├── theme.md
    │   │   │   │   ├── tmux-setup.md
    │   │   │   │   ├── trace-run.md
    │   │   │   │   ├── unicorn-emulate.md
    │   │   │   │   ├── vmmap.md
    │   │   │   │   ├── xfiles.md
    │   │   │   │   ├── xinfo.md
    │   │   │   │   └── xor-memory.md
    │   │   │   ├── commands.md
    │   │   │   ├── config.md
    │   │   │   ├── faq.md
    │   │   │   └── index.md
    │   │   ├── gef.py
    │   │   ├── gef.sh
    │   │   ├── ida_gef.py
    │   │   ├── LICENSE
    │   │   ├── mkdocs.yml
    │   │   ├── README.md
    │   │   └── tests
    │   │       ├── helpers.py
    │   │       ├── pylintrc
    │   │       └── test-runner.py
    │   └── iponmap
    │       ├── index.js
    │       ├── LICENSE
    │       ├── package.json
    │       ├── README.md
    │       └── screenshot.png
    ├── pics
    │   ├── 20h-2012-s.png
    │   ├── 20h.png
    │   ├── dwm-20070930s.png
    │   ├── dwm-20080717s.png
    │   ├── dwm-20090620s.png
    │   ├── dwm-20090709s.png
    │   ├── dwm-20100318s.png
    │   ├── dwm-20101101s.png
    │   ├── dwm-20110720s.png
    │   ├── dwm-20120806.png
    │   ├── frign-2016-s.png
    │   ├── hendry-s.png
    │   ├── poster36.jpg
    │   └── putain-ouais-s.png
    └── src
        ├── dwm-6.1.tar.gz
        └── st-0.7.tar.gz
```

Looking through the images in the pics catalog, we found the flag in the file dwm-20120806.png.

flag was: B@KE_H|M-AWAY_TOYS