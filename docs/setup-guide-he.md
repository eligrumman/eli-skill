# התקנת CCBot — שלב אחרי שלב

CCBot מחבר את Claude Code לטלגרם. אתה ממשיך לעבוד מהטלפון בזמן שהטרמינל רץ על המחשב.

## מה צריך לפני שמתחילים

- מנוי **Claude Max** (בשביל גישה לאופוס)
- חשבון **Telegram**
- **Python 3.10+** ו-**uv** מותקנים ([התקנת uv](https://docs.astral.sh/uv/getting-started/installation/))
- **tmux** מותקן (`brew install tmux` ב-macOS / `apt install tmux` ב-Linux)

---

## התקנה חצי-אוטומטית

העתיקו את הפקודה הזו לקלוד קוד:

```
install ccbot
```

קלוד יציע לכם 2 גלולות:
- 🔴 **אדומה** — אוטומט מלא. הוא עושה הכל, אתם רק מתחברים לטלגרם.
- 🔵 **כחולה** — שלב-שלב. הוא מסביר, אתם מבצעים.

---

## התקנה ידנית — 10 שלבים

### שלב 1: Clone הריפו

```bash
git clone https://github.com/six-ddc/ccbot.git ~/ccbot
cd ~/ccbot
```

### שלב 2: התקנת חבילות

```bash
uv sync
```

### שלב 3: יצירת בוט בטלגרם

1. פתחו את Telegram, חפשו `@BotFather`
2. שלחו `/newbot`
3. בחרו שם תצוגה (למשל "Claude Bot")
4. בחרו username (חייב להסתיים ב-`bot`, למשל `my_claude_ccbot`)
5. **שמרו את הטוקן** שקיבלתם — תצטרכו אותו בשלב 5

### שלב 4: קבלת ה-Telegram ID שלכם

1. פתחו את Telegram, חפשו `@userinfobot`
2. שלחו `/start`
3. **שמרו את המספר** שקיבלתם (למשל `123456789`)

### שלב 5: הגדרת קובץ .env

```bash
cp .env.example .env
```

ערכו את `.env` והחליפו:
```
TELEGRAM_BOT_TOKEN=<הטוקן משלב 3>
ALLOWED_USERS=<ה-ID משלב 4>
```

שאר ההגדרות אופציונליות:

| משתנה | ברירת מחדל | תיאור |
|---|---|---|
| `TMUX_SESSION_NAME` | `ccbot` | שם סשן ה-tmux |
| `CLAUDE_COMMAND` | `claude` | פקודה להרצת Claude Code |
| `MONITOR_POLL_INTERVAL` | `2.0` | תדירות סריקה (שניות) |

### שלב 6: התקנת Hook

```bash
uv run ccbot hook --install
```

זה מוסיף hook ל-`~/.claude/settings.json` שמאפשר ל-CCBot לעקוב אחרי סשנים אוטומטית.

### שלב 7: יצירת גרופ בטלגרם עם Topics

1. Telegram → **New Group**
2. תנו שם (למשל "Claude Code" או "CCBot")
3. הפכו ל-**Supergroup**: הגדרות גרופ → ערוך → הפעילו הגדרת אדמין כלשהי (זה מפעיל שדרוג אוטומטי)
4. הפעילו **Topics**: הגדרות גרופ → Topics → Enable
5. הוסיפו את הבוט שלכם לגרופ ותנו לו **הרשאות אדמין**

> **למה Topics?** כל טופיק = פרויקט נפרד = סשן נפרד של Claude Code. ככה אפשר לנהל כמה פרויקטים במקביל מאותו גרופ.

### שלב 8: הפעלת Threaded Mode ב-BotFather

1. פתחו את הפרופיל של **@BotFather** בטלגרם
2. לחצו על **Open App** (כפתור המיני-אפ בתחתית)
3. בחרו את הבוט שלכם מהרשימה
4. **Settings** → **Bot Settings**
5. הפעילו **Threaded Mode**

> **חשוב!** בלי Threaded Mode הבוט לא יוכל לקרוא הודעות בטופיקים.

### שלב 9: כיבוי Group Privacy

1. חזרו לצ'אט עם **@BotFather**
2. שלחו `/setprivacy`
3. בחרו את הבוט שלכם
4. בחרו **Disable** (כדי שהבוט יוכל לקרוא הודעות בגרופ)

### שלב 10: הרצת CCBot

```bash
tmux new-session -d -s ccbot -n bot
tmux send-keys -t ccbot:bot "cd ~/ccbot && uv run ccbot" Enter
```

או אם אתם כבר בתוך tmux:
```bash
cd ~/ccbot && uv run ccbot
```

### שלב 11: בדיקה

1. פתחו את הגרופ בטלגרם
2. צרו **טופיק חדש**
3. שלחו הודעה כלשהי בטופיק
4. הבוט צריך להגיב עם **directory browser** — בחרו תיקיית פרויקט
5. Claude Code מתחיל לרוץ, ואתם רואים את הפלט בטלגרם

**אם זה עובד — סיימתם!**

---

## פתרון בעיות

| בעיה | פתרון |
|---|---|
| `uv: command not found` | התקינו uv: `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| `tmux: command not found` | macOS: `brew install tmux` / Linux: `apt install tmux` |
| הבוט לא מגיב בגרופ | ודאו שהבוט הוא אדמין + ש-Threaded Mode מופעל + ש-Group Privacy כבוי |
| `TELEGRAM_BOT_TOKEN not set` | ודאו שקובץ `.env` קיים ב-`~/ccbot/` עם הטוקן |
| Hook לא עוקב אחרי סשנים | הריצו שוב `uv run ccbot hook --install` והפעילו מחדש את Claude Code |
| הבוט לא רואה הודעות | כבו Group Privacy: `@BotFather` → `/setprivacy` → Disable |

---

## פקודות שימושיות

| פקודה | מה זה עושה |
|---|---|
| `/esc` | עוצר את Claude באמצע פעולה |
| `/screenshot` | צילום מסך של הטרמינל |
| `/clear` | ניקוי סשן והתחלה מחדש |
| `/compact` | דחיסת היסטוריית שיחה |
| `/cost` | הצגת צריכת טוקנים |
| `/history` | גלילה בהיסטוריית הודעות |

כל פקודת `/` שלא מוכרת לבוט מועברת ישירות ל-Claude Code.

---

## איך זה עובד

CCBot **לא** משתמש ב-Claude API. הוא שכבה דקה מעל tmux — קורא פלט מהטרמינל ושולח הקשות מקלדת. הטרמינל נשאר ה-source of truth. אפשר תמיד לחזור למחשב עם `tmux attach -t ccbot` ולהמשיך מאיפה שעזבתם.

**1 טופיק = 1 חלון tmux = 1 סשן Claude Code**

נבנה ע״י [ddc](https://github.com/six-ddc) — שבנה את CCBot באמצעות CCBot.
