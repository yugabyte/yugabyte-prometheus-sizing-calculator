#### Prometheus Sizing Calculator for YugabyteDB Anywhere
##### Acess Web UI at : https://yugabyte.github.io/yugabyte-prometheus-sizing-calculator/
- Quickly estimate the memory, disk, and CPU requirements for your YugabyteDB Anywhere node running Prometheus, YB Platform and Postgres service.
- For more information, visit: [YugabyteDB Knowledge Base Article](https://support.yugabyte.com/hc/en-us/articles/38092646336909-How-to-Estimate-Prometheus-Resource-Requirements-for-YugabyteDB-Anywhere)

**NOTE**: This only estimates the prometheus instance size i.e how much resource needed for Prometheus service to operate. YBA combines 2 more service yb-platform and postgres which also needs resource. So always add 3GiB to 4GiB buffer on top of what you get from this calculator to run YBA smoothly.

### Metrics Calculation Logic

#### 1. Total Metrics

Metrics for each universe are calculated independently and then summed for the final total.

```
Universe Metrics = (60 × Tables + 9000) × Nodes
Total Metrics    = Σ(All Universe Metrics)
```

**Example:**
- Universe A: 50 tables, 3 nodes  
  Universe Metrics = (60 × 50 + 9000) × 3 = (3000 + 9000) × 3 = 12,000 × 3 = 36,000
- Universe B: 20 tables, 5 nodes  
  Universe Metrics = (60 × 20 + 9000) × 5 = (1200 + 9000) × 5 = 10,200 × 5 = 51,000

**Total Metrics** = 36,000 + 51,000 = **87,000**

---

#### 2. Memory (GB)

Memory per metric varies based on the total volume:

- **For totals ≤ 1,000,000 metrics** (30 KB/metric):

```
Memory (GB) = (Total Metrics × 30) / 1024 / 1024
```

- **For totals > 1,000,000 metrics** (10 KB/metric):

```
Memory (GB) = (Total Metrics × 10) / 1024 / 1024
```

**Example:**
Total Metrics = 87,000 (less than 1,000,000)  
Memory (GB) = (87,000 × 30) / 1024 / 1024  
Memory (GB) = 2,610,000 / 1,048,576 ≈ **2.49 GB**

---

#### 3. Disk (GB)

Disk usage is estimated at **253 KB per metric**:

```
Disk (GB) = (Total Metrics × 253) / 1024 / 1024
```

**Example:**
Disk (GB) = (87,000 × 253) / 1024 / 1024  
Disk (GB) = 22,011,000 / 1,048,576 ≈ **21.00 GB**

---

#### 4. CPU (Cores)

CPU usage is estimated at **1 core per 1,000,000 metrics**:

```
CPU Cores = Total Metrics / 1,000,000
```

**Example:**
CPU Cores = 87,000 / 1,000,000 = **0.087 cores** (~9% of a CPU core)

---

**Note:**  
These calculations are estimates based on a standard Prometheus configuration with:
- **10-second scrape interval**
- **15-day data retention period**

Actual resource usage may vary.