require('luarocks.require')
require('socket')
http = require('socket.http')
https = require('ssl.https')
json = require('cjson')

print("Bot gestartet...")
started = 0
our_id = 0

function on_binlog_replay_end()
  started = 1
end

function on_our_id(id)
 our_id = id
end

function ok_cb()
  --
end

function on_msg_receive(msg)
 if started == 0 then
  return
 end

 receiver = msg.to.print_name
 if msg.to.id == our_id then
  receiver = msg.from.print_name
 end

 for i = 1, #available_actions do
   if (available_actions[i].isActionTriggered(msg.text)) then
     available_actions[i].doAction(receiver, msg.text)
   end
 end

end

----------- Actions

GenericBotAction = {}
GenericBotAction.__index = GenericBotAction

function GenericBotAction:new()
  local instance = {}
  setmetatable(instance, GenericBotAction)
  return instance
end

function GenericBotAction:getInfo()
  return GenericBotAction.info
end

function GenericBotAction:doAction(receiver, input)
  --
end

function GenericBotAction:isActionTriggered(input)
  return false
end

----------- In der Tat!

InDerTatAction = GenericBotAction.new()

function InDerTatAction.getInfo()
  return "in der Tat"
end

function InDerTatAction.isActionTriggered(input)
  return string.lower(input) == 'in der tat'
end

function InDerTatAction.doAction(receiver, input)
  send_photo(receiver, 'indertat.jpg',ok_cb,false)
end

----------- Magic 8Ball

Magic8BallAction = GenericBotAction.new()

function Magic8BallAction.getInfo()
  return 'orakel'
end

function Magic8BallAction.isActionTriggered(input)
  return string.lower(input) == 'orakel'
end

function Magic8BallAction.get8BallAnswer()
 answers = {'Ja!', 'Nein!', 'Vielleicht'}
 return '[Bot] ' .. answers[math.random(#answers)]
end

function Magic8BallAction.doAction(receiver, input)
  send_msg(receiver, Magic8BallAction.get8BallAnswer(),ok_cb,false)
end

----------- GoogleImage

GoogleImageAction = GenericBotAction.new()

function GoogleImageAction.getInfo()
  return 'gi <image>'
end

function GoogleImageAction.isActionTriggered(input)
  return not (string.match(input, '^gi .*') == nil)
end

function GoogleImageAction.url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end

function GoogleImageAction.find_image(search_string)
  json_string = http.request('https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q='..GoogleImageAction.url_encode(search_string))
  local json_data = json.decode(json_string)
  image_url = json_data.responseData.results[1].unescapedUrl
  return image_url
end

function GoogleImageAction.download_image(image_url)
  image_path = 'image/'..'img'..socket.gettime()..'.jpg'

  local file = ltn12.sink.file(io.open(image_path, 'w'))
  http.request {
      url = image_url,
      sink = file,
  }
  return image_path
end

function GoogleImageAction.doAction(receiver, input)
  input = string.sub(input, 4)
  local img_url = GoogleImageAction.find_image(input)
  local img_path = GoogleImageAction.download_image(image_url)
  send_photo(receiver, img_path,ok_cb,false)
end

----------- Mustache

MustacheAction = GenericBotAction.new()

function MustacheAction.getInfo()
  return "mustache <image>"
end

function MustacheAction.doAction(receiver, input)
  input = string.sub(input, 9)
  local img_url = GoogleImageAction.find_image(input)
  local mustache_url = 'http://mustachify.me/?src='..img_url
  local img_path = GoogleImageAction.download_image(mustache_url)
  send_photo(receiver, img_path,ok_cb,false)
end

function MustacheAction.isActionTriggered(input)
  return not (string.match(input, '^mustache .*') == nil)
end

----------- XKCD

XKCDAction = GenericBotAction.new()

function XKCDAction.getInfo()
  return "xkcd"
end

function XKCDAction.doAction(receiver, input)
  input = string.sub(input, 6)
  local url = 'http://xkcd.com/info.0.json'
  if string.len(input) > 0 then
    url = 'http://xkcd.com/'.. input ..'/info.0.json'
  end
  local json_string = http.request(url)
  local json_data = json.decode(json_string)
  local img_url = json_data.img
  local img_path = GoogleImageAction.download_image(img_url)
  send_photo(receiver, img_path,ok_cb,false)
end

function XKCDAction.isActionTriggered(input)
  return not (string.match(input, '^xkcd .*') == nil)
end

----------- CommitMessage

CommitMessageAction = GenericBotAction.new()

function CommitMessageAction.getInfo()
  return "commit message"
end

function CommitMessageAction.doAction(receiver, input)
  local commitmsg = http.request('http://whatthecommit.com/index.txt')
  send_msg(receiver, '[Bot] '..commitmsg,ok_cb,false)
end

function CommitMessageAction.isActionTriggered(input)
  return string.lower(input) == 'commit message'
end


----------- Help Action

HelpAction = GenericBotAction.new()

function HelpAction.getInfo()
  return "help"
end

function HelpAction.doAction(receiver, input)
  help_text = '[Bot] Verfügbare Befehle:\n'
  for i = 1, #available_actions do
    help_text = help_text .. i .. '. ' .. available_actions[i].getInfo() .. '\n'
  end
  send_msg(receiver, help_text,ok_cb,false)
end

function HelpAction.isActionTriggered(input)
  return string.lower(input) == 'help'
end

----------- Hacker News Action

HackerNewsAction = GenericBotAction.new()

function HackerNewsAction.getInfo()
  return 'hackernews'
end

function HackerNewsAction.doAction(receiver, input)
  result = '[Bot] Hacker News Top5:\n'
  top_stories_json = https.request('https://hacker-news.firebaseio.com/v0/topstories.json')
  top_stories = json.decode(top_stories_json)
  for i = 1, 5 do
    story_json = https.request('https://hacker-news.firebaseio.com/v0/item/'..top_stories[i]..'.json')
    story = json.decode(story_json)
    result = result .. i .. '. ' .. story.title .. ' - ' .. story.url .. '\n'
  end
  send_msg(receiver, result,ok_cb,false)
end

function HackerNewsAction.isActionTriggered(input)
  return string.lower(input) == 'hackernews'
end

available_actions = {HelpAction, InDerTatAction, GoogleImageAction, MustacheAction, Magic8BallAction, HackerNewsAction, XKCDAction, CommitMessageAction}
