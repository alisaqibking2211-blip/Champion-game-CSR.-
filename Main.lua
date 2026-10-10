require "import"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.content.SharedPreferences"
-- میڈیا پلیئر امپورٹ کیا گیا
import "android.media.MediaPlayer"
import "java.io.File"

local context = service or activity or this

function speak(t)
  if service then
    service.speak(t)
  elseif context then
    Toast.makeText(context, t, 0).show()
  end
end

local prefs = context.getSharedPreferences("GamePrefs", 0)
local editor = prefs.edit()

playerName = prefs.getString("playerName", nil)

gameStats = {
  guessing = {score = 0, played = 0},
  math = {score = 0, played = 0},
  rps = {score = 0, played = 0},
  dice = {score = 0, played = 0}
}

function loadStats()
  gameStats.guessing.score = prefs.getInt("guessing_score", 0)
  gameStats.guessing.played = prefs.getInt("guessing_played", 0)
  gameStats.math.score = prefs.getInt("math_score", 0)
  gameStats.math.played = prefs.getInt("math_played", 0)
  gameStats.rps.score = prefs.getInt("rps_score", 0)
  gameStats.rps.played = prefs.getInt("rps_played", 0)
  gameStats.dice.score = prefs.getInt("dice_score", 0)
  gameStats.dice.played = prefs.getInt("dice_played", 0)
end

function saveStats()
  editor.putInt("guessing_score", gameStats.guessing.score)
  editor.putInt("guessing_played", gameStats.guessing.played)
  editor.putInt("math_score", gameStats.math.score)
  editor.putInt("math_played", gameStats.math.played)
  editor.putInt("rps_score", gameStats.rps.score)
  editor.putInt("rps_played", gameStats.rps.played)
  editor.putInt("dice_score", gameStats.dice.score)
  editor.putInt("dice_played", gameStats.dice.played)
  editor.apply()
end

loadStats()

mainDialog = nil

function getInfoText()
  return "Guessing Game: Score " .. gameStats.guessing.score .. " , Played " .. gameStats.guessing.played .. "\n" ..
         "Math Quiz: Score " .. gameStats.math.score .. " , Played " .. gameStats.math.played .. "\n" ..
         "Rock Paper Scissors: Score " .. gameStats.rps.score .. " , Played " .. gameStats.rps.played .. "\n" ..
         "Dice Roll: Score " .. gameStats.dice.score .. " , Played " .. gameStats.dice.played
end

function showMainMenu()
  if mainDialog then
    mainDialog.dismiss()
  end
  mainDialog = LuaDialog(context)
  mainDialog.setTitle("Champion Game")
  
  local layout = {LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text="Username: " .. tostring(playerName), textSize="18sp", textColor="#FF0000", layout_marginBottom="5dp"},
    {TextView, text="Developed by. CSR official", textSize="14sp", textColor="#666666", layout_marginBottom="10dp"},
    {TextView, text="Games", textSize="16sp", textColor="#0000FF", layout_marginTop="5dp"},
    {Button, text="1. Guessing Game", layout_width="fill", id="btnGuess"},
    {Button, text="2. Math Quiz", layout_width="fill", layout_marginTop="5dp", id="btnMath"},
    {Button, text="3. Rock Paper Scissors", layout_width="fill", layout_marginTop="5dp", id="btnRPS"},
    {Button, text="4. Dice Roll", layout_width="fill", layout_marginTop="5dp", id="btnDice"},
    {TextView, text="Information", textSize="16sp", textColor="#0000FF", layout_marginTop="15dp"},
    {TextView, id="infoText", text=getInfoText(), textSize="14sp", layout_marginTop="5dp"},
    {Button, text="About", layout_width="fill", layout_marginTop="15dp", id="btnAbout"},
    {Button, text="Exit", layout_width="fill", layout_marginTop="10dp", id="btnExit"}
  }
  mainDialog.setView(loadlayout(layout))
  
  btnGuess.onClick = function()
    mainDialog.dismiss()
    startGuessingGame()
  end
  btnMath.onClick = function()
    mainDialog.dismiss()
    startMathGame()
  end
  btnRPS.onClick = function()
    mainDialog.dismiss()
    startRPSGame()
  end
  btnDice.onClick = function()
    mainDialog.dismiss()
    startDiceGame()
  end
  btnAbout.onClick = function()
    showAbout()
  end
  btnExit.onClick = function()
    mainDialog.dismiss()
    if activity then activity.finish() end
  end
  
  mainDialog.onCancel = function()
    mainDialog = nil
  end
  mainDialog.show()
