# GitMind 🧠

A zero-friction spaced repetition system built for learning, leveraging an advanced Elixir backend, Google Gemini 1.5 Flash AI, PostgreSQL, and Discord.

---

## 🚀 Troubleshooting Erlang/OTP Boot Failure (Windows)

If you run the startup script (`run.ps1`) and see the following crash:
```text
Runtime terminating during boot ({'cannot get bootfile','C:\\Program Files\\Erlang OTP/bin/start.boot'})
Crash dump is being written to: erl_crash.dump...done
```
This error indicates that Erlang was installed but its post-installation configuration (`Install.exe`) was not run (or did not complete successfully), leaving the boot scripts and configuration `.ini` files ungenerated.

### How to Fix:
1. **Open PowerShell as Administrator.**
2. Run the following command to execute Erlang's post-installation setup utility:
   ```powershell
   Start-Process -FilePath "C:\Program Files\Erlang OTP\Install.exe" -Verb RunAs
   ```
3. A UAC prompt will appear. Accept it.
4. An interactive console window will open and prompt you:
   ```text
   Do you want a minimal startup instead of sasl [No]:
   ```
   Press **Enter** (to accept the default **No**).
5. The setup utility will generate the required boot files (`start.boot`, `start_clean.boot`, etc.) in the installation directory.
6. Close the console window and restart your normal terminal. Running `.\run.ps1` should now succeed!

---

## 🛠️ Prerequisites

Make sure you have the following installed on your system:
* **Erlang/OTP** (version 26 or 27 recommended)
* **Elixir** (version 1.14 or later)
* **PostgreSQL** (local instance or hosted database such as Supabase)
* **Git** (for version control and backend logic)

---

## ⚙️ Project Setup

### 1. Clone & Navigate
Ensure you are in the project's subfolder:
```powershell
cd gitmind
```

### 2. Configure Environment Variables
Inside the `gitmind` folder, create a file named `.env`. It must contain the following keys:
```env
# Discord Bot Token (created via the Discord Developer Portal)
DISCORD_BOT_TOKEN=your_discord_bot_token

# PostgreSQL Connection String
DATABASE_URL=postgresql://username:password@hostname:port/database_name

# Google Gemini API Key (obtained from Google AI Studio)
GEMINI_API_KEY=your_gemini_api_key
```

### 3. Run the Application
You can start the project automatically using the provided PowerShell script. From the `gitmind` directory, run:
```powershell
.\run.ps1
```
This script will:
1. Load environment variables from `.env` into the process.
2. Fetch Elixir dependencies (`mix deps.get`).
3. Run database migrations (`mix ecto.migrate`).
4. Boot the application in an interactive Elixir shell (`iex.bat -S mix`).

#### Manual Startup Steps (Alternative)
If you prefer not to use the script:
```powershell
# 1. Set environment variables in your terminal session
# 2. Fetch dependencies
mix deps.get
# 3. Migrate the database
mix ecto.migrate
# 4. Run the interactive shell
iex -S mix
```

---

## 📦 Project Structure

The codebase is organized as follows:
* **`gitmind/run.ps1`**: The main startup script for Windows environment setup and execution.
* **`gitmind/lib/gitmind/`**:
  * **`application.ex`**: The main supervisor managing Ecto, the Discord bot websocket, and the Plug web server.
  * **`discord_gateway.ex` & `discord_client.ex`**: Connects to the Discord Gateway and handles bot interactions.
  * **`gemini_client.ex`**: Interacts with the Gemini API to analyze text/voice notes and calculate recall curves.
  * **`review_engine.ex`**: The core spaced repetition engine implementing the forgetting curve formulas.
  * **`repo.ex`**: The Ecto database wrapper.
  * **`card.ex` & `user.ex`**: Database schemas for users and learning cards.
  * **`router.ex`**: Webhook endpoint router.

---

## 🤖 Discord Bot Setup
1. Go to the [Discord Developer Portal](https://discord.com/developers/applications).
2. Create a new Application and select **Bot**.
3. Under **Privileged Gateway Intents**, enable:
   * **Presence Intent**
   * **Server Members Intent**
   * **Message Content Intent** (Crucial for receiving commands/messages)
4. Copy the bot Token and paste it into your `.env` file as `DISCORD_BOT_TOKEN`.
5. Invite the bot to your Discord server with appropriate channel read/write permissions.
