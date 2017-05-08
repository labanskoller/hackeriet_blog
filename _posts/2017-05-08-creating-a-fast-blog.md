---
layout: post
title: "Creating a fast blog"
author: capitol
category: infrastructure
---
![dog](/images/fast-dog.jpg)

Let us go over the stack we use to power this blog and why it's both easy to use
and fast for our visitors.

The goal is to serve the blog as fast as possible, while avoiding the constant
stream of security holes that wordpress exposes it's users for.

We achieve this by only serving static content, that is updated every time that
someone pushes new content to the git repository that backs the blog.

We server this over http/2 and both IPv4 and Ipv6, in order to take advantage of
the improvements in the new protocols.

### Setup

#### Debian jessie

We use [debian](https://www.debian.org/) jessie as a base distribution,
they do a reasonable job of patching security issues and have almost all the
software we need packaged.

In regard to security, we think that the most likely attack is that someone
reuse a known exploit rather than burn a 0-day on us. So the most important
thing is to not have any unpatched software in our stack. In order to archive this
we have configured apt to automatically download and install security patches,
as described [here](https://wiki.debian.org/UnattendedUpgrades).

#### Nginx

We use [nginx](https://nginx.org/) as our web server of choice. It's fast and
quite flexible, it lacks a good module system but we don't need any esoteric features.

We installed nginx from the [jessie-backports](https://backports.debian.org/Instructions/)
repository, in order to get a version of nginx that supports http/2.

The configuration file for nginx looks like this:
 
```text
server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        server_name blog.hackeriet.no;

        ssl_certificate /etc/letsencrypt/live/hackeriet.no/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/hackeriet.no/privkey.pem;

        ssl_protocols TLSv1.2;
        ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
        ssl_dhparam /etc/ssl/certs/dhparam.pem;

        add_header Strict-Transport-Security "max-age=63072000; ";
        add_header X-Frame-Options "DENY";

        root /home/blog/blog-static/;

        location /images/ {
                expires 30d;
        }
}
```

We configure the server to listen to both IPv4 and IPv6, supporting IPv6 means
that mobile devices doesn't have to go through a carrier grade NAT (CGN) in order to
reach the site. CGN's can add significant amount of latency when the conditions are
bad.

The tls protocol is limited to only TLSv1.2 as all modern browsers have supported it
for a long time, the protocol was released in 2008. If there is someone out there 
that still can't use it, they need to seriously rethink how they manage their software.

The list of ciphers are chosen in order to avoid a number
of [cryptographic attacks](https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html).

The Strict-Transport-Security header tells the browser that it should only use
https in order to access the site in the future.

We also configure the caching of images to be 30 days, so that returning readers
of the blog will have a better experience.

#### Let's encrypt

The [Let's encrypt](https://letsencrypt.org/) project is our tls certificate
provider, they have enabled the world to move away from the insecure http protocol.

Let's encrypt lets us automate the signing of the certificate that tls uses. We
use [certbot](https://certbot.eff.org/) in standalone mode for this.

The openssl package needs to be installed from jessie backports also, since nginx was
installed from there.

### Jekyll

The engine that powers the blog is [jekyll](https://jekyllrb.com/), it takes our
blog posts that are written in markdown and compiles them into html pages.

The source of the blog lives [on github](https://github.com/hackeriet/blog) and each
blog post is it's own file under _posts/ prefixed with the date it will be published.

On the server we have a simple bash script that monitors github for new content
and regenerates the static files by running:

```bash
jekyll build --source /home/blog/blog --destination /home/blog/blog-static/
```

Jekyll is installed from source, since the version in debian is too old and there
isn't an updated version in backports.

