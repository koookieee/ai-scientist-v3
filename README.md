# AI Scientist v3

Autonomous AI research agent. No Python orchestration — the agent (Claude Code or Gemini CLI) plans experiments, writes code, debugs failures, generates plots, writes the paper, and iterates on reviewer feedback on its own.

## Setup

Requires Python 3.12+ and Docker (or an E2B account for sandboxed runs).

```bash
git clone <this-repo-url>
cd ai-scientist-v3-new

python3.12 -m venv .venv
source .venv/bin/activate
pip install -e .
```

Create a `.env` file (never commit this — it's gitignored):

```bash
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic   # or https://api.anthropic.com
ANTHROPIC_API_KEY=<your-key>
ANTHROPIC_AUTH_TOKEN=<your-key>
E2B_API_KEY=<your-key>            # only needed for --env e2b
GEMINI_API_KEY=<your-key>         # optional, for Gemini CLI agent
REVIEW_API_URL=<your-review-api-url>     # optional, self-hosted review API
SEARCH_PUBLIC_URL=<your-search-api-url>  # optional, for /search-papers skill
```

### `--ae` patch (required for `claude-code` agent + harbor)

`run.sh` must pass `ANTHROPIC_*`/`GEMINI_API_KEY` into the sandbox via harbor's `--ae` flag, or the agent gets no API key inside the container and hangs silently. Check `run.sh` for `HARBOR_ARGS+=(--ae ...)` near the `claude-code` agent branch — add it back if missing:

```bash
[[ -n "${ANTHROPIC_BASE_URL:-}" ]]   && HARBOR_ARGS+=(--ae "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL")
[[ -n "${ANTHROPIC_API_KEY:-}" ]]    && HARBOR_ARGS+=(--ae "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
[[ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]] && HARBOR_ARGS+=(--ae "ANTHROPIC_AUTH_TOKEN=$ANTHROPIC_AUTH_TOKEN")
[[ -n "${GEMINI_API_KEY:-}" ]]       && HARBOR_ARGS+=(--ae "GEMINI_API_KEY=$GEMINI_API_KEY")
[[ -n "${REVIEWER_MODE:-}" ]]        && HARBOR_ARGS+=(--ae "REVIEWER_MODE=$REVIEWER_MODE")
```

## Running a Research Idea

```bash
# List available ideas
ls ideas/

# Run one
./run.sh ideas/idea_tabulartransformer.json \
    --model deepseek-v4-pro \
    --timeout 7200 \
    --use-upstream-agent \
    --env docker --gpus 0

# In the background, logging to a file
nohup ./run.sh ideas/idea_tabulartransformer.json \
    --model deepseek-v4-pro --timeout 7200 --use-upstream-agent --env docker --gpus 0 \
    > ai_scientist_run.log 2>&1 &
tail -f ai_scientist_run.log
```

Swap `--env docker` for `--env e2b` to run in an isolated E2B sandbox (requires `E2B_API_KEY`), or `--env modal --gpus 1` for GPU runs on Modal. See the `run_*_with_reviews.sh` / `run_*_no_reviews.sh` scripts for more per-idea examples.

### Resuming a timed-out run

```bash
./run.sh ideas/idea_tabulartransformer.json --resume-from jobs/<job-id>/ --timeout 7200
```

### Sending feedback for the next iteration

```bash
./run.sh ideas/idea_tabulartransformer.json \
    --resume-from jobs/<job-id>/ \
    --feedback "The ablation study is missing a comparison without X. Add error bars to Figure 3."
```

## Monitoring a Run

```bash
ps aux | grep 'harbor run'                                # is it alive?
find jobs/ -name 'trial.log' -exec cat {} \;               # trial state
find jobs/ -path '*/setup/stdout.txt' -exec tail -3 {} \;  # agent setup done?
```

Or use the web viewer:

```bash
cd viewer && pip install -r requirements.txt
python3 app.py --source local
# → http://localhost:8000
```

## Required Pinned Versions

| Component | Version | Why |
|-----------|---------|-----|
| harbor | 0.1.45 | 0.7.x hangs in stream-json reader |
| e2b | 2.14.0 | Matches harbor 0.1.45 API |
| claude-agent-sdk | 0.1.44 | Matches harbor 0.1.45 |
| claude-code (in sandbox) | 2.1.145 | >= 2.1.158 hangs harbor |
| Python | 3.12+ | Required by harbor/e2b deps |

All pinned in `pyproject.toml`; `run.sh` pins the sandbox claude-code version via `--ak "version=2.1.145"`.

## Architecture

```
ai-scientist-v3-new/
├── ideas/                    # Research idea JSONs (input to run.sh)
├── .claude/
│   ├── CLAUDE.md            # Project context + conventions
│   ├── agents/               # reviewer.md, idea-reviewer.md, code-reviewer.md
│   └── skills/search-papers/ # Semantic Scholar / OpenReview / CrossRef search
├── harbor-task/
│   ├── instruction.md.template
│   ├── environment/          # Dockerfile.cpu / Dockerfile.gpu
│   └── tests/test.sh         # Verifier — checks artifacts, produces reward
├── scripts/
│   ├── submit_for_review.sh  # Self-review (subagent / ensemble / API)
│   └── compile_latex.sh
├── viewer/                    # Web dashboard for job results
└── run.sh                     # Entry point
```

## Common Failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| Harbor stuck, no output | Missing `--ae` flags | Apply the patch above |
| `FileNotFoundError: docker` | Forgot `--env docker`/`--env e2b` | Always pass `--env` |
| Setup fails, exit code 1 | Transient network blip in sandbox | Retry |
| "sandbox not found" mid-run | Something called `sb.kill()` | Never kill the sandbox manually, just disconnect |
