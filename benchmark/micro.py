import numpy as np
import glob
import os
import matplotlib
matplotlib.use('Agg') 
import matplotlib.pyplot as plt
from datetime import datetime

def generate_sorted_report(path):
    dt = np.dtype([('sync', np.uint64), ('work', np.uint64)])
    files = glob.glob(os.path.join(path, "*.bin"))
    
    if not files: return

    proc_data = {}
    for f in files:
        data = np.fromfile(f, dtype=dt)
        if data.size == 0: continue
        # Extract name: bench_NAME_addr.bin -> NAME
        name = os.path.basename(f).split('_')[1]
        if name not in proc_data:
            proc_data[name] = {'sync': [], 'work': []}
        proc_data[name]['sync'].append(np.mean(data['sync']))
        proc_data[name]['work'].append(np.mean(data['work']))

    # Calculate means and overhead percentages
    summary = []
    for n in proc_data.keys():
        s_avg = np.mean(proc_data[n]['sync'])
        w_avg = np.mean(proc_data[n]['work'])
        overhead_pct = (s_avg / (s_avg + w_avg)) * 100
        summary.append({'name': n, 'sync': s_avg, 'work': w_avg, 'pct': overhead_pct})

    # Sort: Most overhead (highest pct) to least
    summary.sort(key=lambda x: x['pct'], reverse=True)

    names = [s['name'] for s in summary]
    sync_vals = [s['sync'] for s in summary]
    work_vals = [s['work'] for s in summary]

    # Dynamic sizing for readability
    plt.figure(figsize=(14, len(names) * 0.4 + 3))
    
    plt.barh(names, sync_vals, color='#e74c3c', label='Sync Overhead')
    plt.barh(names, work_vals, left=sync_vals, color='#2ecc71', label='DSP Work')
    
    plt.title(f"Sorted Pipeline Overhead - {datetime.now().strftime('%Y-%m-%d %H:%M')}", fontsize=14)
    plt.xlabel("Clock Cycles")
    plt.gca().invert_yaxis() # Keep highest overhead at the top
    plt.legend(loc='upper right')
    plt.grid(axis='x', linestyle='--', alpha=0.6)
    plt.tight_layout()
    
    # Save with timestamp
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"bench_summary_{ts}.png"
    plt.savefig(filename)
    
    # Single line summary
    total_s = sum(sync_vals)
    total_w = sum(work_vals)
    total_overhead = (total_s / (total_s + total_w)) * 100
    print(f"Overall Pipeline Overhead: {total_overhead:.2f}% (Saved to {filename})")

if __name__ == "__main__":
    generate_sorted_report("/home/device/dev/falcon-core/build/debug/bench/")
