# מדריך התקנה — הרצת אייג'נטים של Claude Code מהטלפון

מדריך מלא מאפס לסטאפ ש-**eli** מקים בשבילכם: שרת בענן שמריץ צי של אייג'נטים של Claude Code, נגיש מכל מקום דרך Tailscale, ונשלט מטלפון אנדרואיד דרך Termux. בלי בוט, בלי דמון מותאם — רק SSH ו-Claude Code.

> **כל הזרימה בשורה אחת:**
> טלפון (Termux) → `ssh mac` → `cd` לתוך פרויקט → `claude` → בוחרים את האייג'נט הרלוונטי → ממשיכים לעבוד.

כל כתובות ה-IP, שמות המשתמש וה-hostnames למטה הם placeholders כמו `<SERVER_IP>`, `<USER>`, `<TAILNET_IP>`. תחליפו בשלכם.

---

## 0. מה בונים

שלושה מכשירים, tailnet אחד:

| מכשיר | תפקיד |
|---|---|
| **שרת בענן** (Hetzner) | מריץ את האייג'נטים 24/7. סוס העבודה האמיתי. |
| **Mac** (אופציונלי) | תיבה always-on שנייה / מכונת פיתוח, גם היא על ה-tailnet. |
| **טלפון אנדרואיד** (Termux) | השלט רחוק שלכם. מתחברים ב-SSH מכל מקום. |

הכל מחובר יחד ע״י **Tailscale** (VPN פרטי בלי הגדרות), כך שכל מכונה מגיעה לכל מכונה אחרת דרך IP פרטי יציב — בלי port-forwarding, בלי לחשוף SSH לאינטרנט הציבורי.

---

## 1. הקמת השרת (Hetzner Cloud)

