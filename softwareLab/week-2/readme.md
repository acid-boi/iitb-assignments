# Bash Networking and Automation Scripts

## [Open it here for a proper formatting and readability!](https://github.com/acid-boi/iitb-assignments/tree/main/softwareLab/week-2)

## 1. Port Scanner

### Overview

This script is a basic port scanner that:

- Pings a given host to check if it is reachable.
- Scans a range of ports on the host by attempting to open TCP connections.
- Supports scanning a single IP or all IPs in a subnet using CIDR notation.

Such scripts are useful in environments where tools like `nmap` are not available, and where the user does not have `sudo` privileges to install them. Instead of manually testing each port or server, this script automates the process using only Bash built-in capabilities and simple utilities like `prips`.

---

### Dependencies

- **prips** (for generating IP addresses in a subnet).

  - Install with:

    ```bash
    sudo apt install prips
    ```

---

### Usage

```bash
./scanner <target IP> <lowerbound port> <higherbound port> <CIDR indicator>
```

- `<target IP>` → The host IP or subnet (in CIDR form).
- `<lowerbound port>` → The starting port number for scanning.
- `<higherbound port>` → The ending port number for scanning.
- `<CIDR indicator>` → `0` for single IP, `1` for subnet.

#### Example 1: Scanning a single host

```bash
./scanner 192.168.1.10 20 100 0
```

#### Example 2: Scanning an entire subnet

```bash
./scanner 192.168.1.0/24 20 100 1
```

---

### Working of the Script

1. **Input Validation**

   ```bash
   if [ $# -lt 4 ]; then
       echo "Usage ./scanner <target IP> <lowerbound port> <higherbound port> <CIDR indicator(1 if subnet, 0 for ip)>"
       exit
   fi
   ```

   The script first ensures that exactly four arguments are provided. If not, it exits with a usage message.

2. **Ping Check**

   ```bash
   ping -c 1 $1 >/dev/null 2>&1
   status=$?
   if [ $status -ne 0 ]; then
       echo "The host is not reachable! Please provide another host"
   fi
   ```

   Before scanning ports, the script checks if the host responds to a ping request. This ensures that scanning is only attempted if the host appears reachable.

3. **Port Scanning Logic**

   ```bash
   for i in $(seq $(($2 - 1)) $3); do
       timeout 1 bash -c "echo hello > /dev/tcp/$ip/$i " >/dev/null 2>&1
       statusCode=$?
       if [ $statusCode -eq 0 ]; then
           echo "Port $i is open for the host $ip"
       fi
   done
   ```

   - The script iterates over the given port range.
   - For each port, it uses the special file `/dev/tcp/host/port` provided by Bash to attempt a TCP connection.
   - A short timeout (`1 second`) is applied to avoid delays.
   - If the connection succeeds (`statusCode=0`), the port is reported as open.

4. **Subnet Expansion (if applicable)**

   ```bash
   if [ $cidr -eq 0 ]; then
       ips+=("$ip")
   else
       ips=($(prips $ip))
   fi
   ```

   - If the user specifies `cidr=1`, the script uses `prips` to generate all IP addresses in the given subnet.
   - Each IP is then scanned individually.
   - If `cidr=0`, only the single given IP is scanned.

---

### Sample Output

```
Trying to enumerate the ip 192.168.1.10

Port 22 is open for the host 192.168.1.10
Port 80 is open for the host 192.168.1.10
```

---

## 2. Weather Notification via Telegram Bot

### Overview

This script integrates with **WeatherAPI** to fetch weather forecasts and uses the **Telegram Bot API** to send weather updates as messages. The purpose is to receive daily weather alerts, such as rainfall warnings, before leaving for class.

The script is intended to be scheduled as a **cron job**, ensuring that notifications are received automatically every morning without manual execution.

---

### Dependencies

