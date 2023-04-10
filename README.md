![TBAG Banner](https://tcno.co/tbag-banner-short.png)

# TB.AG Scripts (TroubleChute Scripts)

Everything hosted on tb.ag. PowerShell scripts and more.

There are PowerShell scripts to be used with `iex (irm <script>.tb.ag)`, as well as bash and more coming in the future. Please, feel free to add to this and submit a Pull Request. I'd be happy to feature code and code improvements.

## How it works

All of these files are stored on my server. My server traverses the folder structure collecting a list of files and their paths. Someone asks for `test.tb.ag`, my server looks for `test` in the list of files, and assuming it finds one, redirects to `tb.ag/test.txt`, for example, where the browser can then handle the download or PowerShell the code.

## Why tb.ag?

Why not?

Seriously. It's short, simple, memorable, and very mildly humorous.

Serious answer: I have https://tcno.co, but adding a whole subdomain system of redirects would break a lot of what I have set up already... Not to mention having a 4-letter domain instead of a 6-letter domain is ever-so-slightly easier to type in powershell or a CLI.

I was busy purchasing a TroubleChute related short URL after hours of searching, just to have it stolen and my payment refunded. I was heartbroken until I spent another hour or so digging into available short domains that weren't A. overly expensive and B. somewhat memorable. I could have bought 94.az or something, but having something memorable is better. https://tb.ag was available, so for the memes and need of having a shorter URL I went for it, even though it was slightly more expensive than the other options I had found.

So we're here.

I tried to do the best I could for a low-effort mostly ChatGPT generated front-end for the website, and it came out pretty well.

## What does tb.ag stand for?

```
T - I
B - Have yet
A - To come up with
G - An acronym
```
