import re
import sys

def remove_ansi_codes(s):
    """Remove ANSI escape codes."""
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', s)

def simulate_backspace(s):
    """Simulate the effect of the backspace character."""
    output = []
    for char in s:
        if char == '\b':
            if output:
                output.pop()
        else:
            output.append(char)
    return ''.join(output)

if __name__ == "__main__":
    content = sys.stdin.read()
    cleaned = remove_ansi_codes(content)
    final_output = simulate_backspace(cleaned)
    sys.stdout.write(final_output)
