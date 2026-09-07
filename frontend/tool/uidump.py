#!/usr/bin/env python3
"""Parse a uiautomator dump and print labeled nodes with bounds.

Usage: python3 uidump.py [filter-substring]
Reads /tmp/ui.xml, prints 'text/desc | bounds | clickable' for every node
with a non-empty label. Optional argument filters by substring.
"""
import sys
import xml.etree.ElementTree as ET

raw = open('/tmp/ui.xml').read()
raw = raw[: raw.rindex('</hierarchy>') + len('</hierarchy>')]
root = ET.fromstring(raw)
needle = sys.argv[1].lower() if len(sys.argv) > 1 else None
for node in root.iter('node'):
    label = node.get('text') or node.get('content-desc')
    if not label or not label.strip():
        continue
    if needle and needle not in label.lower():
        continue
    print(repr(label), node.get('bounds'), 'clickable=' + node.get('clickable'))