end

function updateAndShowMenu()
  saveStats()
  showMainMenu()
end

function showResult(title, msg, gameKey, isWin, retryFunc)
  if isWin then
    gameStats[gameKey].score = gameStats[gameKey].score + 1
  end
  saveStats()
  
  pcall(function()
    local folderPath = "/storage/emulated/0/解说/Plugins/Champion Game by CSR official. /"
    local soundFile = isWin and "chest_open.mp3" or "lesson_failed.mp3"
    
    local fullPath = folderPath .. soundFile
    if File(fullPath).exists() then
      local mp = MediaPlayer()
      mp.setDataSource(fullPath)
      mp.prepare()
      mp.start()
    end
  end)

  local d = LuaDialog(context)
  d.setTitle(title)
  local lay = {LinearLayout, orientation="vertical", padding="25dp",
    {TextView, text=msg, textSize="18sp", gravity="center"},
    {Button, text="Play Again", layout_marginTop="20dp", layout_width="fill", onClick=function() d.dismiss() if retryFunc then retryFunc() end end},
    {Button, text="Main Menu", layout_width="fill", onClick=function() d.dismiss() updateAndShowMenu() end}}
  d.setView(loadlayout(lay))
  d.show()
  speak(msg)
end

function startGuessingGame()
  gameStats.guessing.played = gameStats.guessing.played + 1
  saveStats()
  local target = math.random(1, 20)
  local attempts = 0
  local maxAttempts = 5
  local d = LuaDialog(context)
  d.setTitle("Guess the Number")
  
  local lay = {LinearLayout, orientation="vertical", padding="25dp",
    {TextView, text="Hi " .. playerName .. ", guess 1-20", textSize="16sp"},
    {TextView, id="info", text="Attempts left: " .. maxAttempts, textSize="14sp", textColor="#FFAAAA"},
    {EditText, id="edt", hint="Your guess", inputType="phone", layout_marginTop="10dp"},
    {Button, text="Check", layout_marginTop="10dp", layout_width="fill", id="btn"}}
  d.setView(loadlayout(lay))
  
  btn.onClick = function()
    local v = tonumber(edt.Text)
    if not v then speak("Enter a number") return end
    attempts = attempts + 1
    local left = maxAttempts - attempts
    if v == target then
      d.dismiss()
      showResult("You Won!", "Correct in " .. attempts .. " tries", "guessing", true, startGuessingGame)
    elseif attempts >= maxAttempts then
      d.dismiss()
      showResult("Game Over", "Number was " .. target .. "\nBetter luck next time!", "guessing", false, startGuessingGame)
    else
      pcall(function()
        local folderPath = "/storage/emulated/0/解说/Plugins/Champion Game by CSR official. /"
        local fullPath = folderPath .. "incorrect.mp3"
        if File(fullPath).exists() then
          local mp = MediaPlayer()
          mp.setDataSource(fullPath)
          mp.prepare()
          mp.start()
        end
      end)
      
      info.setText("Attempts left: " .. left)
      edt.Text = ""
    end
  end
  d.show()
end

function startMathGame()
  gameStats.math.played = gameStats.math.played + 1
  saveStats()
  local op = math.random(1,3)
  local n1, n2, ans, opSym
  if op == 1 then
    n1, n2 = math.random(1,12), math.random(1,12)
    ans = n1 + n2
    opSym = "+"
  elseif op == 2 then
    n1, n2 = math.random(5,20), math.random(1,10)
    while n1 < n2 do n1, n2 = math.random(5,20), math.random(1,10) end
    ans = n1 - n2
    opSym = "-"
  else
    n1, n2 = math.random(2,10), math.random(2,8)
    ans = n1 * n2
    opSym = "x"
  end
  local d = LuaDialog(context)
  d.setTitle("Math Master")
  
  local lay = {LinearLayout, orientation="vertical", padding="25dp",
    {TextView, text="Hi " .. playerName .. ", solve:", textSize="16sp"},
    {TextView, text=n1 .. " " .. opSym .. " " .. n2 .. " = ?", textSize="28sp", gravity="center", layout_margin="15dp"},
    {EditText, id="edt", hint="Answer", inputType="phone", layout_marginTop="10dp"},
    {Button, text="Submit", layout_width="fill", layout_marginTop="15dp", id="btn"}}
  d.setView(loadlayout(lay))
  btn.onClick = function()
    local u = tonumber(edt.Text)
    if not u then speak("Type answer") return end
    d.dismiss()
    if u == ans then
      showResult("Correct!", "Well done " .. playerName, "math", true, startMathGame)
    else
      showResult("Oops!", "Correct answer: " .. ans, "math", false, startMathGame)
    end
  end
  d.show()
