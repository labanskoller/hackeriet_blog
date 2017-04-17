---
layout: post
title: "Writeup for auto challenge at The Gathering"
author: capitol
category: ctf
---
![engineering](/images/engineering.jpg)

##### name:
Auto

##### category:
reverse

##### points:
200

#### Writeup

The auto challenge piped a base64 encoded binary at us, and then asked us to provide
the password from that binary.

Visual inspection showed us that something that looked like a password was stored in
plain text between the strings "Password:" and "You did it". 

When the correct password was returned within a second, the whole thing repeated.
After about 5 or 6 times the flag was returned.

I wrote a small java function to extract the string and send that back:
```java
    public void solve() throws Exception {
        String hostName = "auto.tghack.no";
        int portNumber = 2270;

        try (
                Socket echoSocket = new Socket(hostName, portNumber);
                PrintWriter out = new PrintWriter(echoSocket.getOutputStream(), true);
                BufferedReader in = new BufferedReader(new InputStreamReader(echoSocket.getInputStream()));
        ) {
            while(true) {
                String input = in.readLine();

                System.out.println("input = " + input);
                byte[] decoded = Base64.getDecoder().decode(input);

                String b = new String(decoded);

                String password = b.substring(b.indexOf("Password:") + 13, b.indexOf("You did it") - 1);

                String input2 = in.readLine();
                System.out.println("input1 = " + input2);

                out.write(password);
                out.flush();

                input2 = in.readLine();
                System.out.println("input2 = " + input2);
            }
        }
    }
```

The flag was TG17{bin4ries_3verywhere_wh4t_t0_d0}
