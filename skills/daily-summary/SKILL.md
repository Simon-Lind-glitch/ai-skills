---
name: daily-summary
description: "Write the daily stand-up update (Done, Blockers, MRs to review, Next) from the user's Jira tickets and forge activity."
argument-hint: "[since: yesterday|<n>d|<YYYY-MM-DD>] [--no-jira]"
disable-model-invocation: true
---

# Daily Summary

Write the user's stand-up update from what they did, not from what they remember.
Collect the activity, map it to tickets, and print one short block that the user pastes into the team chat.
Then give a housekeeping list: the stale MRs, the tickets whose status is wrong, and the branches to clean up.

The skill reads only, up to the housekeeping list. It changes Jira or the forge only when the user picks an action from that list.

## The output

Print exactly this shape in one fenced block, and nothing else in the block.
The user copies the block and pastes it into Slack.
Slack changes a Markdown link `[text](url)` into a link when the user pastes it.

```text
Done
• [PE-595](https://example.atlassian.net/browse/PE-595): crowdin DNS, cert and S3 copy done
• [PE-572](https://example.atlassian.net/browse/PE-572): staging mail verified, Zitadel SMTP bug fixed in fork, prod DNS [infra!57](https://gitlab.com/group/infrastructure/-/merge_requests/57) open
• crowdin-lang outage: restored the deleted GCP bucket ([PE-594](https://example.atlassian.net/browse/PE-594))
• Reviews: [infra!55](https://gitlab.com/group/infrastructure/-/merge_requests/55), [zitadel-fork!15](https://gitlab.com/group/zitadel-fork/-/merge_requests/15)

Blockers
• Prod mail switch waits on the SMTPeter date ([ADM-2782](https://example.atlassian.net/browse/ADM-2782))

MRs to review
• [account!317](https://gitlab.com/group/account/-/merge_requests/317) ([PE-512](https://example.atlassian.net/browse/PE-512)): CDC of account sessions, in production
• [teach!797](https://gitlab.com/group/teach/-/merge_requests/797) ([PE-512](https://example.atlassian.net/browse/PE-512)): license decides every lesson claim

Next
• GCP teardown follow ups
• [PE-596](https://example.atlassian.net/browse/PE-596): SSO account sync for invited Entra identities
```

Obey these rules for each line:

- Make each ticket key and each MR or PR reference a Markdown link `[text](url)`. Keep the key or the reference as the link text.
- Take the Jira URL from the site URL of the Atlassian resource, plus `/browse/<key>`. Take the MR or PR URL from its `web_url` or `url` field. Do not build a URL by hand.
- Put no other Markdown in the block: no bold, no headings, no `-` lists.
- Use `•` as the bullet. Chat tools keep it, and they change `-` or `*` into other things.
- Start a ticket line with the ticket key, then a colon, then the result.
- Write the result, not the activity. "prod DNS MR open" is a result. "worked on DNS" is not.
- Put one ticket on one line. Join the results of that ticket with commas.
- Keep a line to 15 words or fewer after the key. Leave out "I", articles where the meaning stays clear, and filler.
- Name an MR as `<project>!<iid>` and a PR as `<repo>#<number>`. `<project>` is the last segment of the project path. Shorten it only where the team already uses a short form, for example `infrastructure` to `infra`.
- Name an MR in a ticket line only when it is still open. A merged MR is the result, so write the result.
- Put all the reviews on one last `Reviews:` line of Done. Give at most 6 references, then `and <n> more`.
- Write "none" under Blockers when there is no blocker. Do not leave the section out.
- Leave out the MRs to review section when no MR waits for a review.
- In MRs to review, give the linked reference, the linked ticket key in parentheses, and a short title.
- Give at most 6 lines under Done, 3 under Blockers, 6 under MRs to review, and 4 under Next. Merge or drop the smallest items to stay in the limit.

## 1. Set the window

Parse `$ARGUMENTS`:

