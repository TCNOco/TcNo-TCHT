![TCHT Banner](https://tcno.co/tbag-banner-short.png)

# TC.HT Scripts (TroubleChute Scripts)

Everything hosted on [https://tc.ht](tc.ht). PowerShell scripts and more.

There are PowerShell scripts to be used with `iex (irm <script>.tc.ht)`, as well as bash and more coming in the future. Please, feel free to add to this and submit a Pull Request. I'd be happy to feature code and code improvements.

## How it works

All of these files are stored on my server. My server traverses the folder structure collecting a list of files and their paths. Someone asks for `tc.ht.ag`, my server looks for `test` in the list of files, and assuming it finds one, redirects to `tc.ht/test.txt`, for example, where the browser can then handle the download or PowerShell the code.

## Why tc.ht?

It's a super short, simple to remember short version of TroubleChute.

I have https://tcno.co, but adding a whole subdomain system of redirects would break a lot of what I have set up already... Not to mention having a 4-letter domain instead of a 6-letter domain is ever-so-slightly easier to type in powershell or a CLI.
