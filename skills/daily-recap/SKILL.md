---
name: daily-recap
description: "Write the private morning recap of the user: the reviews and questions that wait for them, and where they stopped work."
argument-hint: "[since: yesterday|<n>d|<YYYY-MM-DD>] [--no-jira] [--no-slack]"
disable-model-invocation: true
---

# Daily Recap

Tell the user what other people wait for from them, and where they stopped work.
The recap is for the user only. It is not a stand-up update. For the stand-up block, the user runs `daily-summary`.

The skill reads only. It changes the forge only when the user picks an action from the clean-up list in step 6.

## The output

Print exactly this shape, as Markdown in the terminal. Do not put it in a fenced block.

```markdown
**Reviews (3)**
1. [infrastructure!61](https://gitlab.com/group/infrastructure/-/merge_requests/61) mahdishahbazi: lifecycle rules on the private bucket. 3d
2. [teach!712](https://gitlab.com/group/teach/-/merge_requests/712) henols: show a review answer only when accepted. 31d
3. [account!251](https://gitlab.com/group/account/-/merge_requests/251) mikaelkaron: approval removed after new commits. 1d

**Waiting on you (3)**
1. [account!310](https://gitlab.com/group/account/-/merge_requests/310) mikaelkaron asks: "Is this ready for production?" 6d
2. [teach!788](https://gitlab.com/group/teach/-/merge_requests/788) your MR: conflict with main. 4d
3. [PE-543](https://example.atlassian.net/browse/PE-543) Henrik asks for the runbook date. 2d

**Where you stopped**
• [PE-512](https://example.atlassian.net/browse/PE-512): staff write keys merged, account!318 deploy is next
• [PE-499](https://example.atlassian.net/browse/PE-499): branch PE-499/flow-ignore pushed, no MR yet
• teach worktree `PE-540/strict-dual-write`: 2 commits not pushed
```

Obey these rules:

- Make each MR, PR, and ticket reference a Markdown link `[text](url)`. Take the URL from the `web_url`, `target_url`, or `url` field of the data. Take a Jira URL from the site URL of the Atlassian resource, plus `/browse/<key>`. Do not build a URL by hand.
- Name an MR as `<project>!<iid>` and a PR as `<repo>#<number>`. `<project>` is the last segment of the project path.
- In Reviews and Waiting on you, end each line with the age. The age is the number of days that the item waited for the user. Give `<1d` for less than one day.
- Sort Reviews and Waiting on you by age. Put the oldest item first.
- In each line, give the person who waits, then what they wait for, in 12 words or fewer.
- Quote a question in at most 10 words. Cut it with `…` when it is longer.
- Give the number of items in the heading of each section.
- Give at most 10 lines under Reviews, 10 under Waiting on you, and 5 under Where you stopped. After the limit, give `and <n> more`.
- Write "nothing" under a section that has no items. Do not leave the section out.

## 1. Set the window

Parse `$ARGUMENTS`:

- No argument, or `yesterday`: the window starts at 00:00 of the previous working day. On a Monday, that is the Friday before.
- `<n>d`: the window starts at 00:00, `<n>` days before today.
- `<YYYY-MM-DD>`: the window starts at 00:00 of that date.
- `--no-jira`: skip Jira.
- `--no-slack`: skip Slack.

The window always ends now. Get today's date and weekday from the environment, not from memory.

The window applies only to Where you stopped and to new questions.
A review or an MR that waits for the user stays in the recap until the user acts on it. This is also true when it is older than the window.

## 2. Collect the data

Run the collectors in parallel. If a source is not available, skip it and say so in one line under the recap. Do not stop.

### GitLab

Use `glab`. Check `glab auth status` first. Get the user id and the username:

```bash
glab api user | jq '{id, username}'
```

Then get these lists:

```bash
# The MRs where the user is a reviewer
glab api "merge_requests?scope=all&reviewer_id=<id>&state=opened&per_page=100" --paginate
# The pending to-do items: review requests, mentions, questions, MRs that cannot merge
glab api "todos?state=pending&per_page=100" --paginate
# The open MRs of the user
glab api "merge_requests?scope=all&author_id=<id>&state=opened&per_page=100" --paginate
# The events of the user, for Where you stopped
glab api "users/<id>/events?after=<day before window start>&per_page=100" --paginate
```

The `after` filter of the events API excludes its own date. Thus give the day before the window start.

For each MR where the user is a reviewer, get the review state of the user:

```bash
glab api "projects/<project_id>/merge_requests/<iid>/reviewers"
```

Keep the `state` of the entry whose `user.username` is the user. The values are `unreviewed`, `reviewed`, `requested_changes`, `approved`, and `unapproved`.

### GitHub

Use `gh` when `gh auth status` succeeds:

```bash
gh search prs --review-requested=@me --state=open --json repository,number,title,url,author,updatedAt
gh search prs --author=@me --state=open --json repository,number,title,url,updatedAt
gh api notifications --jq '.[] | select(.reason == "mention" or .reason == "review_requested" or .reason == "assign")'
```

### Jira

Skip Jira when the arguments include `--no-jira`. Use the Atlassian MCP tools. The tool that lists the accessible resources gives the cloud id and the site URL. Keep both. Get the account id of the user from the user-info tool.

Search with JQL:

```text
(assignee = currentUser() OR reporter = currentUser() OR watcher = currentUser()) AND statusCategory != Done AND updated >= "<window start>" ORDER BY updated DESC
```