- No argument, or `yesterday`: the window starts at 00:00 of the previous working day. On a Monday, that is the Friday before.
- `<n>d`: the window starts at 00:00, `<n>` days before today.
- `<YYYY-MM-DD>`: the window starts at 00:00 of that date.
- `--no-jira`: skip Jira.

The window always ends now. Get today's date and weekday from the environment, not from memory.

## 2. Collect the activity

Run the collectors in parallel. If a source is not available, skip it and say so in one line under the block. Do not stop.

### Jira

Use the Atlassian MCP tools. The tool that lists the accessible resources gives the cloud id and the site URL. Keep both. Then search with JQL:

```text
(assignee = currentUser() OR reporter = currentUser()) AND updated >= "<window start>" ORDER BY updated DESC
```

Request only the fields `summary`, `status`, `assignee`, `updated`, and `issuelinks`.

Search a second time for the open tickets of the user, for the housekeeping list:

```text
assignee = currentUser() AND statusCategory != Done ORDER BY updated ASC
```

For each ticket, keep the key, the summary, the status, and whether the user is the assignee.

### GitLab

Use `glab`. Check `glab auth status` first. Get the user id:

```bash
glab api user | jq '.id'
```

Then get the events, the authored MRs, and the MRs where the user is a reviewer:

```bash
glab api "users/<id>/events?after=<day before window start>&per_page=100" --paginate
glab api "merge_requests?scope=all&author_id=<id>&updated_after=<window start ISO>&per_page=100"
glab api "merge_requests?scope=all&reviewer_id=<id>&updated_after=<window start ISO>&per_page=100"
glab api "merge_requests?scope=all&author_id=<id>&state=opened&per_page=100"
```

The last query gives all the open MRs of the user, for Next. Its `detailed_merge_status` tells whether an MR waits for approval, has a conflict, or needs a rebase.

The `after` filter of the events API excludes its own date. Thus give the day before the window start.

From the events, keep the MRs that the user opened, merged (`accepted`), approved, or commented on, and the branches the user pushed to.
A push to a branch with no MR is work in progress. Include it under the ticket that its branch name gives.

### GitHub

Use `gh` when it is installed and `gh auth status` succeeds:

```bash
gh search prs --author=@me --updated=">=<window start>" --json repository,number,title,state,url
gh search prs --author=@me --state=open --draft=false --review=required --json repository,number,title,url,updatedAt
gh search prs --reviewed-by=@me --updated=">=<window start>" --json repository,number,title,state,url
```

## 3. Map the activity to tickets

Find the ticket key of each MR or PR in this order. Use the first match.

1. A key in the title, for example `(PE-512)` or `fix(PE-543): …`.
2. A key in the source branch name, for example `PE-512/license-staff-write`.
3. A key in the description.

Ignore placeholder keys, for example `PE-000`. Treat them as no key.

Then:

- Group the MRs by ticket key.
- Group the MRs with no key by theme, for example "CDC pipeline" or "DAM S3 versions". Use the words of the MR titles. A theme becomes one line with a short label in place of the key.
- Find the ticket of a theme in the Jira results when the theme clearly matches a summary. Put that key at the end of the line in parentheses, the same way as `(PE-594)` above. Do not guess a key that the data does not show.
- Separate the reviews: an MR that another person wrote goes on the `Reviews:` line, never in a ticket line.

## 4. Sort into Done, Blockers, MRs to review, and Next

**Done** gets each ticket or theme that has one of these in the window: a merged MR, an approved review, or a move to Done.
It also gets each open MR that the user opened or pushed to in the window.
Write the state that the work has now: "merged", "in review", "deployed to staging". Take the state from the data, not from the title.

**Blockers** come only from the data. Do not invent a blocker. Candidates:

- A ticket or MR that names a dependency that is not done. Look for "waits on", "blocked by", and the Jira link type "is blocked by".
- A deploy order that the user saved in memory or in a project note, when the first step is not done.

If a candidate is not clearly a blocker, put it under Next, not under Blockers.

