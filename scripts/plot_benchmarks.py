#!/usr/bin/env python3
"""Generate static plots from benchmark results."""

import json
import matplotlib.pyplot as plt
import sys

def main():
    try:
        with open('benchmark_results.json') as f:
            data = json.load(f)
    except FileNotFoundError:
        print("Error: benchmark_results.json not found. Run benchmarks first.")
        sys.exit(1)
    
    commands = [r['command'] for r in data['results']]
    times = [r['mean'] for r in data['results']]
    stdevs = [r['stddev'] for r in data['results']]
    labels = [' vs '.join(c.split()[-2:]) for c in commands]
    
    plt.figure(figsize=(12, 6))
    bars = plt.bar(range(len(commands)), times, yerr=stdevs, capsize=5)
    plt.xticks(range(len(commands)), labels, rotation=45, ha='right')
    plt.ylabel('Time (seconds)')
    plt.title('Smith-Waterman Benchmark Results')
    plt.grid(axis='y', alpha=0.3)
    
    for i, (time, std) in enumerate(zip(times, stdevs)):
        plt.text(i, time + std + max(times)*0.02, f'{time:.4f}s', ha='center', va='bottom')
    
    plt.tight_layout()
    plt.savefig('benchmark_plot.png', dpi=150, bbox_inches='tight')
    plt.savefig('benchmark_plot.pdf', bbox_inches='tight')
    print('Plots saved to benchmark_plot.png and benchmark_plot.pdf')

if __name__ == '__main__':
    main()