---
layout: post
title: "Solution to nc3 Klikkety Klack"
author: capitol
category: ctf
---
![acab](/images/acab2.jpg)

##### name:
Klikkety Klack

##### category:
various

##### points:
n/a

#### Writeup

The danish police are running a CTF in order to show that they are cool with the kids [here](http://nc3ctffqqn5ozfjy.onion/).

We got a [pcapng]({% link /assets/2.pcapng %}) file that seems to contain 
communication between an usb keyboard of type HP Basic USB Keyboard KU-0316 Keyboard 
and a computer.

Some simple awk and python did the trick, first get byte number three from the usb capture data like this:

```bash
tshark -r /tmp/2.pcapng -T fields -e usb.capdata|awk -F':' '{print($3)}'|awk 'NF > 0' > data.txt
```

and then translate it to characters with this python program:

```python
mappings = {
        0x04:"A",
        0x05:"B",
        0x06:"C",
        0x07:"D",
        0x08:"E",
        0x09:"F",
        0x0A:"G",
        0x0B:"H",
        0x0C:"I",
        0x0D:"J",
        0x0E:"K",
        0x0F:"L",
        0x10:"M",
        0x11:"N",
        0x12:"O",
        0x13:"P",
        0x14:"Q",
        0x15:"R",
        0x16:"S",
        0x17:"T",
        0x18:"U",
        0x19:"V",
        0x1A:"W",
        0x1B:"X",
        0x1C:"Y",
        0x1D:"Z",
        0x1E:"1",
        0x1F:"2",
        0x20:"3",
        0x21:"4",
        0x22:"5",
        0x23:"6",
        0x24:"7",
        0x25:"8",
        0x26:"9",
        0x27:"0",
        0x28:"\n",
        0x2C:" ",
        0x2D:"-",
        0x2E:"=",
        0x2F:"[",
        0x30:"]"
        }
 
nums = []
keys = open('data.txt')
for line in keys:
        nums.append(int(line.strip(),16))
keys.close()
 
output = ""
for n in nums:
        if n in mappings:
                output += mappings[n]
        else:
                output += 'x'
 
print 'output :' + output
```

That gave us the output:

```bash
output: xJxxEEGx xHxAARR xLxIIGGEx xTTEESSTxEETx xMxIINx xTxOxAxSxTTEERxMxAxLLWWAxRREx 
xOxGx xIINNGGEENN xAxNxTxIxVxIIRxUUSx xDxExTTExCxTxEERRExDxEx xDDExNxx1xx xxFxxExDxTx 
xMxAxNxxx xxDxxExNx xHxAARx xSxHxAxxx2x556x 
x4x2xCx3xDx3xBxAx5xCx0x9x9x1x0x6xFxCx2x1xAxBx5x3x9x0x8x4x9x5xDx5xExFx2xFxFx9xFxCxAxAx8x9x0xBx1xCx7xExFx4x3x8x6xBxCx0x8x9x3xFx2xFxxxxxxxFx2xFx
```

Checking the hash 42C3D3BA5C099106FC21AB53908495D5EF2FF9FCAA890B1C7EF4386BC0893F2F on [virustotal.com](https://www.virustotal.com/#/file/42c3d3ba5c099106fc21ab53908495d5ef2ff9fcaa890b1c7ef4386bc0893f2f/detection)
we found this comment:
```
This evil malware that infected my toaster made a call to 45.63.119.180 on port 9999 and send the text "HELLO". I think that server is a C2-server.
```

Connecting to that ip/port gave us another [link](http://nc3ctffqqn5ozfjy.onion/2092c7a391323c18413e33f9840c47e6), 
where we could download a [binary]({% link /assets/g %})

running strings on that binary gave us something that looked like an url:
```bash
nc3ctffqH
qn5ozfjyH
.onion/
```

and the string: 23/09/90 kl. 01:12:12 UTC er det helt rigtige unix-tidspunkt til at skabe en URL

after decompiling the binary the important part was this:

```c
int __cdecl main(int argc, const char **argv, const char **envp)
{
  unsigned int v3; // eax@1
  int v4; // ST0C_4@1
  int result; // eax@1
  __int64 v6; // rsi@1
  __int64 v7; // [sp+10h] [bp-70h]@1
  __int64 v8; // [sp+18h] [bp-68h]@1
  __int64 v9; // [sp+20h] [bp-60h]@1
  char v10; // [sp+28h] [bp-58h]@1
  __int16 v11; // [sp+68h] [bp-18h]@1
  __int64 v12; // [sp+78h] [bp-8h]@1

  v12 = *MK_FP(__FS__, 40LL);
  v3 = time(0LL);
  srand(v3);
  v4 = rand();
  v7 = 8171331223976895342LL;
  v8 = 8748917902158425713LL;
  v9 = 13350748694671150LL;
  memset(&v10, 0, 0x40uLL);
  v11 = 0;
  puts("23/09/90 kl. 01:12:12 UTC er det helt rigtige unix-tidspunkt til at skabe en URL");
  printf("%s%d\n", &v7, (unsigned int)v4);
  result = 0;
  v6 = *MK_FP(__FS__, 40LL) ^ v12;
  return result;
}
```

We changed the init of srand to be the epoch of the date in the string, and got this [url](http://nc3ctffqqn5ozfjy.onion/1228468024/).

That gave us the flag:

DO_IT_FOR_THIS_ADORABLE_LITTLE_PUPPY_LOOK_AT_THE_PUPPY_MARGE 
