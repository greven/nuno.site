%{
title: "AI Fatigue in the Age of Agents",
tags: ~w(dev ai),
excerpt: "I use AI every day. I find it useful. Sometimes even impressive. And yet, I’m tired.",
category: :article,
status: :published,
featured: true
}

---

<!-- lead -->

I use AI every day. I find it useful. Sometimes even impressive. And yet, I’m tired.

I’m a developer. I use AI daily. At this point, pretending it doesn’t exist would be a fool’s errand.
I started using AI models around 2021 (I still dislike the term “Artificial Intelligence” for something artificial but not intelligent) when Github released Github Copilot to the public. Back then, it felt like magic not because it was especially good, but because it was new, exciting. The name Copilot felt perfectly appropriate as we were still flying the plane. The model was there to assist us, not the other way around.

Then the “agent era” arrived and things got muddier.

## The Rise of Agents

I’m not writing this post to take a stand against AI, nor is this an anti-AI manifesto. I use it daily.
Back then, before AI, as an already experienced developer, I rarely Googled basic things. StackOverflow, forums and Discord were for edge cases or unfamiliar territory. However, using Copilot paired with models like Anthropic’s Claude it has largely replaced the old “search-and-scan” workflow. LLM coding models are superior since:

- They understand context.
- They work with less than ideal text prompts.
- They’re faster than traditional search (time spent evaluating results).

The problem isn’t the use of AI assistance. The problem is _how it’s being sold_.

## The hidden costs of AI

We’ve moved from “copilot” to “agentic AI”, then to vague promises of AGI, curing cancer, solving climate change, delivering world peace. Meanwhile, AI is being used to justify mass layoffs, rising energy costs and accelerating the flood of low-quality, low-effort synthetic content.

We were promised freedom from repetitive tasks. Instead, many of us have become human quality filters for AI-generated slop. That’s the promotion nobody asked for!

We hear claims of “10x productivity” but how are we measuring productivity? The problem wasn’t writing code in the first place. If we measure productivity by the number of bricks laid but the building ultimately falls apart, are we truly being productive? The bottleneck in software development has never been typing speed. It’s thinking. Architecture. Tradeoffs. And most importantly, maintenance.

This isn’t to say agents aren’t useful. When used within mature codebases, with well-scoped tasks and by experienced developers who know what “good” looks like it can accelerate execution, but than only works because I already understand the problem and can evaluate the output. Trusting agentic output without any regard for quality, (or as the cool kids call it, _vibe coding_), will always hurt long-term maintainability and lead to lower quality software.

We either have human written software assisted by the machine or we risk accumulating technical debt at machine speed.

## It’s all crabs downhill from here

Some major tech companies, including Microsoft, claim that AI now writes a significant percentage of their new code. If this is true, it raises questions about whether the decline in their product quality could be correlated.

Take Windows 11. In 2026, even [Notepad has had critical security issues](https://www.techradar.com/pro/security/microsoft-patches-concerning-windows-11-notepad-security-flaw). How could this even be possible? Well, because ~~Microsoft~~ Microslop decided to add AI features to Notepad, at the request of no one. Yet, here we are.

<SiteWeb.BlogComponents.article_image image="https://imgs.xkcd.com/comics/machine_learning.png" alt="XKCD #1838" caption="Obligatory XKCD - #1838." width={371} heigh={439} rounded={false} centered />

And then there’s the rise of tools like [OpenClaw](https://openclaw.ai/). An AI chatbot assistant, think _Siri_ but it can actually do something. In a whirlwind of developments, it was rebranded multiple times in the span of days. It was initially named _Clawdbot_, but ironically, Anthropic deemed it too similar to their Claude product. And as we all know, AI companies are notoriously ethical about intellectual property! OpenClaw runs local agents with persistent sessions, integrating with models like ChatGPT and Claude.

It does sound powerful on paper. It can potentially fulfil the void left by the stagnated Google’s Assistant and the ever useless Apple’s Siri. In practice, it requires broad permissions across your accounts and services to be “useful”. Not that Google and Apple wouldn’t have access to your data anyway, but when considering security practices and code quality I still put my bet on Google or Apple over OpenClaw.

One could look at tools like OpenClaw as a massive productivity boost. Myself I lean on surveillance packaged as productivity. We all know the old saying: “the end doesn't justify the security clusterf\*ck”.

## The real tradeoff

AI didn’t emerge, it was unleashed. It went from research labs to global deployment almost overnight. It was released too soon (thanks OpenAI!), before we had clear legal frameworks in place. Before we had meaningful safeguards around intellectual property. Before we understood the economic and societal consequences of deploying systems at this scale.

Regulators are now scrambling to catch up. In Europe, legislation races against adoption curves. In the United States, it often feels like experimentation at planetary scale. AI investment is already the biggest endeavour of the human race to date (even surpassing the investments in The Manhattan Project and The Apollo program by several orders of magnitude). Yet, AI is being pushed from executives downward, searching for problems to justify its existence.

If “10x more efficiency” comes at the cost of privacy, trust and potential global economic collapse, maybe we should at least be honest about the tradeoff.

The cat is out of the bag. There’s no rewinding this, but we can still slow down and let society catch up.