Request only the fields `summary`, `status`, `assignee`, `updated`, and `comment`.
Of the comments, read only the last 3 of each ticket.

### Slack

Skip Slack when the arguments include `--no-slack`, or when no Slack MCP tool is available. Do not ask the user to connect Slack. In the line of skipped sources, say that Slack was not available.

When a Slack MCP tool is available, search the window for the messages that mention the user. Also search for the direct messages to the user.
Keep a message only when it asks the user a question or for an action. Drop it when a later message of the user in that thread or DM answers it.

### Local work

Run these in the current repository, and in each git worktree of it:

```bash
git worktree list --porcelain
git for-each-ref --sort=-committerdate --count=10 --format='%(refname:short) %(committerdate:iso8601) %(upstream:track)' refs/heads
git status --short
```

If the current directory is not a git repository, skip the local work and say so.

Read the project memory of the user when the harness loads it, for example `MEMORY.md`. A memory that names a deploy order or a next step of a ticket is data for Where you stopped.

## 3. Sort the reviews

Put an MR or PR under **Reviews** when all of these are true:

- The user is a reviewer, or a pending to-do item has the action `review_requested`.
- It is not a draft.
- The review state of the user is `unreviewed` or `unapproved`. `unapproved` means that the user approved before and new commits removed the approval.
- On GitHub, the PR is in the result of the `--review-requested=@me` query.

Do not put these under Reviews. They wait for the author, not for the user:

- The review state of the user is `approved`, `reviewed`, or `requested_changes`. When the author asks for a new review, GitLab sets the state back to `unreviewed`.
- `detailed_merge_status` is `conflict` or `need_rebase`.

The age of a review is the time since the `created_at` of its `review_requested` to-do item. When it has no to-do item, use the `updated_at` of the MR.

## 4. Sort the items that wait on the user

Put an item under **Waiting on you** when it is one of these:

| Item | Test | Line |
| --- | --- | --- |
| Direct question | A pending to-do item with the action `directly_addressed`, on a target that is still open | The person and the question |
| Mention | A pending to-do item with the action `mentioned`, on a target that is still open, that asks the user something | The person and the question |
| Your MR cannot merge | A pending to-do item with the action `unmergeable`, or an open MR of the user with `detailed_merge_status` `conflict` or `need_rebase` | "your MR: conflict with `main`" (the target branch) |
| Your MR with open threads | An open MR of the user with `detailed_merge_status` `discussions_not_resolved`, and the last note of an open thread is from another person | The person and what they ask |
| Your MR has a failed pipeline | A pending to-do item with the action `build_failed` | "your MR: pipeline failed" |
| Assigned to you | A pending to-do item with the action `assigned` or `approval_required` | The person who assigned it |
| Jira question | One of the last 3 comments of a ticket mentions the account id of the user, and no later comment of the user follows it | The person and the question |
| Slack question | A Slack message from step 2 | The person and the question, with a link to the message |

Before you keep a direct question or a mention, read the notes of its target:

```bash
glab api "projects/<project_id>/merge_requests/<iid>/notes?sort=desc&per_page=20"
```

If the user wrote a note after the `created_at` of the to-do item, the user already answered. Do not put the item in the recap. Put it on the clean-up list as a stale to-do item.

A mention in a bulk change, for example a dependency bump to many repositories with the same title, is not a question. Join the bulk mentions into one line: "mikaelkaron: nh-oclif 18 in 6 repos, FYI". Put that line last in the section.

The age of an item is the time since the `created_at` of its to-do item, its note, its comment, or its message.

## 5. Find where the user stopped

Use the events of the window, the open MRs of the user, and the local work. Give one line for each ticket or theme. Take the ticket key from the MR title, then the branch name, then the MR description. Ignore placeholder keys, for example `PE-000`.

Put these items in the section, in this order:

1. The last thing the user did in the window: the most recent push, merge, or MR. Name the result, not the activity.
2. The next step that a memory note gives for a ticket from item 1, for example a deploy order whose first step is now done.
3. A branch that the user pushed to in the window, with no MR.
4. A local branch or worktree with commits that are not pushed, or with changes that are not committed. Give the number of commits, from `%(upstream:track)`.

Do not repeat an item from Reviews or Waiting on you.

## 6. Report

Print the recap from "The output" first. Do not ask a question before it.

Under the recap, print a numbered list with the heading **Clean up** when one of these items exists:

- A stale to-do item: the user already answered, or its target is now merged or closed.
- A review on a draft that the user is a reviewer of, with no change in the last 21 days.

Give one item on one line: the number, the linked reference, the reason in at most 10 words, and the action "Mark done?". Give at most 10 items. Then give the number that you left out.

After the list, give at most 3 short lines:

- The sources that you skipped, and why.
- The items that you were not sure about, for example a mention that is maybe not a question.
- How to apply: "Reply with the numbers to mark done, for example `done 1 2`."

## 7. Apply the picked actions

Do this step only when the user replies with numbers from the Clean up list.

- Do only the actions that the user named.
- Mark a GitLab to-do item done with `glab api -X POST "todos/<todo id>/mark_as_done"`.
- Mark a GitHub notification done with `gh api -X PATCH "notifications/threads/<thread id>"`.
- Do not approve, merge, close, or comment on anything.
- After the actions, print one line for each action: the reference and the result.
