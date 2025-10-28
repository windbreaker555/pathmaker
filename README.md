# PathMaker 🛠️

A bash utility that installs scripts and tools to your PATH for easy command-line access. Automatically detects script types (Python, Bash, executables), creates wrapper scripts, and configures your shell environment so you can run tools from anywhere without typing full paths.

## Installation

```bash
git clone https://github.com/yourusername/pathmaker.git
cd pathmaker
chmod +x pathmaker.sh
```

## Usage

**Install a tool:**
```bash
./pathmaker.sh /path/to/script.py commandname
```

**Install ShortEcho example:**
```bash
./pathmaker.sh ~/tools/shortecho.py shortecho
# Now run: shortecho https://example.com
```

**Install any Python script:**
```bash
./pathmaker.sh /home/user/scripts/myscan.py myscan
# Now run: myscan --help
```

**Install bash scripts:**
```bash
./pathmaker.sh /opt/tools/recon.sh recon
# Now run: recon target.com
```

**Options:**
```
<script-path>    Path to the script you want to install
<command-name>   Name of the command to create
-h, --help       Show help message
```

## How It Works

1. **Detects script type** - Automatically identifies Python, Bash, or executable files
2. **Creates wrapper** - Generates a wrapper script in `~/.local/bin/`
3. **Sets permissions** - Makes everything executable
4. **Configures PATH** - Optionally adds `~/.local/bin/` to your shell config
5. **Ready to use** - Command works globally after sourcing or restarting terminal

## Disclaimer

For personal use and authorized systems only. Ensure you have permission to modify system paths.
