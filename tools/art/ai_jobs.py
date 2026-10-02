#!/usr/bin/env python3
"""Bookkeeping for AI art jobs.

  ai_jobs.py jobs <kind> id=job_id ...     record submitted jobs  (art_src/jobs_<kind>.json)
  ai_jobs.py urls <kind> <url> ...          record finished URLs; the job id inside each URL maps it to its id
  ai_jobs.py todo <kind>                    ids with a prompt but no submitted job
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "art_src")


def load(name):
    p = os.path.join(SRC, name)
    return json.load(open(p)) if os.path.exists(p) else {}


def save(name, d):
    json.dump(d, open(os.path.join(SRC, name), "w"), indent=1)


def batch(kind, n, quality):
    prompts = load(f"prompts_{kind}.json")
    jobs = load(f"jobs_{kind}.json")
    todo = [k for k in prompts if k not in jobs][:n]
    reqs = [{"index": i, "params": {"model": "gpt_image_2_5", "quality": quality, "background": "transparent",
             "aspect_ratio": "1:1" if kind == "enemies" else "2:3", "prompt": prompts[k]}} for i, k in enumerate(todo)]
    print(" ".join(todo))
    print(json.dumps(reqs, ensure_ascii=False))



def main():
    cmd, kind = sys.argv[1], sys.argv[2]
    jobs = load(f"jobs_{kind}.json")
    if cmd == "jobs":
        for a in sys.argv[3:]:
            k, v = a.split("=", 1)
            jobs[k] = v
        save(f"jobs_{kind}.json", jobs)
        print(len(jobs), "jobs")
    elif cmd == "urls":
        urls = load(f"urls_{kind}.json")
        by_job = {v: k for k, v in jobs.items()}
        new = []
        for u in sys.argv[3:]:
            jid = u.rsplit("_", 1)[-1].replace(".png", "")
            if jid in by_job:
                urls[by_job[jid]] = u
                new.append(by_job[jid])
            else:
                print("unknown job", jid)
        save(f"urls_{kind}.json", urls)
        print(" ".join(new))
    elif cmd == "batch":
        batch(kind, int(sys.argv[3]), sys.argv[4] if len(sys.argv) > 4 else "medium")
    elif cmd == "todo":
        prompts = load(f"prompts_{kind}.json")
        print(" ".join(k for k in prompts if k not in jobs))


if __name__ == "__main__":
    main()

