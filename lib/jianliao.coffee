{TextMessage, User} = require 'hubot'
WebHookAdapter = require('./WebHookAdapter')

class JianLiaoAdapter extends WebHookAdapter
  constructor: ->
    super
    @nameRegExp = new RegExp("^#{@robot.name}\s+", 'i')

  cleanText: (text = '', directMessage) ->
    text = text.trim()

    if directMessage and not text.match(@nameRegExp)
      text = "#{@robot.name} #{text}"

    text

  parseChatMessage: (incomingMessage) ->
    text = @cleanText(incomingMessage.body, not incomingMessage.room?)
    messageId = incomingMessage._id

    new TextMessage(@extractUser(incomingMessage), text, messageId)

  extractUser: (incomingMessage) ->
    rawUser = incomingMessage.creator

    userInfo =
      id: rawUser._id
      name: rawUser.name

    if incomingMessage.room?
      rawRoom = incomingMessage.room
      userInfo.room =
        id: rawRoom._id
        topic: rawRoom.topic

    new User(userInfo.id, userInfo)

  buildChatMessage: (envelope, text) ->
    message =
     content: text

    if envelope.room?
      message._roomId = envelope.room.id
    else
      message._toId = envelope.user.id

    message

exports.use = (robot) ->
  new JianLiaoAdapter robot