end

function startRPSGame()
  gameStats.rps.played = gameStats.rps.played + 1
  saveStats()
  local ops = {"Rock", "Paper", "Scissors"}
  local d = LuaDialog(context)
  d.setTitle("Rock Paper Scissors")
  local lay = {LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=playerName .. ", choose:", textSize="17sp", gravity="center"},
    {Button, text="Rock", layout_width="fill", id="b1"},
    {Button, text="Paper", layout_width="fill", id="b2"},
    {Button, text="Scissors", layout_width="fill", id="b3"}}
  d.setView(loadlayout(lay))
  
  local function playSound(fileName)
    pcall(function()
      local folderPath = "/storage/emulated/0/解说/Plugins/Champion Game by CSR official. /"
      local fullPath = folderPath .. fileName
      if File(fullPath).exists() then
        local mp = MediaPlayer()
        mp.setDataSource(fullPath)
        mp.prepare()
        mp.start()
      else
        speak("Sound file not found")
      end
    end)
  end

  local function play(userChoice)
    d.dismiss()
    local bot = ops[math.random(1,3)]
    
    if bot == "Rock" then
      playSound("stone.mp3")
    elseif bot == "Paper" then
      playSound("paper.mp3")
    elseif bot == "Scissors" then
      playSound("scissor.mp3")
    end
    
    local resultMsg = ""
    local isWin = false
    if userChoice == bot then
      resultMsg = "Tie\nYou: " .. userChoice .. "\nBot: " .. bot .. "\nNo score."
      isWin = false
    elseif (userChoice == "Rock" and bot == "Scissors") or (userChoice == "Paper" and bot == "Rock") or (userChoice == "Scissors" and bot == "Paper") then
      resultMsg = "You win!\nYou: " .. userChoice .. "\nBot: " .. bot
      isWin = true
    else
      resultMsg = "Bot wins\nYou: " .. userChoice .. "\nBot: " .. bot
      isWin = false
    end
    showResult("Result", resultMsg, "rps", isWin, startRPSGame)
  end
  
  b1.onClick = function() playSound("stone.mp3") play("Rock") end
  b2.onClick = function() playSound("paper.mp3") play("Paper") end
  b3.onClick = function() playSound("scissor.mp3") play("Scissors") end
  d.show()
end

function startDiceGame()
  gameStats.dice.played = gameStats.dice.played + 1
  saveStats()
  local d = LuaDialog(context)
  d.setTitle("Dice Duel")
  local lay = {LinearLayout, orientation="vertical", padding="30dp",
    {TextView, text=playerName .. " vs Bot", gravity="center", textSize="16sp"},
    {Button, text="Roll Dice", layout_marginTop="20dp", layout_width="fill", id="btn"}}
  d.setView(loadlayout(lay))
  
  local function playDiceSound()
    pcall(function()
      local folderPath = "/storage/emulated/0/解说/Plugins/Champion Game by CSR official. /"
      local fullPath = folderPath .. "rolldice.mp3"
      if File(fullPath).exists() then
        local mp = MediaPlayer()
        mp.setDataSource(fullPath)
        mp.prepare()
        mp.start()
      end
    end)
  end

  btn.onClick = function()
    d.dismiss()
    
    playDiceSound()
    pcall(function() Thread.sleep(600) end)
    
    local ur = math.random(1,6)
    speak("Your number is " .. ur)
    pcall(function() Thread.sleep(1000) end)
    
    playDiceSound()
    pcall(function() Thread.sleep(600) end)
    
    local br = math.random(1,6)
    speak("Bot number is " .. br)
    pcall(function() Thread.sleep(1000) end)
    
    local msg = "You: " .. ur .. "  |  Bot: " .. br
    if ur > br then
      showResult("You Win!", msg .. "\nLucky you!", "dice", true, startDiceGame)
    elseif ur < br then
      showResult("Bot Wins", msg .. "\nBetter luck next time", "dice", false, startDiceGame)
    else
      showResult("Draw", msg .. "\nRoll again", "dice", false, startDiceGame)
    end
  end
  d.show()