- **curl** (for making HTTP requests).
- **jq** (for parsing JSON responses).
- A registered account and API key from [WeatherAPI](https://www.weatherapi.com/).
- A Telegram bot created via [BotFather](https://core.telegram.org/bots#botfather) with its API token.

---

### Usage

1. Export your API keys in your `~/.bashrc` file:

   ```bash
   export weatherAPI="<your-weatherapi-key>"
   export botAPI="<your-telegram-bot-token>"
   ```

   Reload the file with:

   ```bash
   source ~/.bashrc
   ```

2. Run the script:

   ```bash
   ./weather.sh
   ```

3. Example cron job entry (daily at 7:30 AM):

   ```bash
   30 7 * * * /path/to/weather.sh
   ```

---

### Working of the Script

1. **API Request and Response Handling**

   ```bash
   status=$(curl -s -w "%{http_code}" "https://api.weatherapi.com/v1/forecast.json?key=$weatherAPI&q=Mumbai&days=1&aqi=no&alerts=yes" -o $filename)
   ```

   - The script makes a request to WeatherAPI and stores the output in a temporary JSON file.
   - It also captures the HTTP status code to verify if the request was successful.

2. **Extracting Data with jq**

   ```bash
   max_temp=$(cat $filename | jq .forecast.forecastday[0].day.maxtemp_c)
   min_temp=$(cat $filename | jq .forecast.forecastday[0].day.mintemp_c)
   avghumidity=$(cat $filename | jq .forecast.forecastday[0].day.avghumidity)
   dailywillitrain=$(cat $filename | jq .forecast.forecastday[0].day.daily_will_it_rain)
   dailychanceofrain=$(cat $filename | jq .forecast.forecastday[0].day.daily_chance_of_rain)
   conditionText=$(cat $filename | jq .forecast.forecastday[0].day.condition.text)
   ```

   - The script extracts useful weather details such as temperature, humidity, rainfall chances, and forecast conditions using `jq`.

3. **Message Crafting**

   ```bash
   if [ $dailywillitrain -eq 1 ]; then
       message="RAINFALL ALERT!"
   fi
   message+=$'
   ```

Maximum Temperature: '"\$max_temp"
message+=\$'
Minimum Temperature: '"\$min_temp"
message+=\$'
Average Humidity: '"\$avghumidity"
message+=\$'
Can it Rain: '"\$dailywillitrain"
message+=\$'
Chances of Rain: '"\$dailychanceofrain"
message+=\$'
Forecast: '"\$conditionText"

````
- A formatted message is created containing all weather details.
- A rainfall alert is added if rain is predicted.

4. **Telegram Notification**
```bash
curl -s -X POST "https://api.telegram.org/bot$botAPI/sendMessage" \
    --data-urlencode "text=$message" \
    -d chat_id="$chatId" >/dev/null 2>&1
````

- The crafted message is sent to the specified Telegram chat ID.
- This provides a real-time weather notification directly in the Telegram app.

5. **Cleanup**

   ```bash
   rm $filename
   ```

   - The temporary JSON file is deleted after the data is processed.

---

### Demonstration

A working demonstration of this script has been recorded and is available in the repository as a GIF:
Please note that since providing the API keys wasn't viable, I have provided a working demo video, if
needed, i can present it during the viva.

![Weather Bot Demo](output.gif)

---

## Script 3: Traceroute-like Utility

### Overview

This script is a simplified implementation of the classic `traceroute` command. It determines the path packets take to reach a given destination by gradually increasing the **Time-To-Live (TTL)** value of ICMP packets sent using the `ping` utility. Each hop on the network path is revealed until the destination host is reached or the maximum hop count is exceeded.

This is useful in environments where the `traceroute` command may not be available or installed, yet you still want to analyze the path taken to reach a network destination.

### Key Features

- Accepts a target IP address or hostname as input.
- Iteratively increases the TTL value to discover intermediate hops.
- Stops execution once the destination is reached or the maximum number of hops (default 20) is exceeded.
- Provides a human-readable output of each hop along the way.

### Usage

```bash
./traceroute.sh <target-ip or name>
```

Example:

```bash
./traceroute.sh google.com
```

### Important Sections of the Code

#### Argument Check

```bash
if [ $# -lt 1 ]; then
    echo "Usage ./traceroute.sh <target>"
    exit 1
fi
```

This ensures that the user provides at least one argument (the target hostname or IP). If not, the script exits with usage instructions.

#### Iterative Hop Discovery

```bash
for ttl in $(seq 1 $max_hops); do
    output=$(timeout 1 ping -c 1 -t $ttl $ip 2>&1)
    exitCode=$?
```

Here, the script loops from TTL = 1 up to a maximum value (`max_hops=20`). For each iteration, it sends a single ping with the corresponding TTL value. The `timeout` ensures that the script does not hang waiting for a response.

#### Handling Responses

```bash
if [ $exitCode -eq 0 ]; then
    hop=$(echo "$output" | grep -i "bytes from" | awk '{print $4}' | sed 's/$://')
    ...
else
    hop=$(echo "$output" | grep -i "From" | awk '{print $2}')
```

- If the destination is reached (`exitCode == 0`), the script extracts the responding IP/hostname and reports the hop number as the destination.
- Otherwise, it captures the intermediate router’s address and displays it as part of the route.

### Sample Output

```
1: 192.168.1.1
2: 10.0.0.1
3: 203.0.113.5
4: google.com   (destination)
Reached destination in 4 hops.
```

---

## Password Manager Script

This script provides a **password management system** using a simple text file as the storage backend. It enables saving, listing, and retrieving passwords for different services, with options to copy them securely to the clipboard or export them as environment variables.

---

### Features

- **Add Passwords**: Securely store a password tied to a service name.
- **List Services**: See all available services stored in the password file.
- **Retrieve Passwords**: For a chosen service, you can:

  1. Copy the password to clipboard.
  2. Print it directly to the terminal.
  3. Export it as an environment variable in your `~/.bashrc` file.

---

### Prerequisites

- **File Storage Location**: The script stores passwords in `/var/secure_passwords.txt`. The file requires **sudo privileges** for writing and reading.
- **Clipboard Tools**:

  - `xclip`

- **Permissions**: Since this involves sensitive data, only privileged users should have access to the password file.

---

### Usage

```bash
# Add a new password
./password_manager.sh add

# List services and retrieve a password
./password_manager.sh list
```

---

### Code Breakdown

#### Adding a Password

```bash
echo "$service:$password" | sudo tee -a "$PASSFILE" >/dev/null
```

The service and password are appended to the secure file in the format:

```
service:password
```

#### Listing Passwords

```bash
services=$(sudo cut -d ":" -f1 "$PASSFILE")
```

This extracts the list of service names (the first field before `:`) to display to the user.

#### Selecting and Acting on a Service

The user chooses a service and can then:

- **Copy** the password to the clipboard if a supported tool is available.
- **Print** the password to the terminal.
- **Export** it as an environment variable:

```bash
echo export "$service""_PASSWORD"="$password" >>~/.bashrc
```

This appends an export statement to `~/.bashrc`, making the password accessible via `$SERVICENAME_PASSWORD` after sourcing.

---

Use strict file permissions to ensure only the script owner can access the password file:

```bash
sudo chmod 600 /var/secure_passwords.txt
sudo chown <your-username> /var/secure_passwords.txt
```
