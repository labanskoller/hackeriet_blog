---
layout: post
title: "Using systemd services of Type=notify with Watchdog in C"
author: sshow
category: systemd
---
![systemd watchdog](/images/systemd-watchdog.png)

A systemd service of `Type=notify` waits for the executable program to send a
notification message to systemd before it is considered activated.
Up until the service is `active`, its state is `starting`.
`systemctl start <svc>` will block until the service is active, or failed.

Similarly, a service which has `WatchdogSec` set will expect to receive a notification
message no less than at every specified time interval. If no message has been received,
systemd will kill the process with `SIGABRT` and place the service in a `failed` state.

Here is an example of how a service can be configured to automatically be restarted if
it hangs.

```text
[Unit]
Description=Watchdog test service

[Service]
ExecStart=/home/sshow/watchdog-service-test
Type=notify
WatchdogSec=15
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

Our example process is written in C.

The manpage for `sd_watchdog_enabled` recommends that the daemon sends a notification
message every half of the time of `WatchdogSec`. The messages themselves are sent
using `sd_notify` with the contents `READY=1` when the process is done initialising,
and `WATCHDOG=1` for keep-alive notifications.

```c
#include <stdio.h>              // printf
#include <stdlib.h>             // getenv
#include <unistd.h>             // sleep
#include <time.h>               // usleep
#include <systemd/sd-daemon.h>  // sd_notify


int main()
{
    setbuf(stdout, NULL);

    // Detect if expected to notify watchdog
    uint64_t watchdogNotifyIntervalUsec = 0;
    int watchdogEnabled = sd_watchdog_enabled(0, &watchdogNotifyIntervalUsec);

    // man systemd.service recommends notifying every half time of max
    watchdogNotifyIntervalUsec = watchdogNotifyIntervalUsec / 2;
    printf("Watchdog status: %d\tWatchdog notify interval (divided by 2): %ld\n", \
        watchdogEnabled, watchdogNotifyIntervalUsec);

    // Just to illustrate that `systemctl start` blocks until notified
    printf("Waiting five seconds before notifying ready state...\n");
    sleep(5);

    // Notify systemd service that we're ready
    sd_notify(0, "READY=1");
    printf("called sd_notify READY\n");

    int i = 0;
    while (1) {
        printf("iteration <%d>\n", i);

        if (watchdogEnabled) {
            // Notify systemd this service is still alive and good
            sd_notify(0, "WATCHDOG=1");
            printf("called sd_notify WATCHDOG\n");
        }

        i++;

        usleep(watchdogNotifyIntervalUsec);
    }

    return 0;
}
```

#### Our specific usage

We have a vending machine in our space that is running a card reader daemon
for a NFC reader. The reader some times stops reading, or hangs unexpectedly.
Now we can send watchdog notification messages whenever the NFC poll function
runs, and if it doesn't, systemd will kill the process, restart the service
and (hopefully) help it start reading cards again.

#### References
- `man systemd.service`
- `man sd_notify`
- `man sd_enable_watchdog`
- https://stackoverflow.com/a/1157217/90674
- https://stackoverflow.com/a/35653394/90674
