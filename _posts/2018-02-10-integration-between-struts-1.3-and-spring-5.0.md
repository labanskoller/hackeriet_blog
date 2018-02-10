---
layout: post
title: "Announcing the integration library between Struts 1.3 and spring 5.0"
author: capitol
category: infrastructure
---
![The swedish word for ostrich is struts](/images/ostrich.jpg)

# Ageing java enterprise developers, look here!

Are you still maintaining an aging enterprise beast that you don't have the
budget to rewrite to modern micro-services?

Have your company spent too much money into an codebase so that you can never
throw it away?

Do you still want to have experience with the latest and greatest toolset
so that you stay relevant on the job market and can get a higher salary 
when you switch jobs?

If the answers to the above questions are yes, look no further!

# Introducing the integration library between Struts 1.3 and Spring 5.0

Now you can use the latest spring release together with your old enterprise
application.

The code was resurrected from the spring 3 code base and ported forward 
to spring 5.

Add this dependency to your struts project

```xml
    <dependency>
        <groupId>no.hackeriet</groupId>
        <artifactId>struts1-spring5</artifactId>
        <version>1.0.0</version>
    </dependency>
```

and just replace `org.springframework.web.struts` with `no.hackeriet.struts1Spring.struts`.

Written because sometimes it's easier to write code than navigate politics.

By the way, don't forget to patch the security holes in struts 1 yourself!

Happy hacking!
