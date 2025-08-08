#!/usr/bin/env python3
"""Plot benchmark performance trends over time."""

import json
import glob
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime
import os
import sys

def main():
    history_files = sorted(glob.glob('benchmark_history/*.json'))
    if not history_files:
        print('No history files found. Run: mise run bbt')
        sys.exit(1)
    
    timestamps = []
    results_by_command = {}
    
    for file in history_files:
        timestamp_str = os.path.basename(file).replace('.json', '')
        try:
            timestamp = datetime.strptime(timestamp_str, '%Y%m%d_%H%M%S')
            timestamps.append(timestamp)
            
            with open(file) as f:
                data = json.load(f)
                for r in data['results']:
                    cmd_key = ' vs '.join(r['command'].split()[-2:])
                    if cmd_key not in results_by_command:
                        results_by_command[cmd_key] = []
                    results_by_command[cmd_key].append(r['mean'])
        except ValueError:
            continue
    
    if not timestamps:
        print('No valid history files found')
        sys.exit(1)
    
    plt.figure(figsize=(14, 8))
    for cmd, times in results_by_command.items():
        plt.plot(timestamps[:len(times)], times, marker='o', label=cmd, linewidth=2)
    
    plt.xlabel('Time')
    plt.ylabel('Execution Time (seconds)')
    plt.title('Smith-Waterman Benchmark Performance Over Time')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig('benchmark_history_plot.png', dpi=150, bbox_inches='tight')
    print('Historical plot saved to benchmark_history_plot.png')

if __name__ == '__main__':
    main()