---
layout: post
title: "Detect security problems compile time"
author: capitol
category: security
---
![bits](/images/java.jpg)

A large part of modern software engineering consists of standing on the shoulders of others
code, this makes us more productive and lets us focus on the solving our business problems
rather than reinventing wheels all the time.

But sometimes security problems are discovered in those libraries, if the project is well
maintained they request a CVE number, patch the flaw and release a new version. CVE numbers
are the canonical identifiers for security problems and they are issued by the 
[CVE Numbering Authority](https://cve.mitre.org/cve/cna.html).

It's obvious that we don't want to use libraries in our projects that have known security 
holes, but how can we automate this this?

[OWASP](https://www.owasp.org/index.php/Main_Page) have solved this problem for us, with 
their [Dependency Check](https://www.owasp.org/index.php/OWASP_Dependency_Check) project.
It can integrate as a step in your build chain and verify your external dependencies.

For java this is done with a maven plugin, you can easily add this to your pom.xml:

```xml
    <build>
        <plugins>
            <plugin>
                <groupId>org.owasp</groupId>
                <artifactId>dependency-check-maven</artifactId>
                <version>1.4.5</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>check</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
```

When I run ```mvn verify``` in one of my projects with the above configuration
it produces this output:

```text
One or more dependencies were identified with known vulnerabilities in ctlog:

httpclient-4.3.3.jar (cpe:/a:apache:httpclient:4.3.3, org.apache.httpcomponents:httpclient:4.3.3) : CVE-2015-5262, CVE-2014-3577
bcprov-jdk15on-1.49.jar (cpe:/a:bouncycastle:bouncy-castle-crypto-package:1.49, cpe:/a:bouncycastle:bouncy_castle_crypto_package:1.49, org.bouncycastle:bcprov-jdk15on:1.49) : CVE-2015-7940


See the dependency-check report for more details.
```

And this [report](({{ site.baseurl }}{% link /assets/dependency-check-report.html %})) is
produced.

It's also possible to configure it to fail the build on any vulnerability, or if a
severe enough problem is discovered.

My opinion is that this should be used in all projects, in order to quickly discover
security problems and give the developers the possibility to act on them. 