**MRs to review** gets each open MR of the user that waits for an approval from another person:

- On GitLab, `detailed_merge_status` is `not_approved`, or the MR is `mergeable` and its approvals endpoint shows `approvals_left` above 0.
- On GitHub, the PR is in the result of the `--review=required` query above.
- Leave out a draft, and an MR that did not change in the last 7 days.
- Leave out an MR with a conflict, a needed rebase, or open discussions. That MR waits for the user, not for a reviewer. Put it under Next.

An MR in this section does not also go under Blockers or Next. If one of these MRs blocks other work, say so in its line, for example "deploy before teach!797".

**Next** gets, in this order:

1. The open MRs of the user that still need work from the user, and that changed in the last 7 days.
2. The tickets of the user with the status In Progress that had no activity in the window.
3. The tickets of the user with the status To Do that were updated in the window.

An open MR that did not change in the last 7 days is stale. Do not put it under Next. It goes on the housekeeping list.

## 5. Find the housekeeping items

Find the items that the user can clean up. Use only the data from step 2. Give each item one suggested action.

| Item | Test | Suggested action |
| --- | --- | --- |
| Stale MR | Open, and no change in the last 7 days | Close, or rebase and ask for a review |
| Abandoned draft | Draft, and no change in the last 21 days | Close |
| MR with a conflict | `detailed_merge_status` is `conflict` or `need_rebase` | Rebase |
| Ticket behind its MRs | Status To Do, and an MR of the ticket is open or merged | Move to In Progress or In Review |
| Ticket that looks done | Status In Progress or In Review, all its MRs merged, none open | Move to Done |
| Done ticket with open MR | Status Done, and an MR of the ticket is still open | Merge or close the MR, or reopen the ticket |
| Old open ticket | Status To Do or In Progress, no update in the last 30 days, no MR | Move back to Backlog, or close |
| Work with no ticket | A theme from step 3 with no key | Make a ticket, or name one |

A merged MR is evidence for a ticket. It is not proof that the ticket is done. A ticket can need a deploy or a backfill after the merge. Thus write "looks done", never "is done".

## 6. Report

Print two parts, in this order.

**Part 1: the block.** Print the fenced block from "The output". Print it first, so that the user can copy it at once.
Do not ask a question before you print the block. The user edits the block. They do not answer a form.

**Part 2: housekeeping.** Under the block, print a numbered list with the heading `Housekeeping`. This list is for the user only. It is not part of the paste.

- Give one item on one line: the number, the linked reference, the reason in at most 10 words, and the suggested action.
- Sort the items by type, in the order of the table above. Put the oldest item of a type first.
- Give at most 15 items. Then give the number of the items that you left out.
- Write "nothing to clean up" when the list is empty.

Example:

```text
Housekeeping
1. specs!29: no change since 2026-09-23, conflict. Close?
2. charts!4: no change since 2026-07-08, conflict. Close?
3. PE-598: To Do, but teach!803 is merged. Move to In Review?
4. CDC pipeline: 14 MRs with no ticket. Make a ticket?
```

Do not put an item in the list that needs no action.

After the list, give at most 3 short lines:

- The sources that you skipped, and why.
- The items that you were not sure about, for example a guessed blocker.
- How to apply: "Reply with the numbers to apply, for example `close 1 2, move 3`."

## 7. Apply the picked actions

Do this step only when the user replies with numbers or names from the housekeeping list.

- Do only the actions that the user named. A number that the user did not name stays as it is.
- Before you close an MR, read its current state again. If it changed since step 2, tell the user, and do not close it.
- Close an MR with `glab mr close <iid> -R <project path>`, or a PR with `gh pr close <number> -R <repo>`. Do not delete its branch.
- Move a Jira ticket with the transition tools of the Atlassian MCP server. Get the transitions of the ticket first. If no transition goes to the status, tell the user.
- Do not merge, approve, or delete anything. Those actions are not on the list.
- After the actions, print one line for each action: the reference and the result.