1. פותחים חשבון ב-[Hetzner Cloud](https://www.hetzner.com/cloud) → פרויקט חדש → **Add Server**.
2. תיבה מומלצת: **CX43** — 4 vCPU, 16GB RAM, 160GB SSD, בערך $14 לחודש. מריץ בנוחות 3+ אייג'נטים במקביל. (CX קטן יותר מספיק ל-1–2 אייג'נטים; יותר RAM = יותר אייג'נטים במקביל.)
3. **Image:** Ubuntu 24.04 LTS.
4. **SSH key:** הדביקו כאן עכשיו את המפתח הציבורי של הטלפון *וגם* של ה-Mac (ראו שלב 2) כדי להתחבר בלי סיסמה. אפשר גם להוסיף מפתחות מאוחר יותר.
5. צרו. שמרו את ה-**public IPv4** — זה ה-`<SERVER_IP>` שלכם.

> Hetzner דורשת אימות זהות לפני שאפשר ליצור שרתים — העלו דרכון או תעודת זהות בדף האימות שלהם. לוקח כמה שעות. תעשו את זה קודם.

התחברות ראשונה והקשחה:
```bash
ssh root@<SERVER_IP>

# צרו משתמש לא-root שתעבדו איתו בפועל
adduser <USER>
usermod -aG sudo <USER>

# (אופציונלי אך מומלץ) כבו התחברות עם סיסמה אחרי שהמפתחות עובדים
# ב-/etc/ssh/sshd_config הגדירו:  PasswordAuthentication no
sudo systemctl restart ssh
```

---

## 2. מפתחות SSH (טלפון + Mac → שרת)

הכלל: **המפתח הפרטי אף פעם לא עוזב את המכשיר; מעתיקים את המפתח *הציבורי* לשרת.**

**בטלפון (Termux):**
```bash
pkg install openssh          # פעם ראשונה בלבד
ssh-keygen -t ed25519        # קבלו את ברירות המחדל; הוסיפו passphrase אם תרצו
cat ~/.ssh/id_ed25519.pub    # העתיקו את השורה הזו
```

**ב-Mac:**
```bash
ssh-keygen -t ed25519        # אם עוד אין לכם
cat ~/.ssh/id_ed25519.pub    # העתיקו גם את זה
```

**בשרת**, הוסיפו את שני המפתחות הציבוריים:
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys   # הדביקו כל pubkey בשורה נפרדת
chmod 600 ~/.ssh/authorized_keys
```

אם ה-Mac והשרת צריכים גם להתחבר זה לזה ב-SSH, חזרו על אותו דבר: צרו מפתח ב-Mac, הוסיפו את ה-pubkey שלו לשרת (ולהיפך). זה בדיוק שלב "pubkey על ה-Mac + על שרת ה-Hetzner".

---

## 3. Tailscale (להגיע לשרת מכל מקום)

כתובות IP ציבוריות משתנות וחושפות אתכם; Tailscale נותן לכל מכונה IP פרטי יציב על ה-tailnet שלכם.

**בשרת:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# פתחו את ה-URL שמודפס, התחברו → השרת מצטרף ל-tailnet שלכם
tailscale ip -4    # שמרו את זה -> <TAILNET_IP> של השרת
```

**ב-Mac:** התקינו את אפליקציית Tailscale (או `brew install tailscale`), התחברו עם אותו חשבון.

**בטלפון:** התקינו **Tailscale** מ-Play Store, התחברו עם אותו חשבון, הפעילו **on**.

עכשיו כל מכשיר מגיע לשרת ב-`<TAILNET_IP>` בלי קשר לרשת. הערות מהניסיון:
- ה-tailnet IP נפתר רק כש-Tailscale **up** בשני הצדדים. אם זה מקרטע, שמרו את ה-`<SERVER_IP>` הציבורי כגיבוי.
- אם אתם רוצים להגיע לתיבה לפי שם, הפעילו **MagicDNS** בקונסולת הניהול של Tailscale.

---

## 4. קיצור "mac" ב-Termux (הארגונומיה בצד הטלפון)

הטריק שמזרז הכל: host מוגדר בשם, כך שתקלידו `ssh mac` במקום פקודה מלאה.

ב-Termux, ערכו את `~/.ssh/config`:
```
Host mac
    HostName <TAILNET_IP>        # או <SERVER_IP> כגיבוי
    User <USER>
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60       # שומר על הסשן מלהתנתק ברשת סלולרית
    ServerAliveCountMax 3
```

עכשיו מהטלפון: `ssh mac` → אתם בשרת. (תקראו לזה איך שתרצו — "mac", "server", "fleet".)

שיפורי חיים אופציונליים ב-Termux:
- `pkg install openssh mosh` — **mosh** שורד שינויי רשת / קליטה חלשה הרבה יותר טוב מ-SSH רגיל לשימוש נייד.
- Termux widgets מאפשרים לשים כפתור `ssh mac` בלחיצה אחת על מסך הבית.

---

## 5. התקנת Claude Code בשרת

```bash
# Node (Claude Code מגיע כחבילת npm)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# uv (מנהל חבילות Python מהיר — שימושי לפרויקטי אייג'נטים)
curl -LsSf https://astral.sh/uv/install.sh | sh

claude          # ההרצה הראשונה מדריכה אתכם בהתחברות/אימות
```
מאמתים פעם אחת וזה נשמר בשרת. מאותו רגע כל סשן SSH יכול פשוט להריץ `claude`.

---

## 6. איך האייג'נטים באמת עובדים

זה החלק שחשוב. "אייג'נט" כאן הוא לא שרת מיוחד; הוא **תיקיית פרויקט + הגדרת תפקיד**. יש שני סגנונות שאני משתמש בהם.

### סגנון A — Subagent כקובץ markdown
בתוך פרויקט שמים קבצי תפקיד ב-`.claude/agents/*.md`. כל אחד הוא קובץ markdown עם YAML frontmatter; הגוף הוא מדריך ההפעלה המלא של האייג'נט (פרסונה, פקודות מדויקות, כללים). דוגמה (`.claude/agents/qa.md`):
```markdown
---
name: qa
description: MANDATORY browser-based QA verifier. Use BEFORE any claim that a UI feature works.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are the QA verifier. Open the real page in Chrome, screenshot it,
read the console, and report only observed facts — never "should work".
...מדריך הפעלה מלא...
```
Claude Code מציג אותו בבורר האייג'נטים, והסשן הראשי מפעיל אותו לפי דרישה. מצוין לתפקידים on-demand (בודק QA, reviewer).

### סגנון B — אייג'נט קבוע בצי (job + skill + prompt)
לעובדים always-on, כל אייג'נט הוא **Claude Code background job** ארוך-טווח, ש:
- **הזהות** שלו מגיעה מ-`state.json` משלו (הוא קורא את זה ראשון בכל סשן כדי ללמוד את שמו),
- **ההתנהגות** שלו מגיעה מ-**skill** באותו שם ב-`.claude/skills/<agent-name>/` (מדריך ההפעלה שלו, כולל מרווח ה-`/loop`, למשל `/loop 15m`),
- **המשימה** שלו מגיעה משורת prompt קנונית בקובץ שליטה משותף (למשל `agent_prompts.txt`).

בהפעלה כל אייג'נט: קורא את `state.json` → מחפש את משימתו → טוען *רק את ה-skill שלו* → מוודא שה-`/loop` שלו רץ → ואז פועל **רק בתחום שלו**, עם prefix של `[agent-name]` לכל commit ומסלים כל דבר מחוץ לתחום במקום לתקן אותו.

### מבנה הפרויקט שמחבר הכל
פרויקט אמיתי מבוסס-אייג'נטים (הפרויקט `investor` שלי) נראה כך:
```
project/
├── CLAUDE.md                     # "החוקה": כללים מחייבים לכל אייג'נט
├── .claude/
│   ├── agents/*.md               # subagents מסגנון A (למשל qa.md)
│   ├── skills/<agent>/           # מדריכי הפעלה מסגנון B, אחד לכל אייג'נט בצי
│   ├── settings.json             # allowlist הרשאות + denylist ל-force-push
│   └── worktrees/                # כל אייג'נט עובד ב-git worktree מבודד
├── docs/ops/                     # runbooks, fleet-constitution.md, לוגים של תקריות
└── <domain code>/                # הדבר עצמו שהאייג'נטים מפעילים
```
משמעת מפתח ששומרת על צי שפוי:
- **`CLAUDE.md` מחייב**, לא דקורטיבי — זה חוזה ההפעלה עבור האדם *וגם* כל אייג'נט.
- **הפרדת תפקידים:** אייג'נט מתאם אף פעם לא מתקן לוגיקת domain; כשל domain = prompt/skill/loop לא-מספיק-טוב, מתוקן *שם*.
- **מקור אמת יחיד:** מניפסט / קובץ prompt אחד; משימות נקראות מילה במילה, לעולם לא מועתקות.
- **worktrees מבודדים:** אייג'נטים עורכים ב-`git worktree` משלהם כדי לא להתנגש.
- **הרשאות כמעקות בטיחות:** `settings.json` מאשר פקודות בטוחות ואוסר כל וריאציה של force-push.

---

## 7. יום בחיים

```bash
# מהטלפון, מכל מקום
ssh mac

# קופצים לפרויקט שרוצים לעבוד עליו
cd ~/investor

# מפעילים Claude Code — הוא טוען את CLAUDE.md + האייג'נטים הזמינים אוטומטית
claude

# ואז, בתוך הסשן:
#   - בוחרים את האייג'נט הרלוונטי מהבורר, או
#   - נותנים לסשן הראשי להאציל ל-subagents, או
#   - בודקים את ה-jobs הקבועים בצי ומכוונים אותם
```
זהו. האייג'נטים ממשיכים לרוץ בשרת בין אם הטלפון מחובר ובין אם לא; SSH הוא רק החלון שדרכו מסתכלים. מנתקים את הטלפון, העבודה ממשיכה; מתחברים מאוחר יותר, ממשיכים מאיפה שעצרתם.

---

## צ'ק-ליסט סיכום

- [ ] Hetzner CX43, Ubuntu 24.04, משתמש sudo לא-root
- [ ] זוג מפתחות ed25519 בטלפון (Termux) **וגם** ב-Mac; שני ה-pubkeys ב-`~/.ssh/authorized_keys` של השרת
- [ ] Tailscale מותקן + מחובר בשרת, ב-Mac ובטלפון (אותו חשבון)
- [ ] קיצור `Host mac` ב-`~/.ssh/config` ב-Termux (tailnet IP, keepalive)
- [ ] Node + Claude Code CLI + uv מותקנים בשרת; `claude` אומת פעם אחת
- [ ] לכל פרויקט: `CLAUDE.md`, `.claude/agents/*.md`, ו/או `.claude/skills/<agent>/` שמגדירים כל אייג'נט
- [ ] `ssh mac` → `cd project` → `claude` → עובדים
