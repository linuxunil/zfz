#!/usr/bin/env python3
"""Display benchmark results as ASCII bar chart."""

import json
import sys

def main():
    try:
        with open('benchmark_results.json') as f:
            data = json.load(f)
    except FileNotFoundError:
        print("Error: benchmark_results.json not found. Run benchmarks first.")
        sys.exit(1)
    
    print('\n=== Smith-Waterman Benchmark Results ===')
    max_time = max(r['mean'] for r in data['results'])
    
    for r in data['results']:
        name = ' vs '.join(r['command'].split()[-2:])
        time = r['mean']
        stddev = r['stddev']
        bar_length = int((time / max_time) * 40)
        bar = '█' * bar_length
        print(f'{name:25} │{bar:<40}│ {time:.4f}s ±{stddev:.4f}s')
    print()

if __name__ == '__main__':
    main()