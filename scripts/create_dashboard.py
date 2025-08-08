#!/usr/bin/env python3
"""Create interactive HTML dashboard from benchmark results."""

import json
import plotly.graph_objects as go
import sys

def main():
    try:
        with open('benchmark_results.json') as f:
            data = json.load(f)
    except FileNotFoundError:
        print("Error: benchmark_results.json not found. Run benchmarks first.")
        sys.exit(1)
    
    # Create main benchmark chart
    fig = go.Figure()
    commands = [r['command'] for r in data['results']]
    labels = [' vs '.join(c.split()[-2:]) for c in commands]
    times = [r['mean'] for r in data['results']]
    stdevs = [r['stddev'] for r in data['results']]
    
    fig.add_trace(go.Bar(
        x=labels,
        y=times,
        error_y=dict(array=stdevs, visible=True),
        name='Mean Time',
        text=[f'{t:.4f}s' for t in times],
        textposition='outside'
    ))
    
    fig.update_layout(
        title='Smith-Waterman Algorithm Benchmark Results',
        xaxis_title='Sequence Comparison',
        yaxis_title='Time (seconds)',
        showlegend=False,
        height=600,
        template='plotly_white'
    )
    
    fig.write_html('benchmark_dashboard.html')
    print('Interactive dashboard saved to benchmark_dashboard.html')
    print('Open with: open benchmark_dashboard.html (macOS) or xdg-open benchmark_dashboard.html (Linux)')

if __name__ == '__main__':
    main()