#### Prometheus Sizing Calculator for YugabyteDB Anywhere
 Acess Web UI at : https://yugabyte.github.io/yugabyte-prometheus-sizing-calculator/
- Quickly estimate the memory, disk, and CPU requirements for your YugabyteDB Anywhere node running Prometheus, YB Platform and Postgres service.
- For more information, visit: [YugabyteDB Knowledge Base Article](https://support.yugabyte.com/hc/en-us/articles/38092646336909-How-to-Estimate-Prometheus-Resource-Requirements-for-YugabyteDB-Anywhere)

**NOTE**: This only estimates the prometheus instance size i.e how much resource needed for Prometheus service to operate. YBA combines 2 more service yb-platform and postgres which also needs resource. So always add 3GiB to 4GiB buffer on top of what you get from this calculator to run YBA smoothly.

