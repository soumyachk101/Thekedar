# 🚀 Thekedar (ठेकेदार) — Official Launch LinkedIn Post

Copy and paste the exact post text below directly into LinkedIn:

---

Most AI coding tools fail not because the LLMs are dumb... but because we treat a single chat window like a silver bullet.

After 30 minutes of chatting:
❌ Context window swells & memory degrades  
❌ The agent starts hallucinating non-existent file paths  
❌ It edits files outside the task scope & breaks working code  
❌ You spend more time debugging what the AI wrote than writing code yourself  

I got tired of prompt-based "promises" that fail under context pressure. 

So I built **Thekedar (ठेकेदार)** — an enterprise-grade AI Workflow & Crew Site Supervisor for Claude Code & AI Coding Agents.

🎉 **Now officially live on the Claude Code Plugin Marketplace!**

Think of it as a real-world site supervisor (ठेकेदार): He doesn't lay every brick himself — he decomposes goals, assigns specialist workers, mechanically enforces safety rules, inspects the work, and logs every single edit.

---

### 🏗️ How Thekedar (ठेकेदार) fixes AI code drift:

1️⃣ **15 Purpose-Built Specialist Subagents**  
Instead of one agent wearing every hat, tasks are routed to isolated specialists — `planner` (नक्शा-वाला), `backend-dev` (मिस्त्री), `frontend-dev` (रंग-मिस्त्री), `error-checker`, `security-auditor` (चौकीदार), and more.

2️⃣ **Mechanical PreToolUse Scope Protection (`Exit 2`)**  
Rule #1: *Never rely on LLM prompts if bash can enforce it.* `scope-guard.sh` intercepts every file write. If an agent tries to edit a file outside its declared scope, bash throws Exit Code 2 and halts the write before disk mutation.

3️⃣ **PreToolUse Secret Interceptor**  
`secret-guard.sh` regex-scans edit payloads in real-time. Zero hardcoded AWS keys, PEMs, or API tokens ever touch your git history.

4️⃣ **Zero-Token Change Ledger (`munshi.sh`)**  
Every edit is logged in structured markdown disk ledgers without consuming model context tokens.

5️⃣ **Enforced Read-Only Reviewers**  
`error-checker` and `security-auditor` have file mutation permissions physically stripped. They inspect diffs hostile-reviewer style but physically cannot corrupt your source code.

---

### 📦 Quick Install via Claude Marketplace:

```bash
claude plugin marketplace add soumyachk101/Thekedar
claude plugin install thekedar@thekedar
```

**Kaam Pakka, Hisaab Saaf.** 👷‍♂️

Thekedar is 100% open-source!

🌐 **Live Interactive Demo & Docs**: https://soumyachk101.github.io/Thekedar/  
⭐ **GitHub Repository**: https://github.com/soumyachk101/Thekedar  

How are you currently managing scope drift in your AI coding workflows? Would love to hear your thoughts in the comments! 👇

#AI #SoftwareEngineering #ClaudeCode #DevTools #OpenSource #ArtificialIntelligence #Coding #TechInnovation
