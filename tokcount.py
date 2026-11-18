"""Approximate PICO-8 token count (manual rules: brackets pairs=1, strings=1,
commas/periods/colons/semicolons/local/end/comments free; unary minus on numbers free)."""
import re, sys
src = open(sys.argv[1]).read()
src = re.sub(r'--\[\[.*?\]\]', '', src, flags=re.S)
src = re.sub(r'--[^\n]*', '', src)
tok = re.compile(r'''("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\[\[.*?\]\]|0x[0-9a-fA-F.]+|0b[01.]+|\d+\.?\d*|\.\d+|[A-Za-z_][A-Za-z0-9_]*|\.\.\.|\.\.=?|[=~!<>]=|[-+*/%^\\&|]=|>>>?|<<|\^\^|[-+*/%^#<>=(){}\[\],;:.\\@$&|~])''', re.S)
n = 0
for m in tok.finditer(src):
    t = m.group(0)
    if t in (',', '.', ':', ';', ')', ']', '}', 'local', 'end'):
        continue
    n += 1
print(n)
