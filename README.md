# Python Pool Tester

![ScreenShot Python tester](screenshot.png)

### Quick Start

#### Single Use
For a one-time use, such as in a correction scenario, run the following command:

```bash
bash -c "$(curl -Ls http://tinyurl.com/FtPythonPoolTester)" _ [options]

options:
	--allow-cache | -c		: Cache the tester file and dependency to run test faster
	--day[n] | [n]			: launch a specifi day with [n] the day number
```

#### Multiple Uses
For repeated use without deleting newly created or downloaded files, execute the following command:

```bash
bash -c "$(curl -Ls http://tinyurl.com/FtPythonPoolTester)" _ --allow-cache
```

#### Cleanup
To remove all files associated with the tester, simply run the program again:

```bash
bash -c "$(curl -Ls http://tinyurl.com/FtPythonPoolTester)"
```

Alternatively, you can manually delete the files with the following command:

```bash
rm -rf PYscine_tester ./conftest.py
```

### Security Notice

**Important:** Always verify the source of scripts obtained from URL shorteners. For transparency, here is the final destination of the script URL: [Direct Script URL](http://preview.tinyurl.com/FtPythonPoolTester)

### Getting Involved

We welcome contributions! Feel free to propose new tests or enhancements to existing ones. Your input is valuable in improving the Python Pool Tester.