end

function showAbout()
  local d = LuaDialog(context)
  d.setTitle("About")
  
  local Uri = luajava.bindClass("android.net.Uri")
  
  local description = [[Champion Game is a fun game hub containing four games: Guessing Game, Math Quiz, Rock Paper Scissors, and Dice Duel. Play games and increase your scores. This app is developed in AndroLua. All scores are tracked per game.]]
  
  local layout = {LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text="Game Name: Champion Game", textSize="16sp", textColor="#000000"},
    {TextView, text="Developed by. CSR official", textSize="14sp", layout_marginTop="5dp"},
    {TextView, text="Created by. Ch abdulrafay", textSize="14sp"},
    {TextView, text="Detail", textSize="16sp", textColor="#0000FF", layout_marginTop="10dp"},
    {TextView, text=description, textSize="14sp", layout_marginTop="5dp"},
    {TextView, text="Contact us", textSize="16sp", textColor="#0000FF", layout_marginTop="10dp"},
    {Button, text="WhatsApp Channel", layout_width="fill", id="waChannel"},
    {Button, text="WhatsApp Community", layout_width="fill", id="waCommunity"},
    {Button, text="YouTube Channel", layout_width="fill", id="youtube"},
    {Button, text="Send Feedback by Developer", layout_width="fill", layout_marginTop="10dp", id="feedback"},
    {Button, text="Close", layout_width="fill", layout_marginTop="15dp", id="closeBtn"}
  }
  d.setView(loadlayout(layout))
  
  waChannel.onClick = function()
    local url = "https://whatsapp.com/channel/0029VbCJfWSAojYuaMuB9E1t"
    local intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
    context.startActivity(intent)
  end
  
  waCommunity.onClick = function()
    local url = "https://chat.whatsapp.com/C5jA2u0gGDO9rkgcCY2ybg"
    local intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
    context.startActivity(intent)
  end
  
  youtube.onClick = function()
    local url = "https://youtube.com/@csr-official-f5v?si=nwBIaiiFoI8Ix8k5"
    local intent = Intent(Intent.parseUri(url, 0))
    context.startActivity(intent)
  end
  
  feedback.onClick = function()
    local url = "https://wa.me/923057040811"
    local intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
    context.startActivity(intent)
  end
  
  closeBtn.onClick = function()
    d.dismiss()
  end
  
  d.show()
end

function askNameAndStart()
  -- اگر نام پہلے سے محفوظ ہے تو براہ راست مین مینو کھلے گا
  if playerName ~= nil and playerName ~= "" and not playerName:match("^%s*$") then
    showMainMenu()
    return
  end
  
  local d = LuaDialog(context)
  d.setTitle("Welcome to Champion Game")
  d.setCancelable(false) -- یوزر بیک بٹن دبا کر اسے بند نہ کر سکے
  
  local lay = {LinearLayout, orientation="vertical", padding="25dp",
    {TextView, text="Please enter your name:", textSize="16sp"},
    {EditText, id="nameEdt", hint="e.g. Ch abdulrafay", layout_marginTop="10dp"},
    {Button, text="Next", layout_width="fill", layout_marginTop="20dp", id="nextBtn"}}
  d.setView(loadlayout(lay))
  
  nextBtn.onClick = function()
    local name = nameEdt.getText().toString()
    -- نام کی سخت جانچ، خالی نام یا صرف سپیس آگے نہیں جانے دے گی
    if name == nil or name == "" or name:match("^%s*$") then
      speak("Please enter a valid name")
      return
    end
    playerName = name
    editor.putString("playerName", playerName)
    editor.apply()
    d.dismiss()
    showMainMenu()
  end
  d.show()
end

askNameAndStart()